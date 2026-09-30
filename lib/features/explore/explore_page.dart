import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:web/web.dart' as web;

import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../navigation/navigation_page.dart';

@JS('initResQNavPlaces')
external void initResQNavPlaces(
  JSString containerId,
  JSFunction callback,
);

@JS('computeResQNavRoute')
external void computeResQNavRoute(
  JSNumber originLat,
  JSNumber originLng,
  JSNumber destinationLat,
  JSNumber destinationLng,
  JSString travelMode,
  JSFunction callback,
);

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() =>
      _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  // =========================================================
  // MAP
  // =========================================================

  GoogleMapController? mapController;

  static const LatLng defaultLocation = LatLng(
    19.0760,
    72.8777,
  );

  LatLng? currentLocation;

  final Set<Marker> markers = {};
  final Set<Polyline> polylines = {};

  // =========================================================
  // SEARCH
  // =========================================================

  static bool _viewFactoryRegistered = false;

  bool placeSelected = false;
  bool locationLoading = false;
  bool routeLoading = false;

  String selectedPlaceName = '';
  String selectedPlaceAddress = '';

  double selectedDestinationLat = 0;
  double selectedDestinationLng = 0;

  // =========================================================
  // ROUTE
  // =========================================================

  String travelMode = 'car';

  double routeDistance = 0;
  double routeDuration = 0;

  LatLng? routeOrigin;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    _registerSearchContainer();
    _loadCurrentLocation();
  }

  // =========================================================
  // SEARCH CONTAINER
  // =========================================================

  void _registerSearchContainer() {
    if (_viewFactoryRegistered) {
      return;
    }

    ui_web.platformViewRegistry.registerViewFactory(
      'resqnav-place-search',
      (int viewId) {
        final container = web.HTMLDivElement()
          ..id = 'resqnav-place-search-$viewId'
          ..style.width = '100%'
          ..style.height = '100%';

        return container;
      },
    );

    _viewFactoryRegistered = true;
  }

  void _initializePlaces(
    String containerId,
  ) {
    Null callback(
      String name,
      String address,
      double lat,
      double lng,
    ) {
      if (!mounted) {
        return;
      }

      _onPlaceSelected(
        name,
        address,
        lat,
        lng,
      );
    }

    initResQNavPlaces(
      containerId.toJS,
      callback.toJS,
    );
  }

  // =========================================================
  // CURRENT LOCATION
  // =========================================================

  Future<void> _loadCurrentLocation() async {
    if (locationLoading) {
      return;
    }

    setState(() {
      locationLoading = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _setDefaultLocation();
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.denied ||
          permission ==
              LocationPermission.deniedForever) {
        _setDefaultLocation();
        return;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      if (!mounted) {
        return;
      }

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      setState(() {
        currentLocation = location;
      });

      _updateCurrentLocationMarker(
        location,
      );

      await mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: 14,
          ),
        ),
      );
    } catch (error) {
      debugPrint(
        'ResQNav explore location error: $error',
      );

      _setDefaultLocation();
    } finally {
      if (mounted) {
        setState(() {
          locationLoading = false;
        });
      }
    }
  }

  void _setDefaultLocation() {
    if (!mounted) {
      return;
    }

    setState(() {
      currentLocation = defaultLocation;
    });

    _updateCurrentLocationMarker(
      defaultLocation,
    );
  }

  void _updateCurrentLocationMarker(
    LatLng location,
  ) {
    setState(() {
      markers.removeWhere(
        (marker) =>
            marker.markerId ==
            const MarkerId(
              'current_location',
            ),
      );

      markers.add(
        Marker(
          markerId: const MarkerId(
            'current_location',
          ),
          position: location,
          infoWindow: const InfoWindow(
            title: 'Your location',
          ),
          icon: BitmapDescriptor
              .defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    });
  }

  // =========================================================
  // PLACE SELECTED
  // =========================================================

  void _onPlaceSelected(
    String name,
    String address,
    double lat,
    double lng,
  ) {
    final location = LatLng(
      lat,
      lng,
    );

    setState(() {
      selectedPlaceName = name;
      selectedPlaceAddress = address;

      selectedDestinationLat = lat;
      selectedDestinationLng = lng;

      placeSelected = true;

      routeLoading = false;
      routeDistance = 0;
      routeDuration = 0;

      polylines.clear();

      markers.removeWhere(
        (marker) =>
            marker.markerId ==
            const MarkerId(
              'selected_place',
            ),
      );

      markers.add(
        Marker(
          markerId: const MarkerId(
            'selected_place',
          ),
          position: location,
          infoWindow: InfoWindow(
            title: name,
            snippet: address,
          ),
        ),
      );
    });

    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 16,
        ),
      ),
    );
  }

  // =========================================================
  // GET ROUTE
  // =========================================================

  Future<void> _getRoute() async {
    if (!placeSelected ||
        routeLoading) {
      return;
    }

    if (selectedDestinationLat == 0 &&
        selectedDestinationLng == 0) {
      _showMessage(
        'Please select a destination first.',
      );
      return;
    }

    setState(() {
      routeLoading = true;
      polylines.clear();
      routeDistance = 0;
      routeDuration = 0;
    });

    try {
      LatLng? origin =
          currentLocation;

      if (origin == null) {
        await _loadCurrentLocation();
        origin = currentLocation;
      }

      if (origin == null) {
        if (mounted) {
          setState(() {
            routeLoading = false;
          });
        }

        _showMessage(
          'Current location is required.',
        );

        return;
      }

      routeOrigin = origin;

      Null callback(
        String pathJson,
        double distance,
        double duration,
      ) {
        if (!mounted) {
          return;
        }

        try {
          final decoded =
              jsonDecode(pathJson);

          if (decoded is! List) {
            throw const FormatException(
              'Invalid route response.',
            );
          }

          final List<LatLng> routePoints =
              decoded.map<LatLng>(
            (point) {
              return LatLng(
                (point['lat'] as num)
                    .toDouble(),
                (point['lng'] as num)
                    .toDouble(),
              );
            },
          ).toList();

          if (routePoints.isEmpty) {
            setState(() {
              routeLoading = false;
              routeDistance = 0;
              routeDuration = 0;
              polylines.clear();
            });

            _showMessage(
              'No route could be found.',
            );

            return;
          }

          setState(() {
            routeLoading = false;
            routeDistance = distance;
            routeDuration = duration;

            polylines
              ..clear()
              ..add(
                Polyline(
                  polylineId:
                      const PolylineId(
                    'resqnav_route',
                  ),
                  points: routePoints,
                  width: 6,
                  color:
                      AppTheme.primary,
                  geodesic: true,
                ),
              );
          });

          _fitRoute(routePoints);
        } catch (error) {
          setState(() {
            routeLoading = false;
            routeDistance = 0;
            routeDuration = 0;
            polylines.clear();
          });

          debugPrint(
            'ResQNav explore route error: $error',
          );

          _showMessage(
            'Unable to display the route.',
          );
        }
      }

      computeResQNavRoute(
        origin.latitude.toJS,
        origin.longitude.toJS,
        selectedDestinationLat.toJS,
        selectedDestinationLng.toJS,
        travelMode.toJS,
        callback.toJS,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          routeLoading = false;
        });
      }

      debugPrint(
        'ResQNav route start error: $error',
      );

      _showMessage(
        'Unable to start directions.',
      );
    }
  }

  // =========================================================
  // FIT ROUTE
  // =========================================================

  void _fitRoute(
    List<LatLng> points,
  ) {
    if (points.isEmpty ||
        mapController == null) {
      return;
    }

    double minLat =
        points.first.latitude;
    double maxLat =
        points.first.latitude;

    double minLng =
        points.first.longitude;
    double maxLng =
        points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) {
        minLat = point.latitude;
      }

      if (point.latitude > maxLat) {
        maxLat = point.latitude;
      }

      if (point.longitude < minLng) {
        minLng = point.longitude;
      }

      if (point.longitude > maxLng) {
        maxLng = point.longitude;
      }
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        minLat,
        minLng,
      ),
      northeast: LatLng(
        maxLat,
        maxLng,
      ),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        90,
      ),
    );
  }

  // =========================================================
  // START NAVIGATION
  // =========================================================

  Future<void> _startNavigation() async {
    if (!placeSelected) {
      _showMessage(
        'Please select a destination.',
      );
      return;
    }

    if (routeLoading) {
      return;
    }

    if (routeOrigin == null ||
        routeDistance <= 0 ||
        routeDuration <= 0) {
      await _getRoute();
    }

    if (!mounted) {
      return;
    }

    if (routeOrigin == null ||
        routeDistance <= 0 ||
        routeDuration <= 0) {
      _showMessage(
        'Please get directions first.',
      );
      return;
    }

    final destination =
        LatLng(
      selectedDestinationLat,
      selectedDestinationLng,
    );

    // Save normal destination search.
    _saveDestinationHistory();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return NavigationPage(
            destinationName:
                selectedPlaceName,
            destinationAddress:
                selectedPlaceAddress,
            currentLocation:
                routeOrigin!,
            destinationLocation:
                destination,
            routePoints:
                _currentRoutePoints(),
            distanceMeters:
                routeDistance,
            durationMilliseconds:
                routeDuration,
            travelMode:
                travelMode,
          );
        },
      ),
    );
  }

  // =========================================================
  // CURRENT ROUTE POINTS
  // =========================================================

  List<LatLng> _currentRoutePoints() {
    if (polylines.isEmpty) {
      return [];
    }

    return polylines.first.points;
  }
