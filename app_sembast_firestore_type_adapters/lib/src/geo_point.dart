import 'package:sembast/utils/type_adapter.dart';
import 'package:tekartik_app_sembast_firestore_type_adapters/src/mixin.dart';
import 'package:tekartik_firebase_firestore/firestore.dart' show GeoPoint;

class _FirestoreGeoPointAdapter
    extends SembastTypeAdapter<GeoPoint, Map<String, dynamic>>
    with TypeAdapterCodecMixin<GeoPoint, Map<String, dynamic>> {
  _FirestoreGeoPointAdapter() {
    // Encode to string
    encoder = TypeAdapterConverter<GeoPoint, Map<String, dynamic>>(
      (geoPoint) => <String, dynamic>{
        'latitude': geoPoint.latitude,
        'longitude': geoPoint.longitude,
      },
    );
    // Decode from string
    decoder = TypeAdapterConverter<Map<String, dynamic>, GeoPoint>(
      (map) => GeoPoint(
        (map['latitude'] as num).toDouble(),
        (map['longitude'] as num).toDouble(),
      ),
    );
  }

  @override
  String get name => 'FirestoreGeoPoint';
}

/// Firestore GeoPoint adapter.
///
/// Convert a GeoPoint to a map with latitude and longitude information.
final SembastTypeAdapter<GeoPoint, Map<String, dynamic>>
sembastFirestoreGeoPointAdapter = _FirestoreGeoPointAdapter();
