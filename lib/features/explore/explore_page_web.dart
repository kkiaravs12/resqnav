import 'dart:js_interop';
import 'package:google_maps_flutter/google_maps_flutter.dart';

@JS('initResQNavPlaces')
external void _initResQNavPlacesJS(
  JSString containerId,
  JSFunction callback,
);

@JS('computeResQNavRoute')
external void _computeResQNavRouteJS(
  JSNumber originLat,
  JSNumber originLng,
  JSNumber destinationLat,
  JSNumber destinationLng,
  JSString travelMode,
  JSFunction callback,
);

void initResQNavPlaces(
  String containerId,
  Function(String, String, double, double) callback,
) {
  _initResQNavPlacesJS(
    containerId.toJS,
    callback.toJS,
  );
}

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
    callback.toJS,
  );
}