// =========================================================
// SAVE NORMAL DESTINATION HISTORY
// =========================================================

  Future<void> _saveDestinationHistory() async {
    try {
      final history = <String, dynamic>{
        'search_type': 'destination',
        'query': selectedPlaceName,
        'destination_name': selectedPlaceName,
        'destination_address': selectedPlaceAddress,
        'latitude': double.parse(selectedDestinationLat.toStringAsFixed(6)),
        'longitude': double.parse(selectedDestinationLng.toStringAsFixed(6)),
        'distance_meters': routeDistance,
        'duration_seconds':
            routeDuration / 1000,
      };

      debugPrint(
        'ResQNav destination history request: '
        '$history',
      );

      final result =
          await ApiService.createHistory(
        history,
      );

      debugPrint(
        'ResQNav destination history saved: '
        '$result',
      );
    } on ApiException catch (error) {
      debugPrint(
        'ResQNav destination history failed: '
        '${error.statusCode} - ${error.message}',
      );
    } catch (error) {
      debugPrint(
        'ResQNav destination history error: '
        '$error',
      );
    }
  }
  // =========================================================
  // MAP
  // =========================================================

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition:
          const CameraPosition(
        target: defaultLocation,
        zoom: 12.5,
      ),
      markers: markers,
      polylines: polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: true,
      onMapCreated: (
        GoogleMapController controller,
      ) {
        mapController = controller;

        final location =
            currentLocation;

        if (location != null) {
          controller.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: location,
                zoom: 14,
              ),
            ),
          );
        }
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Stack(
      children: [
        Positioned.fill(
          child: _buildMap(),
        ),

        // SEARCH
        Positioned(
          top: 20,
          left: 16,
          right: 16,
          child: _buildSearchPanel(),
        ),

        // LOCATION BUTTON
        Positioned(
          right: 16,
          bottom: 24,
          child:
              _buildLocationButton(),
        ),

        // DESTINATION CARD
        if (placeSelected)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child:
                _buildDestinationCard(),
          ),
      ],
    );
  }

  // =========================================================
  // SEARCH PANEL
  // =========================================================

  Widget _buildSearchPanel() {
    return Material(
      elevation: 8,
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(16),
      child: Container(
        height: 64,
        padding:
            const EdgeInsets.all(8),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: HtmlElementView(
          viewType:
              'resqnav-place-search',
          onPlatformViewCreated:
              (int viewId) {
            final containerId =
                'resqnav-place-search-$viewId';

            Timer(
              const Duration(
                milliseconds: 100,
              ),
              () {
                if (!mounted) {
                  return;
                }

                _initializePlaces(
                  containerId,
                );
              },
            );
          },
        ),
      ),
    );
  }

  // =========================================================
  // DESTINATION CARD
  // =========================================================

  Widget _buildDestinationCard() {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final compact =
            constraints.maxWidth < 650;

        return Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 760,
            ),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(16),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  18,
                ),
                boxShadow:
                    const [
                  BoxShadow(
                    blurRadius: 20,
                    offset:
                        Offset(0, 8),
                    color:
                        Color(
                      0x22000000,
                    ),
                  ),
                ],
              ),
              child: compact
                  ? _buildCompactDestinationCard()
                  : _buildWideDestinationCard(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWideDestinationCard() {
    return Row(
      children: [
        _buildDestinationIcon(),

        const SizedBox(width: 14),

        Expanded(
          child:
              _buildDestinationDetails(),
        ),

        const SizedBox(width: 14),

        _buildStartButton(),
      ],
    );
  }

  Widget _buildCompactDestinationCard() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildDestinationIcon(),

            const SizedBox(width: 12),

            Expanded(
              child:
                  _buildDestinationDetails(),
            ),
          ],
        ),

        const SizedBox(height: 14),

        _buildModeSelector(),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,
          child: _buildStartButton(),
        ),
      ],
    );
  }

  Widget _buildDestinationIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color:
            AppTheme.primary.withValues(
          alpha: 0.09,
        ),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: const Icon(
        Icons.location_on_rounded,
        color: AppTheme.primary,
        size: 24,
      ),
    );
  }

  Widget _buildDestinationDetails() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          selectedPlaceName,
          maxLines: 1,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight:
                FontWeight.w700,
            color:
                AppTheme.textPrimary,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          selectedPlaceAddress,
          maxLines: 2,
          overflow:
              TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            height: 1.4,
            color:
                AppTheme.textSecondary,
          ),
        ),

        if (routeDistance > 0 &&
            routeDuration > 0) ...[
          const SizedBox(height: 10),

          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.route_rounded,
                    size: 16,
                    color:
                        AppTheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDistance(
                      routeDistance,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),

              Row(
                mainAxisSize:
                    MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color:
                        AppTheme.primary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _formatDuration(
                      routeDuration,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ],
    );
  }

  // =========================================================
  // MODE SELECTOR
  // =========================================================

  Widget _buildModeSelector() {
    return Container(
      padding:
          const EdgeInsets.all(4),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFF1F4F8),
        borderRadius:
            BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          _buildModeButton(
            mode: 'car',
            icon:
                Icons.directions_car_rounded,
            label: 'Car',
          ),
          _buildModeButton(
            mode: 'walk',
            icon:
                Icons.directions_walk_rounded,
            label: 'Walk',
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required String mode,
    required IconData icon,
    required String label,
  }) {
    final selected =
        travelMode == mode;

    return InkWell(
      onTap: routeLoading
          ? null
          : () {
              setState(() {
                travelMode = mode;

                routeDistance = 0;
                routeDuration = 0;

                routeOrigin = null;

                polylines.clear();
              });
            },
      borderRadius:
          BorderRadius.circular(10),
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 9,
        ),
        decoration:
            BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.transparent,
          borderRadius:
              BorderRadius.circular(10),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    blurRadius: 6,
                    offset:
                        Offset(0, 2),
                    color:
                        Color(
                      0x14000000,
                    ),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected
                  ? AppTheme.primary
                  : AppTheme.textSecondary,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? AppTheme.primary
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // START BUTTON
  // =========================================================

  Widget _buildStartButton() {
    return ElevatedButton.icon(
      onPressed:
          routeLoading
              ? null
              : _startNavigation,
      icon: routeLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child:
                  CircularProgressIndicator(
                strokeWidth: 2,
              ),
            )
          : const Icon(
              Icons.navigation_rounded,
              size: 18,
            ),
      label: Text(
        routeLoading
            ? 'Finding route...'
            : routeDistance > 0
                ? 'Start Navigation'
                : 'Get Directions',
      ),
    );
  }

  // =========================================================
  // LOCATION BUTTON
  // =========================================================

  Widget _buildLocationButton() {
    return Material(
      elevation: 6,
      borderRadius:
          BorderRadius.circular(13),
      child: InkWell(
        onTap:
            locationLoading
                ? null
                : _loadCurrentLocation,
        borderRadius:
            BorderRadius.circular(13),
        child: Container(
          width: 48,
          height: 48,
          decoration:
              BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: locationLoading
              ? const Padding(
                  padding:
                      EdgeInsets.all(14),
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.my_location_rounded,
                  color:
                      AppTheme.primary,
                  size: 22,
                ),
        ),
      ),
    );
  }

  // =========================================================
  // FORMATTING
  // =========================================================

  String _formatDistance(
    double meters,
  ) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(
    double milliseconds,
  ) {
    final minutes =
        (milliseconds / 60000).round();

    if (minutes < 60) {
      return '$minutes min';
    }

    final hours = minutes ~/ 60;
    final remaining =
        minutes % 60;

    if (remaining == 0) {
      return '$hours hr';
    }

    return '$hours hr $remaining min';
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}