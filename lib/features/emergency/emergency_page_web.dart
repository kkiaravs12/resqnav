import 'dart:js_interop';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@JS('computeResQNavRoute')
external void _computeResQNavRouteJS(
  JSNumber originLat,
  JSNumber originLng,
  JSNumber destinationLat,
  JSNumber destinationLng,
  JSString travelMode,
  JSFunction callback,
);

// Wrapper function that handles JS interop
void computeResQNavRoute(
  LatLng origin,
  double destLat,
  double destLng,
  String travelMode,
  Function(String, double, double) callback,
) {
  _computeResQNavRouteJS(
    origin.latitude.toJS,
    origin.longitude.toJS,
    destLat.toJS,
    destLng.toJS,
    travelMode.toJS,
    ((JSString pathJson, JSNumber distance, JSNumber duration) {
      callback(pathJson.toDart, distance.toDartDouble, duration.toDartDouble);
    }).toJS,
  );
}
