import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../domain/place_type.dart';

/// Wymiary pinezki w SVG z `tool/place_icons.py` (jednostki viewBox = dp przy skali 1).
///
/// SVG ma cień jako `feDropShadow`, którego `flutter_svg` nie rysuje – [PlacePin]
/// i [renderPlacePinPng] malują ten sam cień sami z parametrów [shadowDy],
/// [shadowBlur] (= `stdDeviation`) i [shadowOpacity]. Test porównuje je z SVG.
class PlacePinGeometry {
  const PlacePinGeometry._({
    required this.viewBox,
    required this.pinSize,
    required this.shadowDy,
    required this.shadowBlur,
    required this.shadowOpacity,
  });

  static const normal = PlacePinGeometry._(
    viewBox: Size(48, 56),
    pinSize: Size(36, 44),
    shadowDy: 3,
    shadowBlur: 2.5,
    shadowOpacity: 0.3,
  );

  static const selected = PlacePinGeometry._(
    viewBox: Size(54, 64),
    pinSize: Size(42, 52),
    shadowDy: 5,
    shadowBlur: 4,
    shadowOpacity: 0.45,
  );

  static PlacePinGeometry of({required bool selected}) =>
      selected ? PlacePinGeometry.selected : normal;

  /// Pinezka leży w viewBox przesunięta o ten margines (miejsce na cień).
  static const pinOffset = Offset(6, 4);

  final Size viewBox;
  final Size pinSize;
  final double shadowDy;
  final double shadowBlur;
  final double shadowOpacity;

  /// Czubek pinezki w jednostkach viewBox.
  double get tipY => pinOffset.dy + pinSize.height;

  ColorFilter get shadowFilter =>
      ColorFilter.mode(Color.fromRGBO(0, 0, 0, shadowOpacity), BlendMode.srcIn);
}

/// Samodzielna ikona typu miejsca (24×24 dp) w kolorze kategorii – do filtrów,
/// wyników wyszukiwania, szczegółów miejsca, legendy. [color] nadpisuje kolor.
class PlaceIcon extends StatelessWidget {
  const PlaceIcon(this.type, {super.key, this.size = 24, this.color});

  final PlaceType type;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color;
    return SvgPicture.asset(
      type.iconAsset,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}

/// Ikona na zaokrąglonym tle kategorii, jak w matrycy Stitch: w jasnym
/// motywie `lightContainer` + kolor kategorii, w ciemnym `darkContainer` + `onDarkContainer`.
class PlaceIconBadge extends StatelessWidget {
  const PlaceIconBadge(
    this.type, {
    super.key,
    this.dark = false,
    this.size = 40,
  });

  final PlaceType type;
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final category = type.category;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: dark ? category.darkContainer : category.lightContainer,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: PlaceIcon(
        type,
        size: size * 0.6,
        color: dark ? category.onDarkContainer : null,
      ),
    );
  }
}

/// Pinezka typu miejsca jako wektor. Rozmiar widżetu to sam korpus pinezki
/// (36×44 dp, zaznaczona 42×52 dp, albo [width] w proporcji); cień wychodzi poza niego.
/// Czubek leży na dolnej krawędzi – do pozycjonowania jak kotwicą `BOTTOM`.
class PlacePin extends StatelessWidget {
  const PlacePin(this.type, {super.key, this.selected = false, this.width});

  final PlaceType type;
  final bool selected;

  /// Szerokość korpusu w dp; `null` = rozmiar ze specyfikacji.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final geometry = PlacePinGeometry.of(selected: selected);
    final k = (width ?? geometry.pinSize.width) / geometry.pinSize.width;
    final view = geometry.viewBox * k;
    final svg = SvgPicture.asset(
      type.pinAsset(selected: selected),
      width: view.width,
      height: view.height,
      excludeFromSemantics: true,
    );
    return SizedBox.fromSize(
      size: geometry.pinSize * k,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -PlacePinGeometry.pinOffset.dx * k,
            top: -PlacePinGeometry.pinOffset.dy * k,
            width: view.width,
            height: view.height,
            child: Stack(
              children: [
                Transform.translate(
                  offset: Offset(0, geometry.shadowDy * k),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(
                      sigmaX: geometry.shadowBlur * k,
                      sigmaY: geometry.shadowBlur * k,
                    ),
                    child: ColorFiltered(
                      colorFilter: geometry.shadowFilter,
                      child: svg,
                    ),
                  ),
                ),
                svg,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// PNG pinezki dla Mapbox (`PointAnnotation` potrzebuje bajtów), z cieniem,
/// w gęstości [pixelRatio]. Szerokość = viewBox, wysokość ucięta na czubku,
/// więc kotwica `BOTTOM` bez przesunięcia stawia czubek w punkcie (jak v9).
Future<Uint8List> renderPlacePinPng(
  PlaceType type, {
  bool selected = false,
  double pixelRatio = 3,
  AssetBundle? bundle,
}) async {
  final geometry = PlacePinGeometry.of(selected: selected);
  final info = await vg.loadPicture(
    SvgAssetLoader(type.pinAsset(selected: selected), assetBundle: bundle),
    null,
  );
  final width = (geometry.viewBox.width * pixelRatio).round();
  final fullHeight = (geometry.viewBox.height * pixelRatio).round();
  final height = (geometry.tipY * pixelRatio).round();

  // Najpierw sam wektor w docelowej gęstości, potem cień z niego w pikselach urządzenia.
  final shapeRecorder = ui.PictureRecorder();
  Canvas(shapeRecorder)
    ..scale(width / info.size.width, fullHeight / info.size.height)
    ..drawPicture(info.picture);
  info.picture.dispose();
  final shapePicture = shapeRecorder.endRecording();
  final shape = await shapePicture.toImage(width, fullHeight);
  shapePicture.dispose();

  final recorder = ui.PictureRecorder();
  final sigma = geometry.shadowBlur * pixelRatio;
  Canvas(recorder)
    ..drawImage(
      shape,
      Offset(0, geometry.shadowDy * pixelRatio),
      Paint()
        ..colorFilter = geometry.shadowFilter
        ..imageFilter = ui.ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
    )
    ..drawImage(shape, Offset.zero, Paint());
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  shape.dispose();
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}
