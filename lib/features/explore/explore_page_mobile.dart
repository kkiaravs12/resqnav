import 'package:google_maps_flutter/google_maps_flutter.dart';

void initResQNavPlaces(
  String containerId,
  Function(String, String, double, double) callback,
) {
  throw UnsupportedError('initResQNavPlaces is only available on web');
}

void computeResQNavRoute(
  LatLng origin,
  double destLat,
  double destLng,
  String travelMode,
  Function(String, double, double) callback,
) {
  throw UnsupportedError('computeResQNavRoute is only available on web');
}
