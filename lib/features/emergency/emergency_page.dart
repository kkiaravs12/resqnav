import 'dart:convert';
import 'dart:js_interop';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../services/api_service.dart';
import '../navigation/navigation_page.dart';
import 'package:url_launcher/url_launcher.dart';

@JS('computeResQNavRoute')
external void computeResQNavRoute(
  JSNumber originLat,
  JSNumber originLng,
  JSNumber destinationLat,
  JSNumber destinationLng,
  JSString travelMode,
  JSFunction callback,
);

class EmergencyPage extends StatefulWidget {
  final String? initialCategory;

  const EmergencyPage({
    super.key,
    this.initialCategory,
  });

  @override
  State<EmergencyPage> createState() =>
      _EmergencyPageState();
}

class _EmergencyPageState extends State<EmergencyPage> {
  GoogleMapController? mapController;

  static const LatLng defaultLocation = LatLng(
    19.0760,
    72.8777,
  );

  LatLng? currentLocation;

  bool locationLoading = false;
  bool routeLoading = false;
  bool servicesLoading = false;

  late String selectedCategory;
  String travelMode = 'car';
  String searchQuery = '';

  String? servicesError;

  EmergencyService? selectedService;

  List<EmergencyService> allServices = [];

  @override
  void initState() {
    super.initState();

    selectedCategory = (widget.initialCategory != null &&
            widget.initialCategory!.isNotEmpty)
        ? widget.initialCategory!
        : 'Hospital';

    _loadInitialLocation();
    _loadEmergencyServices();
  }

  // =========================================================
  // LOCATION
  // =========================================================

  Future<void> _loadInitialLocation() async {
    await _fetchCurrentLocation(
      showMapMove: true,
    );
  }

