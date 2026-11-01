import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jureczek/features/map/presentation/pin_drop.dart';

void main() {
  const anchor = Offset(200, 300);
  const size = Size(60, 80);
  final image = MemoryImage(File('assets/markers/pin.png').readAsBytesSync());

  Future<void> pumpDrop(
    WidgetTester tester, {
    VoidCallback? onImpact,
    VoidCallback? onLanded,
  }) {
    return tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            PinDrop(
              image: image,
              anchor: anchor,
              size: size,
              onImpact: onImpact ?? () {},
              onLanded: onLanded ?? () {},
            ),
          ],
        ),
      ),
    );
  }

  Offset bottomCenter(WidgetTester tester) =>
      tester.getRect(find.byType(Image)).bottomCenter;

  testWidgets('startuje nad punktem w podanym rozmiarze i ląduje w punkcie', (
    tester,
  ) async {
    await pumpDrop(tester);

    expect(tester.getSize(find.byType(Image)), size);
    expect(bottomCenter(tester), anchor - const Offset(0, pinDropLift));

    await tester.pumpAndSettle();
    expect(bottomCenter(tester), anchor);
  });

  testWidgets('uderza raz w trakcie, a ląduje po odbiciu', (tester) async {
    var impacts = 0;
    var landed = 0;
    await pumpDrop(tester, onImpact: () => impacts++, onLanded: () => landed++);

    await tester.pump(const Duration(milliseconds: 100));
    expect((impacts, landed), (0, 0));

    // Po uderzeniu pinezka jest w powietrzu (odbicie), jeszcze nie wylądowała.
    await tester.pump(const Duration(milliseconds: 250));
    expect((impacts, landed), (1, 0));
    expect(bottomCenter(tester).dy, lessThan(anchor.dy));

    await tester.pumpAndSettle();
    expect((impacts, landed), (1, 1));
  });
}
