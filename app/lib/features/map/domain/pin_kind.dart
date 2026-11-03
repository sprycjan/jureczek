import 'package:flutter/foundation.dart';

import '../../places/domain/place_type.dart';

/// Typ pinezki (v16): zielona „Pinezka” bez typu ([type] `null`) albo typ miejsca.
///
/// [key] trafia do kolumny `pins.category`: `standard` albo klucz [PlaceType].
@immutable
class PinKind {
  const PinKind(this.type);

  static const standard = PinKind(null);
  static const standardKey = 'standard';

  final PlaceType? type;

  bool get isStandard => type == null;

  String get key => type?.key ?? standardKey;

  /// Nieznany lub pusty klucz to [standard], żeby zepsuty wiersz nie wywracał mapy.
  static PinKind fromKey(String? key) => PinKind(PlaceType.fromKey(key));

  @override
  bool operator ==(Object other) => other is PinKind && other.type == type;

  @override
  int get hashCode => type.hashCode;

  @override
  String toString() => 'PinKind($key)';
}