  Future<LatLng?> _fetchCurrentLocation({
    bool showMapMove = true,
  }) async {
    if (locationLoading) {
      return currentLocation;
    }

    setState(() {
      locationLoading = true;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        _showMessage(
          'Location services are disabled.',
        );

        return currentLocation;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission ==
          LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission ==
          LocationPermission.denied) {
        _showMessage(
          'Location permission was denied.',
        );

        return currentLocation;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        _showMessage(
          'Location permission is blocked in Edge.',
        );

        return currentLocation;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) {
        return location;
      }

      setState(() {
        currentLocation = location;
      });

      if (showMapMove &&
          mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: location,
              zoom: 14,
            ),
          ),
        );
      }

      return location;
    } catch (error) {
      debugPrint(
        'ResQNav emergency location error: $error',
      );

      _showMessage(
        'Unable to get your current location.',
      );

      return currentLocation;
    } finally {
      if (mounted) {
        setState(() {
          locationLoading = false;
        });
      }
    }
  }

  Future<void> _goToCurrentLocation() async {
    final location =
        await _fetchCurrentLocation(
      showMapMove: true,
    );

    if (location == null || !mounted) {
      return;
    }

    setState(() {
      selectedService = null;
    });
  }

  // =========================================================
  // EMERGENCY API
  // =========================================================

  Future<void> _loadEmergencyServices() async {
    if (servicesLoading) {
      return;
    }

    setState(() {
      servicesLoading = true;
      servicesError = null;
    });

    try {
      final data =
          await ApiService.getEmergencyServices();

      final services = data.map(
        (item) {
          return EmergencyService.fromJson(
            item,
          );
        },
      ).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        allServices = services;
        servicesLoading = false;
      });
    } catch (error) {
      debugPrint(
        'ResQNav emergency API error: $error',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        servicesLoading = false;
        servicesError =
            'Unable to load emergency services.';
        allServices = [];
      });

      _showMessage(
        'Unable to load emergency services from server.',
      );
    }
  }

  // =========================================================
  // FILTERING
  // =========================================================

  List<EmergencyService> get filteredServices {
    final query =
        searchQuery.trim().toLowerCase();

    final services =
        allServices.where((service) {
      final matchesCategory =
          service.category ==
              selectedCategory;

      final matchesSearch =
          query.isEmpty ||
          service.name
              .toLowerCase()
              .contains(query) ||
          service.address
              .toLowerCase()
              .contains(query);

      return matchesCategory &&
          matchesSearch;
    }).toList();

    final origin =
        currentLocation ?? defaultLocation;

    services.sort(
      (a, b) {
        final distanceA =
            _distanceInMeters(
          origin.latitude,
          origin.longitude,
          a.latitude,
          a.longitude,
        );

        final distanceB =
            _distanceInMeters(
          origin.latitude,
          origin.longitude,
          b.latitude,
          b.longitude,
        );

        return distanceA.compareTo(
          distanceB,
        );
      },
    );

    return services;
  }

  // =========================================================
  // CATEGORY
  // =========================================================

  void _selectCategory(
    String category,
  ) {
    setState(() {
      selectedCategory = category;
      selectedService = null;
      searchQuery = '';
    });

    final services = filteredServices;

    if (services.isNotEmpty) {
      _selectService(
        services.first,
        moveMap: true,
      );
    }
  }

  // =========================================================
  // SERVICE SELECTION
  // =========================================================

  Future<void> _selectService(
    EmergencyService service, {
    bool moveMap = true,
  }) async {
    setState(() {
      selectedService = service;
    });

    if (!moveMap ||
        mapController == null) {
      return;
    }

    await mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: service.location,
          zoom: 16,
        ),
      ),
    );
  }

  // =========================================================
  // DIRECTIONS
  // =========================================================

  Future<void> _getDirections(
    EmergencyService service,
  ) async {
    if (routeLoading) {
      return;
    }

    setState(() {
      routeLoading = true;
      selectedService = service;
    });

    try {
      LatLng? origin =
          currentLocation;

      origin ??= await _fetchCurrentLocation(
          showMapMove: false,
        );

      if (origin == null) {
        if (mounted) {
          setState(() {
            routeLoading = false;
          });
        }

        _showMessage(
          'Current location is required for directions.',
        );

        return;
      }

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
            throw const FormatException(
              'No route found.',
            );
          }

          setState(() {
            routeLoading = false;
          });

          // Save the successful emergency
          // route to Django history.
          //
          // Do not await this inside the JS
          // callback. Navigation should not
          // depend on the history request.
          _saveEmergencyHistory(
            service: service,
            distanceMeters: distance,
            durationMilliseconds: duration,
          );

          if (!mounted) {
            return;
          }

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) {
                return NavigationPage(
                  destinationName:
                      service.name,
                  destinationAddress:
                      service.address,
                  currentLocation:
                      origin!,
                  destinationLocation:
                      service.location,
                  routePoints:
                      routePoints,
                  distanceMeters:
                      distance,
                  durationMilliseconds:
                      duration,
                  travelMode:
                      travelMode,
                );
              },
            ),
          );
        } catch (error) {
          setState(() {
            routeLoading = false;
          });

          debugPrint(
            'ResQNav emergency route error: $error',
          );

          _showMessage(
            'Unable to create directions.',
          );
        }
      }

      computeResQNavRoute(
        origin.latitude.toJS,
        origin.longitude.toJS,
        service.latitude.toJS,
        service.longitude.toJS,
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
        'ResQNav emergency directions error: $error',
      );

      _showMessage(
        'Unable to start directions.',
      );
    }
  }

  // =========================================================
  // SAVE EMERGENCY HISTORY
  // =========================================================

  Future<void> _saveEmergencyHistory({
    required EmergencyService service,
    required double distanceMeters,
    required double durationMilliseconds,
  }) async {
    try {
      await ApiService.createHistory({
        'search_type': 'emergency',
        'query': service.name,
        'destination_name': service.name,
        'destination_address': service.address,
        'category': service.category,
        'latitude': service.latitude,
        'longitude': service.longitude,
        'distance_meters': distanceMeters,
        'duration_seconds':
            durationMilliseconds / 1000,
      });

      debugPrint(
        'ResQNav emergency history saved: ${service.name}',
      );
    } on ApiException catch (error) {
      debugPrint(
        'ResQNav emergency history save failed: ${error.message}',
      );
    } catch (error) {
      debugPrint(
        'ResQNav emergency history error: $error',
      );
    }
  }

  // =========================================================
// CALL EMERGENCY SERVICE
// =========================================================

  Future<void> _callService(
    EmergencyService service,
  ) async {
    final phone =
        service.phone.trim();

    if (phone.isEmpty) {
      _showMessage(
        'Phone number is not available.',
      );
      return;
    }

    final cleanedPhone =
        phone.replaceAll(
          RegExp(r'[^0-9+]'),
          '',
        );

    if (cleanedPhone.isEmpty) {
      _showMessage(
        'Invalid phone number.',
      );
      return;
    }

    final uri = Uri(
      scheme: 'tel',
      path: cleanedPhone,
    );

    try {
      final launched =
          await launchUrl(
        uri,
        mode:
            LaunchMode.externalApplication,
      );

      if (!launched && mounted) {
        _showMessage(
          'Unable to open the phone app.',
        );
      }
    } catch (error) {
      debugPrint(
        'ResQNav call error: $error',
      );

      if (mounted) {
        _showMessage(
          'Unable to start the call.',
        );
      }
    }
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

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final services =
            filteredServices;

        final isMobile =
            constraints.maxWidth < 800;

        if (isMobile) {
          return _buildMobileLayout(
            services,
            constraints.maxHeight,
          );
        }

        return _buildDesktopLayout(
          services,
        );
      },
    );
  }

  // =========================================================
  // MOBILE LAYOUT
  // =========================================================

  Widget _buildMobileLayout(
    List<EmergencyService> services,
    double availableHeight,
  ) {
    final mapHeight = math.max(
      270.0,
      math.min(
        370.0,
        availableHeight * 0.40,
      ),
    );

    return Column(
      children: [
        SizedBox(
          height: mapHeight,
          child: _buildMap(
            mobile: true,
          ),
        ),
        Expanded(
          child:
              _buildMobileServicePanel(
            services,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileServicePanel(
    List<EmergencyService> services,
  ) {
    return Container(
      decoration:
          const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 4,
            margin:
                const EdgeInsets.only(
              top: 9,
              bottom: 4,
            ),
            decoration: BoxDecoration(
              color:
                  const Color(0xFFD8DDE6),
              borderRadius:
                  BorderRadius.circular(20),
            ),
          ),

          _buildCategorySection(),

          _buildSearchField(),

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              12,
              18,
              7,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.near_me_rounded,
                  size: 17,
                  color: AppTheme.primary,
                ),
                const SizedBox(width: 6),
                const Text(
                  'Nearby services',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w800,
                    color:
                        AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${services.length} found',
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: servicesLoading
                ? _buildLoadingState()
                : servicesError != null
                    ? _buildErrorState()
                    : services.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            physics:
                                const BouncingScrollPhysics(),
                            padding:
                                const EdgeInsets.fromLTRB(
                              18,
                              4,
                              18,
                              22,
                            ),
                            itemCount:
                                services.length,
                            separatorBuilder:
                                (_, _) =>
                                    const SizedBox(
                              height: 10,
                            ),
                            itemBuilder:
                                (context, index) {
                              return _buildServiceCard(
                                services[index],
                                mobile: true,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // DESKTOP LAYOUT
  // =========================================================

  Widget _buildDesktopLayout(
    List<EmergencyService> services,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 390,
          child:
              _buildDesktopServicePanel(
            services,
          ),
        ),
        Expanded(
          child: _buildMap(
            mobile: false,
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopServicePanel(
    List<EmergencyService> services,
  ) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              20,
              18,
              20,
              10,
            ),
            child:
                _buildTravelModeSelector(),
          ),

          _buildCategorySection(),

          _buildSearchField(),

          Padding(
            padding:
                const EdgeInsets.fromLTRB(
              18,
              14,
              18,
              8,
            ),
            child: Row(
              children: [
                const Text(
                  'Nearby services',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${services.length} found',
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: servicesLoading
                ? _buildLoadingState()
                : servicesError != null
                    ? _buildErrorState()
                    : services.isEmpty
                        ? _buildEmptyState()
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(
                              18,
                              4,
                              18,
                              20,
                            ),
                            itemCount:
                                services.length,
                            separatorBuilder:
                                (_, _) =>
                                    const SizedBox(
                              height: 10,
                            ),
                            itemBuilder:
                                (context, index) {
                              return _buildServiceCard(
                                services[index],
                                mobile: false,
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // TRAVEL MODE
  // =========================================================

  Widget _buildTravelModeSelector() {
    return Container(
      padding:
          const EdgeInsets.all(4),
      decoration: BoxDecoration(
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
        decoration: BoxDecoration(
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
                        Color(0x14000000),
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
  // CATEGORIES
  // =========================================================

  Widget _buildCategorySection() {
    // Get all categories organized by type
    final emergencyCategories = AppConstants.emergencyOnly;
    final homeServiceCategories = AppConstants.homeServicesOnly;  
    final professionalCategories = AppConstants.professionalServicesOnly;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emergency Services Section
        _buildCategoryGroup(
          title: 'Emergency Services',
          categories: emergencyCategories,
          titleColor: AppTheme.danger,
        ),
        
        const SizedBox(height: 8),
        
        // Home Services Section  
        _buildCategoryGroup(
          title: 'Home Services',
          categories: homeServiceCategories,
          titleColor: AppTheme.primary,
        ),
        
        const SizedBox(height: 8),
        
        // Professional Services Section
        _buildCategoryGroup(
          title: 'Professional Services', 
          categories: professionalCategories,
          titleColor: AppTheme.textSecondary,
        ),
      ],
    );
  }

  Widget _buildCategoryGroup({
    required String title,
    required List<EmergencyCategory> categories,
    required Color titleColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: titleColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 8),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 9),
            itemBuilder: (context, index) {
              final category = categories[index];
              return _buildCategoryButton(
                category.id,
                category.icon,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryButton(
    String title,
    IconData icon,
  ) {
    final selected = selectedCategory == title;
    final category = AppConstants.getCategoryById(title);
    final isEmergency = AppConstants.isEmergencyCategory(title);
    
    // Use category-specific color or default
    final categoryColor = category?.color ?? AppTheme.primary;
    final bgColor = selected 
        ? categoryColor 
        : const Color(0xFFF5F7FA);
    final borderColor = selected 
        ? categoryColor 
        : const Color(0xFFE4E8EE);
    final iconColor = selected ? Colors.white : categoryColor;
    final textColor = selected ? Colors.white : AppTheme.textPrimary;

    String shortTitle;
    switch (title) {
      case 'Fire Station':
        shortTitle = 'Fire';
        break;
      case 'Pest Control':
        shortTitle = 'Pest';
        break;  
      default:
        shortTitle = title;
    }

    return InkWell(
      onTap: routeLoading ? null : () => _selectCategory(title),
      borderRadius: BorderRadius.circular(15),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 76,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: borderColor),
          // Add subtle shadow for emergency categories when selected
          boxShadow: selected && isEmergency ? [
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
            const SizedBox(height: 5),
            Text(
              shortTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // SEARCH
  // =========================================================

  Widget _buildSearchField() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 18,
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
        textInputAction:
            TextInputAction.search,
        decoration:
            InputDecoration(
          hintText:
              'Search nearby ${selectedCategory.toLowerCase()}s',
          prefixIcon:
              const Icon(
            Icons.search_rounded,
            size: 21,
          ),
          suffixIcon:
              searchQuery.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        setState(() {
                          searchQuery = '';
                        });
                      },
                      icon:
                          const Icon(
                        Icons.close_rounded,
                        size: 18,
                      ),
                    ),
          filled: true,
          fillColor:
              const Color(0xFFF6F8FC),
          contentPadding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 13,
          ),
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              14,
            ),
            borderSide:
                BorderSide.none,
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SERVICE CARD
  // =========================================================

  Widget _buildServiceCard(
    EmergencyService service, {
    required bool mobile,
  }) {
    final origin =
        currentLocation ??
            defaultLocation;

    final distance =
        _distanceInMeters(
      origin.latitude,
      origin.longitude,
      service.latitude,
      service.longitude,
    );

    final selected =
        selectedService?.id ==
            service.id;

    return Material(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(17),
      child: InkWell(
        onTap: () =>
            _selectService(service),
        borderRadius:
            BorderRadius.circular(17),
        child: Container(
          padding:
              const EdgeInsets.all(14),
          decoration:
              BoxDecoration(
            color: selected
                ? AppTheme.primary
                    .withValues(
                    alpha: 0.05,
                  )
                : Colors.white,
            borderRadius:
                BorderRadius.circular(
              17,
            ),
            border: Border.all(
              color: selected
                  ? AppTheme.primary
                      .withValues(
                      alpha: 0.30,
                    )
                  : const Color(
                      0xFFE6EAF0,
                    ),
            ),
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _buildServiceIcon(
                    service.category,
                  ),
                  const SizedBox(
                    width: 11,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 14,
                            fontWeight:
                                FontWeight.w800,
                            color: AppTheme
                                .textPrimary,
                          ),
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Text(
                          service.address,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 11,
                            height: 1.35,
                            color: AppTheme
                                .textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons.near_me_rounded,
                    size: 15,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Text(
                    _formatDistance(
                      distance,
                    ),
                    style:
                        const TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          AppTheme.primary,
                    ),
                  ),
                  const SizedBox(
                    width: 9,
                  ),
                  Container(
                    width: 4,
                    height: 4,
                    decoration:
                        const BoxDecoration(
                      shape:
                          BoxShape.circle,
                      color:
                          AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                  Expanded(
                    child: Text(
                      service.status,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style:
                          const TextStyle(
                        fontSize: 10,
                        color: AppTheme
                            .textSecondary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child:
                        OutlinedButton.icon(
                      onPressed:
                          routeLoading
                              ? null
                              : () {
                                  _selectService(
                                    service,
                                  );
                                },
                      style:
                          OutlinedButton
                              .styleFrom(
                        minimumSize:
                            const Size
                                .fromHeight(
                          44,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            11,
                          ),
                        ),
                      ),
                      icon:
                          const Icon(
                        Icons.map_rounded,
                        size: 17,
                      ),
                      label:
                          const Text(
                        'Map',
                      ),
                    ),
                  ),

                  const SizedBox(
                    width: 8,
                  ),

                  Expanded(
                    flex: 2,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          routeLoading
                              ? null
                              : () {
                                  _getDirections(
                                    service,
                                  );
                                },
                      style:
                          ElevatedButton
                              .styleFrom(
                        minimumSize:
                            const Size
                                .fromHeight(
                          44,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            11,
                          ),
                        ),
                      ),
                      icon:
                          routeLoading &&
                                  selected
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .directions_rounded,
                                  size: 17,
                                ),
                      label: Text(
                        routeLoading &&
                                selected
                            ? 'Routing...'
                            : 'Directions',
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              SizedBox(
                width: double.infinity,
                child:
                    OutlinedButton.icon(
                  onPressed: () {
                    _callService(service);
                  },
                  style:
                      OutlinedButton
                          .styleFrom(
                    minimumSize:
                        const Size
                            .fromHeight(
                      42,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        11,
                      ),
                    ),
                  ),
                  icon: const Icon(
                    Icons.call_rounded,
                    size: 16,
                  ),
                  label: Text(
                    service.phone,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // SERVICE ICON
  // =========================================================

  Widget _buildServiceIcon(
    String category,
  ) {
    // Get category info from constants
    final categoryInfo = AppConstants.getCategoryById(category);
    
    final icon = categoryInfo?.icon ?? Icons.help_outline_rounded;
    final color = categoryInfo?.color ?? AppTheme.primary;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(
        icon,
        color: color,
        size: 22,
      ),
    );
  }

  // =========================================================
  // LOADING
  // =========================================================

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          SizedBox(
            width: 30,
            height: 30,
            child:
                CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.primary,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Loading nearby services...',
            style: TextStyle(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color:
                  AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // ERROR
  // =========================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load services',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Please check that the Django server is running.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.4,
                color:
                    AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed:
                  _loadEmergencyServices,
              icon: const Icon(
                Icons.refresh_rounded,
                size: 17,
              ),
              label:
                  const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY
  // =========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 44,
              color:
                  Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            const Text(
              'No nearby services found',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try another category or search term.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color:
                    AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // MAP
  // =========================================================

  Widget _buildMap({
    required bool mobile,
  }) {
    final origin =
        currentLocation ??
            defaultLocation;

    final services =
        filteredServices;

    final Set<Marker> markers = {
      Marker(
        markerId:
            const MarkerId(
          'current_location',
        ),
        position: origin,
        infoWindow:
            const InfoWindow(
          title: 'Your location',
        ),
      ),
    };

    for (final service in services) {
      final selected =
          selectedService?.id ==
              service.id;

      markers.add(
        Marker(
          markerId:
              MarkerId(
            service.id.toString(),
          ),
          position:
              service.location,
          infoWindow:
              InfoWindow(
            title: service.name,
            snippet:
                service.address,
          ),
          onTap: () {
            _selectService(
              service,
              moveMap: false,
            );
          },
          icon:
              BitmapDescriptor
                  .defaultMarkerWithHue(
            selected
                ? BitmapDescriptor
                    .hueAzure
                : BitmapDescriptor
                    .hueRed,
          ),
        ),
      );
    }

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            initialCameraPosition:
                const CameraPosition(
              target: defaultLocation,
              zoom: 12.5,
            ),
            markers: markers,
            zoomControlsEnabled:
                false,
            mapToolbarEnabled:
                false,
            compassEnabled: true,
            myLocationEnabled:
                false,
            myLocationButtonEnabled:
                false,
            onMapCreated:
                (controller) async {
              mapController =
                  controller;

              if (currentLocation !=
                  null) {
                await controller
                    .animateCamera(
                  CameraUpdate
                      .newCameraPosition(
                    CameraPosition(
                      target:
                          currentLocation!,
                      zoom: 14,
                    ),
                  ),
                );
              }
            },
          ),
        ),

        // -------------------------------------------------
        // CATEGORY LABEL
        // -------------------------------------------------

        Positioned(
          left: mobile ? 14 : 18,
          top: mobile ? 14 : 18,
          child: Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 10,
                  offset:
                      Offset(0, 3),
                  color:
                      Color(0x18000000),
                ),
              ],
            ),
            child: Row(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emergency_rounded,
                  size: 16,
                  color: Colors.red,
                ),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  '$selectedCategory near you',
                  style:
                      const TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w800,
                    color: AppTheme
                        .textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // -------------------------------------------------
        // TRAVEL MODE
        // -------------------------------------------------

        Positioned(
          right: mobile ? 14 : 18,
          top: mobile ? 14 : 18,
          child: Material(
            elevation: 5,
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              13,
            ),
            child:
                _buildTravelModeSelector(),
          ),
        ),

        // -------------------------------------------------
        // CURRENT LOCATION
        // -------------------------------------------------

        Positioned(
          right: mobile ? 14 : 18,
          bottom:
              selectedService != null
                  ? 110
                  : 18,
          child: Material(
            elevation: 7,
            color: Colors.white,
            borderRadius:
                BorderRadius.circular(
              13,
            ),
            child: InkWell(
              onTap:
                  _goToCurrentLocation,
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
              child: SizedBox(
                width: 48,
                height: 48,
                child: locationLoading
                    ? const Padding(
                        padding:
                            EdgeInsets.all(
                          14,
                        ),
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme
                              .primary,
                        ),
                      )
                    : const Icon(
                        Icons
                            .my_location_rounded,
                        color: AppTheme
                            .primary,
                      ),
              ),
            ),
          ),
        ),

        // -------------------------------------------------
        // SELECTED SERVICE
        // -------------------------------------------------

        if (selectedService != null)
          Positioned(
            left: mobile ? 12 : 18,
            right: mobile ? 12 : 18,
            bottom: 14,
            child:
                _buildSelectedServiceOverlay(
              selectedService!,
              mobile: mobile,
            ),
          ),
      ],
    );
  }

  // =========================================================
  // SELECTED SERVICE OVERLAY
  // =========================================================

  Widget _buildSelectedServiceOverlay(
    EmergencyService service, {
    required bool mobile,
  }) {
    final origin =
        currentLocation ??
            defaultLocation;

    final distance =
        _distanceInMeters(
      origin.latitude,
      origin.longitude,
      service.latitude,
      service.longitude,
    );

    return Material(
      elevation: 12,
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(17),
      child: Padding(
        padding:
            const EdgeInsets.all(14),
        child: mobile
            ? Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildServiceIcon(
                        service.category,
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              service.name,
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color: AppTheme
                                    .textPrimary,
                              ),
                            ),
                            const SizedBox(
                              height: 3,
                            ),
                            Text(
                              '${_formatDistance(distance)} away • ${service.status}',
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style:
                                  const TextStyle(
                                fontSize: 10,
                                color: AppTheme
                                    .textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  SizedBox(
                    width:
                        double.infinity,
                    child:
                        ElevatedButton.icon(
                      onPressed:
                          routeLoading
                              ? null
                              : () {
                                  _getDirections(
                                    service,
                                  );
                                },
                      style:
                          ElevatedButton.styleFrom(
                        minimumSize:
                            const Size
                                .fromHeight(
                          42,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                            11,
                          ),
                        ),
                      ),
                      icon: routeLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth:
                                    2,
                                color:
                                    Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons
                                  .navigation_rounded,
                              size: 17,
                            ),
                      label: Text(
                        routeLoading
                            ? 'Creating route...'
                            : 'Get Directions',
                      ),
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  _buildServiceIcon(
                    service.category,
                  ),
                  const SizedBox(
                    width: 11,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          service.name,
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.w700,
                            color: AppTheme
                                .textPrimary,
                          ),
                        ),
                        const SizedBox(
                          height: 3,
                        ),
                        Text(
                          '${_formatDistance(distance)} away • ${service.status}',
                          maxLines: 1,
                          overflow:
                              TextOverflow
                                  .ellipsis,
                          style:
                              const TextStyle(
                            fontSize: 11,
                            color: AppTheme
                                .textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  ElevatedButton.icon(
                    onPressed:
                        routeLoading
                            ? null
                            : () {
                                _getDirections(
                                  service,
                                );
                              },
                    icon: const Icon(
                      Icons
                          .navigation_rounded,
                      size: 17,
                    ),
                    label:
                        const Text(
                      'Directions',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // =========================================================
  // DISTANCE
  // =========================================================

  double _distanceInMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius =
        6371000.0;

    final dLat =
        _degreesToRadians(
      lat2 - lat1,
    );

    final dLon =
        _degreesToRadians(
      lon2 - lon1,
    );

    final a =
        math.sin(dLat / 2) *
                math.sin(dLat / 2) +
            math.cos(
                  _degreesToRadians(
                    lat1,
                  ),
                ) *
                math.cos(
                  _degreesToRadians(
                    lat2,
                  ),
                ) *
                math.sin(dLon / 2) *
                math.sin(dLon / 2);

    final c =
        2 *
            math.atan2(
              math.sqrt(a),
              math.sqrt(1 - a),
            );

    return earthRadius * c;
  }

  double _degreesToRadians(
    double degrees,
  ) {
    return degrees *
        math.pi /
        180;
  }

  String _formatDistance(
    double meters,
  ) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }

    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}

// =============================================================
// EMERGENCY SERVICE MODEL
// =============================================================

class EmergencyService {
  final int id;
  final String name;
  final String category;
  final String address;
  final String phone;
  final double latitude;
  final double longitude;
  final String status;

  const EmergencyService({
    required this.id,
    required this.name,
    required this.category,
    required this.address,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  factory EmergencyService.fromJson(
    Map<String, dynamic> json,
  ) {
    return EmergencyService(
      id: (json['id'] as num).toInt(),

      name:
          json['name']?.toString() ?? '',

      category:
          json['category']?.toString() ?? '',

      address:
          json['address']?.toString() ?? '',

      phone:
          json['phone']?.toString() ?? '',

      latitude:
          double.tryParse(
                json['latitude']
                        ?.toString() ??
                    '',
              ) ??
              0.0,

      longitude:
          double.tryParse(
                json['longitude']
                        ?.toString() ??
                    '',
              ) ??
              0.0,

      status:
          json['status']?.toString() ?? '',
    );
  }

  LatLng get location {
    return LatLng(
      latitude,
      longitude,
    );
  }
}