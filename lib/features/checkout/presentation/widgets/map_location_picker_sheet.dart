import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/app_colors.dart';

class SelectedLocation {
  final String locationName;
  final String street;
  final String district;
  final String cityProvince;
  final double latitude;
  final double longitude;
  final String noteForDriver;
  final String label;

  const SelectedLocation({
    required this.locationName,
    required this.street,
    required this.district,
    required this.cityProvince,
    required this.latitude,
    required this.longitude,
    this.noteForDriver = '',
    this.label = 'Home',
  });

  String get fullAddress => locationName.contains(cityProvince)
      ? locationName
      : '$locationName, $cityProvince';

  String get formattedCoordinates =>
      '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
}

/// A landmark preset chip for instant map navigation
class LandmarkPreset {
  final String name;
  final String category;
  final IconData icon;
  final LatLng position;
  final String street;
  final String district;

  const LandmarkPreset({
    required this.name,
    required this.category,
    required this.icon,
    required this.position,
    required this.street,
    required this.district,
  });
}

class MapLocationPickerSheet extends StatefulWidget {
  final SelectedLocation? initialLocation;

  const MapLocationPickerSheet({super.key, this.initialLocation});

  static Future<SelectedLocation?> show(
    BuildContext context, {
    SelectedLocation? initialLocation,
  }) {
    return showModalBottomSheet<SelectedLocation>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) =>
          MapLocationPickerSheet(initialLocation: initialLocation),
    );
  }

  @override
  State<MapLocationPickerSheet> createState() => _MapLocationPickerSheetState();
}

class _MapLocationPickerSheetState extends State<MapLocationPickerSheet>
    with TickerProviderStateMixin {
  late double _latitude;
  late double _longitude;
  late String _locationName;
  late String _street;
  late String _district;
  late String _cityProvince;
  String _selectedLabel = 'Home';

  bool _isLocating = false;
  bool _isSearching = false;
  bool _isGeocoding = false;
  bool _isDraggingMap = false;
  bool _hasLocationPermission = false;
  bool _trafficEnabled = false;
  bool _showStores = true;

  List<SelectedLocation> _searchResults = [];
  GoogleMapController? _mapController;
  MapType _mapType = MapType.normal;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _geocodeDebounce;
  Timer? _searchDebounce;

  late AnimationController _pinAnimController;
  late Animation<double> _pinLiftAnim;
  late Animation<double> _shadowScaleAnim;

  late AnimationController _radarAnimController;
  late Animation<double> _radarScaleAnim;
  late Animation<double> _radarOpacityAnim;

  static const LatLng _defaultCenter = LatLng(11.556400, 104.928200);

  // Cambodia geographic bounding box
  static final LatLngBounds _cambodiaBounds = LatLngBounds(
    southwest: const LatLng(9.0, 101.5),
    northeast: const LatLng(15.5, 108.5),
  );

  static final List<LandmarkPreset> _landmarks = [
    const LandmarkPreset(
      name: 'Cherish Flagship (BKK1)',
      category: 'Store',
      icon: Icons.storefront_rounded,
      position: LatLng(11.5520, 104.9255),
      street: 'Street 302, Boeung Keng Kang 1',
      district: 'Boeung Keng Kang',
    ),
    const LandmarkPreset(
      name: 'Aeon Sen Sok City',
      category: 'Mall',
      icon: Icons.shopping_bag_outlined,
      position: LatLng(11.6033, 104.8814),
      street: 'St 1003, Bayab Village, Sen Sok',
      district: 'Sen Sok',
    ),
    const LandmarkPreset(
      name: 'Aeon Mall Samdach Sothearos',
      category: 'Mall',
      icon: Icons.local_mall_outlined,
      position: LatLng(11.5478, 104.9351),
      street: '#132, Samdach Sothearos Blvd',
      district: 'Chamkar Mon',
    ),
    const LandmarkPreset(
      name: 'TK Avenue (Toul Kork)',
      category: 'Mall',
      icon: Icons.store_mall_directory_outlined,
      position: LatLng(11.5831, 104.8988),
      street: 'Corner St 315 & St 516, Toul Kork',
      district: 'Toul Kork',
    ),
    const LandmarkPreset(
      name: 'Olympia City Mall',
      category: 'Mall',
      icon: Icons.apartment_outlined,
      position: LatLng(11.5619, 104.9126),
      street: 'Monireth Blvd (217), 7 Makara',
      district: '7 Makara',
    ),
    const LandmarkPreset(
      name: 'Royal Palace Phnom Penh',
      category: 'Landmark',
      icon: Icons.account_balance_outlined,
      position: LatLng(11.5638, 104.9304),
      street: 'Samdach Sothearos Blvd',
      district: 'Daun Penh',
    ),
    const LandmarkPreset(
      name: 'Phnom Penh Int’l Airport',
      category: 'Transport',
      icon: Icons.flight_takeoff_rounded,
      position: LatLng(11.5466, 104.8441),
      street: 'Russian Federation Blvd',
      district: 'Pou Senchey',
    ),
  ];

  static bool _isInCambodia(double lat, double lon) {
    return lat >= 9.0 && lat <= 15.5 && lon >= 101.5 && lon <= 108.5;
  }

  @override
  void initState() {
    super.initState();

    if (widget.initialLocation != null) {
      _latitude = widget.initialLocation!.latitude;
      _longitude = widget.initialLocation!.longitude;
      _locationName = widget.initialLocation!.locationName;
      _street = widget.initialLocation!.street;
      _district = widget.initialLocation!.district;
      _cityProvince = widget.initialLocation!.cityProvince;
      _selectedLabel = widget.initialLocation!.label;
      _noteController.text = widget.initialLocation!.noteForDriver;
    } else {
      _latitude = _defaultCenter.latitude;
      _longitude = _defaultCenter.longitude;
      _locationName = 'Preah Norodom Boulevard (41), Phnom Penh, Cambodia';
      _street = 'Preah Norodom Boulevard (41)';
      _district = 'Sangkat Chakto Mukh';
      _cityProvince = 'Phnom Penh';
    }
    if (widget.initialLocation != null) {
      _searchController.text = _locationName;
    }

    // Pin Physics Animations (Google Maps style)
    _pinAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _pinLiftAnim = Tween<double>(begin: 0.0, end: -24.0).animate(
      CurvedAnimation(
        parent: _pinAnimController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.bounceOut,
      ),
    );
    _shadowScaleAnim = Tween<double>(begin: 1.0, end: 0.45).animate(
      CurvedAnimation(
        parent: _pinAnimController,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeIn,
      ),
    );

    // Radar Pulse Animation
    _radarAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _radarScaleAnim = Tween<double>(begin: 0.8, end: 2.2).animate(
      CurvedAnimation(parent: _radarAnimController, curve: Curves.easeOutCubic),
    );
    _radarOpacityAnim = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _radarAnimController, curve: Curves.easeOutQuad),
    );

    _checkInitialPermission();
  }

  Future<void> _checkInitialPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        if (mounted) setState(() => _hasLocationPermission = true);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _searchDebounce?.cancel();
    _pinAnimController.dispose();
    _radarAnimController.dispose();
    _mapController?.dispose();
    _searchController.dispose();
    _noteController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ====================== GEOCODING ======================

  Future<void> _fetchReverseGeocode(double lat, double lon) async {
    if (!mounted) return;
    setState(() => _isGeocoding = true);

    // 1. Try Google Maps Geocoding API (Forced English)
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lon&language=en&key=${ApiConstants.googleMapsApiKey}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'OK' &&
            data['results'] is List &&
            (data['results'] as List).isNotEmpty) {
          final first = data['results'][0];
          final formatted = (first['formatted_address'] ?? _locationName)
              .toString();
          String street = _street;
          String district = _district;
          String city = _cityProvince;
          for (final comp in (first['address_components'] as List? ?? [])) {
            final types = (comp['types'] as List?)?.cast<String>() ?? [];
            if (types.contains('route') || types.contains('street_number')) {
              street = comp['long_name']?.toString() ?? street;
            } else if (types.contains('sublocality') ||
                types.contains('sublocality_level_1') ||
                types.contains('neighborhood')) {
              district = comp['long_name']?.toString() ?? district;
            } else if (types.contains('locality') ||
                types.contains('administrative_area_level_1')) {
              city = comp['long_name']?.toString() ?? city;
            }
          }
          if (mounted) {
            setState(() {
              _locationName = formatted;
              _street = street;
              _district = district;
              _cityProvince = city;
              _isGeocoding = false;
            });
          }
          return;
        }
      }
    } catch (_) {}

    // 2. OpenStreetMap Fallback (Forced English)
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1&accept-language=en',
      );
      final res = await http
          .get(
            url,
            headers: {
              'User-Agent': 'CherishBabyApp/2.0',
              'Accept-Language': 'en',
            },
          )
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        final addr = data['address'] as Map<String, dynamic>? ?? {};
        final road =
            (addr['road'] ?? addr['neighbourhood'] ?? addr['suburb'] ?? _street)
                .toString();
        final sub = (addr['suburb'] ?? addr['city_district'] ?? _district)
            .toString();
        final city = (addr['city'] ?? addr['state'] ?? _cityProvince)
            .toString();
        final displayName = (data['display_name'] ?? '$road, $sub, $city')
            .toString();
        if (mounted) {
          setState(() {
            _locationName = displayName;
            _street = road;
            _district = sub;
            _cityProvince = city;
            _isGeocoding = false;
          });
        }
        return;
      }
    } catch (_) {}

    if (mounted) setState(() => _isGeocoding = false);
  }

  void _onCameraMoveStarted() {
    if (!_isDraggingMap) {
      _pinAnimController.forward();
      setState(() => _isDraggingMap = true);
    }
  }

  void _onCameraIdle() {
    if (_isDraggingMap) {
      _pinAnimController.reverse().then((_) {
        HapticFeedback.selectionClick();
      });
      setState(() => _isDraggingMap = false);
    }
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(const Duration(milliseconds: 350), () {
      _fetchReverseGeocode(_latitude, _longitude);
    });
  }

  void _onSearchChanged(String query) {
    final trimmed = query.trim();
    _searchDebounce?.cancel();
    if (trimmed.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _queryGoogleSearch(trimmed);
    });
  }

  Future<void> _queryGoogleSearch(String query) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(query)}&components=country:KH&language=en&key=${ApiConstants.googleMapsApiKey}',
      );
      final res = await http.get(url).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['status'] == 'OK' && data['results'] is List && mounted) {
          final results = (data['results'] as List).map((item) {
            final loc = item['geometry']['location'];
            final lat = (loc['lat'] as num).toDouble();
            final lon = (loc['lng'] as num).toDouble();
            final formatted = (item['formatted_address'] ?? query).toString();
            String street = query, district = 'Phnom Penh', city = 'Phnom Penh';
            for (final comp in (item['address_components'] as List? ?? [])) {
              final types = (comp['types'] as List?)?.cast<String>() ?? [];
              if (types.contains('route') || types.contains('street_number')) {
                street = comp['long_name']?.toString() ?? street;
              } else if (types.contains('sublocality') ||
                  types.contains('sublocality_level_1') ||
                  types.contains('neighborhood')) {
                district = comp['long_name']?.toString() ?? district;
              } else if (types.contains('locality') ||
                  types.contains('administrative_area_level_1')) {
                city = comp['long_name']?.toString() ?? city;
              }
            }
            return SelectedLocation(
              locationName: formatted,
              street: street,
              district: district,
              cityProvince: city,
              latitude: lat,
              longitude: lon,
            );
          }).toList();

          if (mounted) {
            setState(() {
              _searchResults = results;
            });
          }
          return;
        }
      }
    } catch (_) {}

    // Fallback: OSM Search
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}+Cambodia&format=json&addressdetails=1&limit=5&accept-language=en',
      );
      final res = await http.get(
        url,
        headers: {'User-Agent': 'CherishBabyApp/2.0', 'Accept-Language': 'en'},
      );
      if (res.statusCode == 200 && mounted) {
        final data = json.decode(res.body) as List;
        setState(() {
          _searchResults = data.map((item) {
            final lat = double.tryParse(item['lat'].toString()) ?? 11.5564;
            final lon = double.tryParse(item['lon'].toString()) ?? 104.9282;
            final addr = item['address'] as Map<String, dynamic>? ?? {};
            return SelectedLocation(
              locationName: (item['display_name'] ?? query).toString(),
              street: (addr['road'] ?? addr['suburb'] ?? query).toString(),
              district:
                  (addr['suburb'] ?? addr['city_district'] ?? 'Phnom Penh')
                      .toString(),
              cityProvince: (addr['city'] ?? addr['state'] ?? 'Phnom Penh')
                  .toString(),
              latitude: lat,
              longitude: lon,
            );
          }).toList();
        });
      }
    } catch (_) {}
  }

  void _selectLocationDirectly({
    required double lat,
    required double lon,
    required String name,
    required String street,
    required String district,
    String city = 'Phnom Penh',
  }) {
    HapticFeedback.selectionClick();
    setState(() {
      _latitude = lat;
      _longitude = lon;
      _locationName = name;
      _street = street;
      _district = district;
      _cityProvince = city;
      _isSearching = false;
      _searchResults = [];
      _searchController.text = name;
      _searchFocusNode.unfocus();
    });

    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lon), zoom: 17, tilt: 15),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    HapticFeedback.lightImpact();
    setState(() => _isLocating = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Location services are disabled. Please enable GPS.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '⚠️ Location permission permanently denied. Enable in Settings.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Location permission was denied.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      if (mounted) setState(() => _hasLocationPermission = true);

      Position? position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 4),
          ),
        );
      } catch (_) {
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 4),
            ),
          );
        } catch (_) {
          position = await Geolocator.getLastKnownPosition();
        }
      }

      if (position == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Could not obtain GPS coordinates.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _isLocating = false);
        return;
      }

      double lat = position.latitude;
      double lon = position.longitude;

      // Swapped lat/lon correction
      if (lat > 50.0 && lon < 25.0) {
        final temp = lat;
        lat = lon;
        lon = temp;
      }

      if (!_isInCambodia(lat, lon)) {
        if (mounted) {
          setState(() => _isLocating = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '📍 GPS coordinates outside Cambodia: (${lat.toStringAsFixed(3)}, ${lon.toStringAsFixed(3)}).\n'
                'Set simulator location to Phnom Penh (Lat: 11.5564, Lon: 104.9282).',
              ),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _latitude = lat;
          _longitude = lon;
        });
        await _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(lat, lon), zoom: 17.5, tilt: 20),
          ),
        );
        await _fetchReverseGeocode(lat, lon);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Location error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLocating = false);
  }

  void _showMapLayerSelector(BuildContext context, bool isDark) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(90),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Map Settings & Layers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF202124),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMapTypeOption(
                        title: 'Default',
                        icon: Icons.map_outlined,
                        isSelected: _mapType == MapType.normal,
                        isDark: isDark,
                        onTap: () {
                          setState(() => _mapType = MapType.normal);
                          setSheetState(() {});
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildMapTypeOption(
                        title: 'Satellite',
                        icon: Icons.satellite_alt_rounded,
                        isSelected:
                            _mapType == MapType.satellite ||
                            _mapType == MapType.hybrid,
                        isDark: isDark,
                        onTap: () {
                          setState(() => _mapType = MapType.hybrid);
                          setSheetState(() {});
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildMapTypeOption(
                        title: 'Terrain',
                        icon: Icons.terrain_rounded,
                        isSelected: _mapType == MapType.terrain,
                        isDark: isDark,
                        onTap: () {
                          setState(() => _mapType = MapType.terrain);
                          setSheetState(() {});
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Live Traffic Conditions',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Real-time traffic flow overlay',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    secondary: const Icon(
                      Icons.traffic_rounded,
                      color: Colors.amber,
                    ),
                    value: _trafficEnabled,
                    activeThumbColor: AppColors.accent,
                    onChanged: (val) {
                      setState(() => _trafficEnabled = val);
                      setSheetState(() {});
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Show Cherish Outlets',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    subtitle: const Text(
                      'Official store locations & pickup points',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    secondary: const Icon(
                      Icons.storefront_rounded,
                      color: AppColors.accent,
                    ),
                    value: _showStores,
                    activeThumbColor: AppColors.accent,
                    onChanged: (val) {
                      setState(() => _showStores = val);
                      setSheetState(() {});
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMapTypeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF1A73E8).withAlpha(30)
                  : (isDark
                        ? const Color(0xFF333333)
                        : const Color(0xFFF1F3F4)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 32,
              color: isSelected
                  ? AppColors.accent
                  : (isDark ? Colors.white70 : const Color(0xFF5F6368)),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? AppColors.accent
                  : (isDark ? Colors.white70 : const Color(0xFF3C4043)),
            ),
          ),
        ],
      ),
    );
  }

  Set<Marker> _buildStoreMarkers() {
    if (!_showStores) return {};
    return _landmarks
        .where((l) => l.category == 'Store')
        .map(
          (store) => Marker(
            markerId: MarkerId(store.name),
            position: store.position,
            infoWindow: InfoWindow(
              title: store.name,
              snippet: '${store.street} • Official Store',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          ),
        )
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final media = MediaQuery.of(context);
    final size = media.size;
    final sheetHeight = size.height * 0.96;
    final controlsBottomOffset = math.min(sheetHeight * 0.42, 292.0);
    final searchResultsTop = media.padding.top + 116;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Stack(
          children: [
            // ================= 1. NATIVE GOOGLE MAP =================
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_latitude, _longitude),
                  zoom: 16.5,
                  tilt: 20,
                ),
                cameraTargetBounds: CameraTargetBounds(_cambodiaBounds),
                minMaxZoomPreference: const MinMaxZoomPreference(6, 20),
                mapType: _mapType,
                myLocationEnabled: _hasLocationPermission,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                compassEnabled: true,
                buildingsEnabled: true,
                trafficEnabled: _trafficEnabled,
                markers: _buildStoreMarkers(),
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                onCameraMoveStarted: _onCameraMoveStarted,
                onCameraMove: (position) {
                  _latitude = position.target.latitude;
                  _longitude = position.target.longitude;
                },
                onCameraIdle: _onCameraIdle,
              ),
            ),

            _buildCenterPin(isDark),

            // ================= 3. FLOATING TOP SEARCH BAR & LANDMARK CHIPS =================
            _buildTopSearchArea(isDark),

            // ================= 4. SEARCH AUTOCOMPLETE DROPDOWN =================
            if (_isSearching && _searchResults.isNotEmpty)
              _buildSearchResultsPanel(isDark, searchResultsTop, size),

            // ================= 5. FLOATING MAP CONTROLS (RIGHT SIDE) =================
            Positioned(
              right: 14,
              bottom: controlsBottomOffset,
              child: _buildMapControls(isDark),
            ),

            // ================= 6. BOTTOM DELIVERY DETAILS CARD =================
            _buildDeliveryDetailsPanel(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPin(bool isDark) {
    final statusText = _isGeocoding
        ? 'Finding address'
        : (_isDraggingMap ? 'Setting pin' : null);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          if (!_isDraggingMap)
            AnimatedBuilder(
              animation: _radarAnimController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _radarScaleAnim.value,
                  child: Opacity(
                    opacity: _radarOpacityAnim.value,
                    child: Container(
                      width: 34,
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.accent, width: 2),
                      ),
                    ),
                  ),
                );
              },
            ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AppColors.accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withAlpha(120),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pinAnimController,
            builder: (context, child) {
              return Transform.scale(
                scale: _shadowScaleAnim.value,
                child: Opacity(
                  opacity: (1.0 - _pinAnimController.value * 0.65).clamp(
                    0.25,
                    0.85,
                  ),
                  child: Container(
                    width: 24,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(145),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _pinAnimController,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -50.0 + _pinLiftAnim.value),
                child: child,
              );
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: statusText == null
                      ? const SizedBox(height: 0)
                      : Container(
                          key: ValueKey(statusText),
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.surfaceDark.withAlpha(238)
                                : Colors.white.withAlpha(245),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(28),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isGeocoding)
                                const SizedBox(
                                  width: 13,
                                  height: 13,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accent,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.location_searching_rounded,
                                  size: 14,
                                  color: AppColors.accent,
                                ),
                              const SizedBox(width: 7),
                              Text(
                                statusText,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
                const CustomPaint(
                  size: Size(36, 50),
                  painter: GoogleMapsPinPainter(
                    primaryColor: AppColors.accent,
                    innerEyeColor: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSearchArea(bool isDark) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 54,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark.withAlpha(244)
                      : Colors.white.withAlpha(248),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(24),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Tooltip(
                      message: 'Close',
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                          size: 22,
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        onChanged: _onSearchChanged,
                        textInputAction: TextInputAction.search,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search street, landmark, district',
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ),
                    if (_searchController.text.isNotEmpty)
                      Tooltip(
                        message: 'Clear search',
                        child: IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                            size: 20,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _isSearching = false;
                              _searchResults = [];
                            });
                          },
                        ),
                      ),
                    Tooltip(
                      message: 'Map layers',
                      child: IconButton(
                        icon: const Icon(
                          Icons.layers_rounded,
                          color: AppColors.accent,
                          size: 22,
                        ),
                        onPressed: () => _showMapLayerSelector(context, isDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildShortcutChip(
                      isDark: isDark,
                      icon: Icons.my_location_rounded,
                      label: _isLocating ? 'Locating' : 'My Location',
                      isBusy: _isLocating,
                      onPressed: _isLocating ? null : _useCurrentLocation,
                    ),
                    ..._landmarks.map(
                      (landmark) => _buildShortcutChip(
                        isDark: isDark,
                        icon: landmark.icon,
                        label: landmark.name,
                        isStore: landmark.category == 'Store',
                        onPressed: () => _selectLocationDirectly(
                          lat: landmark.position.latitude,
                          lon: landmark.position.longitude,
                          name: '${landmark.name}, ${landmark.street}',
                          street: landmark.street,
                          district: landmark.district,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutChip({
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    bool isBusy = false,
    bool isStore = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: isBusy
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.8,
                  color: AppColors.accent,
                ),
              )
            : Icon(
                icon,
                size: 16,
                color: isStore
                    ? AppColors.accent
                    : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight),
              ),
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: isDark
              ? AppColors.textPrimaryDark
              : AppColors.textPrimaryLight,
        ),
        backgroundColor: isDark
            ? AppColors.surfaceDark.withAlpha(238)
            : Colors.white.withAlpha(245),
        side: BorderSide(
          color: isStore
              ? AppColors.accent.withAlpha(90)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        elevation: 2,
        shadowColor: Colors.black.withAlpha(24),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSearchResultsPanel(bool isDark, double top, Size size) {
    return Positioned(
      top: top,
      left: 14,
      right: 14,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: math.min(size.height * 0.38, 320.0),
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(42),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _searchResults.length,
          separatorBuilder: (context, index) => Divider(
            height: 1,
            indent: 64,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          itemBuilder: (ctx, i) {
            final place = _searchResults[i];
            return ListTile(
              minLeadingWidth: 38,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(22),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ),
              title: Text(
                place.locationName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${place.district}, ${place.cityProvince}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(
                Icons.north_west_rounded,
                size: 18,
                color: AppColors.accent,
              ),
              onTap: () => _selectLocationDirectly(
                lat: place.latitude,
                lon: place.longitude,
                name: place.locationName,
                street: place.street,
                district: place.district,
                city: place.cityProvince,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapControls(bool isDark) {
    return Column(
      children: [
        _buildRoundMapButton(
          isDark: isDark,
          icon: Icons.explore_rounded,
          tooltip: 'Reset bearing',
          onTap: () {
            HapticFeedback.selectionClick();
            _mapController?.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: LatLng(_latitude, _longitude),
                  zoom: 16.5,
                  bearing: 0,
                  tilt: 0,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 10),
        Container(
          width: 46,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceDark.withAlpha(238)
                : Colors.white.withAlpha(245),
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Tooltip(
                message: 'Zoom in',
                child: IconButton(
                  icon: const Icon(Icons.add_rounded, size: 22),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _mapController?.animateCamera(CameraUpdate.zoomIn());
                  },
                ),
              ),
              Container(
                width: 24,
                height: 1,
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              Tooltip(
                message: 'Zoom out',
                child: IconButton(
                  icon: const Icon(Icons.remove_rounded, size: 22),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _mapController?.animateCamera(CameraUpdate.zoomOut());
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _buildRoundMapButton(
          isDark: isDark,
          icon: Icons.my_location_rounded,
          tooltip: 'Use current location',
          isBusy: _isLocating,
          onTap: _isLocating ? null : _useCurrentLocation,
        ),
      ],
    );
  }

  Widget _buildRoundMapButton({
    required bool isDark,
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
    bool isBusy = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isDark
            ? AppColors.surfaceDark.withAlpha(238)
            : Colors.white.withAlpha(245),
        shape: const CircleBorder(),
        elevation: 4,
        shadowColor: Colors.black.withAlpha(30),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 46,
            child: Center(
              child: isBusy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    )
                  : Icon(icon, size: 22, color: AppColors.accent),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryDetailsPanel(bool isDark) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(28),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : const Color(0xFFDADCE0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(24),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      color: AppColors.accent,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Delivery address',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            if (_isGeocoding) ...[
                              const SizedBox(width: 8),
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.7,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _street.isNotEmpty ? _street : _locationName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _locationName,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.25,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _buildCoordinatesChip(isDark),
                  ...[
                    'Home',
                    'Work',
                    'Other',
                  ].map((label) => _buildLabelChip(label, isDark)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceSoftDark
                      : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      size: 18,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Apartment, floor, or driver note',
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  SizedBox(
                    width: 52,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _confirmLocation,
                        icon: const Icon(
                          Icons.check_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Confirm delivery location',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoordinatesChip(bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Clipboard.setData(
          ClipboardData(
            text:
                '${_latitude.toStringAsFixed(6)}, ${_longitude.toStringAsFixed(6)}',
          ),
        );
        HapticFeedback.selectionClick();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Coordinates copied'),
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceSoftDark : AppColors.accentLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.gps_fixed_rounded,
              size: 13,
              color: AppColors.accent,
            ),
            const SizedBox(width: 5),
            Text(
              '${_latitude.toStringAsFixed(5)}, ${_longitude.toStringAsFixed(5)}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.copy_rounded,
              size: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelChip(String label, bool isDark) {
    final isSelected = _selectedLabel == label;
    final IconData icon = switch (label) {
      'Home' => Icons.home_rounded,
      'Work' => Icons.work_rounded,
      _ => Icons.bookmark_rounded,
    };

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedLabel = label);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent
              : (isDark ? AppColors.surfaceSoftDark : const Color(0xFFF4F5F2)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? AppColors.accent
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected
                  ? Colors.white
                  : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: isSelected
                    ? Colors.white
                    : (isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLocation() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      SelectedLocation(
        locationName: _locationName,
        street: _street,
        district: _district,
        cityProvince: _cityProvince,
        latitude: _latitude,
        longitude: _longitude,
        noteForDriver: _noteController.text.trim(),
        label: _selectedLabel,
      ),
    );
  }
}

/// Exact vector renderer for the iconic Google Maps teardrop pin
class GoogleMapsPinPainter extends CustomPainter {
  final Color primaryColor;
  final Color innerEyeColor;
  final Color dotColor;

  const GoogleMapsPinPainter({
    this.primaryColor = const Color(0xFFEA4335), // Google Maps Red
    this.innerEyeColor = const Color(0xFFB31412), // Dark Cherry
    this.dotColor = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final radius = w / 2;
    final centerX = w / 2;
    final centerY = radius;

    // Pin Body Path
    final path = Path();
    // Start at bottom tip
    path.moveTo(centerX, h);
    // Smooth bezier curve to the left tangent of top circular head
    path.cubicTo(
      centerX - w * 0.18,
      h - h * 0.35,
      0,
      centerY + radius * 0.55,
      0,
      centerY,
    );
    // Arc across the top circle
    path.arcToPoint(
      Offset(w, centerY),
      radius: Radius.circular(radius),
      clockwise: true,
    );
    // Smooth bezier curve down to the bottom tip
    path.cubicTo(
      w,
      centerY + radius * 0.55,
      centerX + w * 0.18,
      h - h * 0.35,
      centerX,
      h,
    );
    path.close();

    // 1. Drop shadow around pin
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);

    // 2. Google Maps gradient fill
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFFF574D), // Highlight top-left
        primaryColor, // True Google Red
        const Color(0xFFC5221F), // Darker bottom-right
      ],
      stops: const [0.0, 0.5, 1.0],
    );
    final pinPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, pinPaint);

    // 3. Subtle inner stroke highlight
    final strokePaint = Paint()
      ..color = Colors.white.withAlpha(50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawPath(path, strokePaint);

    // 4. Inner Eye (Circle hole in Google Maps Pin)
    final eyePaint = Paint()
      ..color = innerEyeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.40, eyePaint);

    // 5. Center Core Dot
    final corePaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.18, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Google Maps "Dropped Pin" callout speech bubble with downward pointer arrow
class GoogleMapsCalloutPainter extends CustomPainter {
  final Color backgroundColor;

  const GoogleMapsCalloutPainter({required this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height - 6.0; // Reserve 6px at bottom for pointer beak
    const r = 14.0;

    final path = Path();
    path.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, w, h),
        const Radius.circular(r),
      ),
    );

    // Downward pointing triangle pointer beak at center bottom
    const beakWidth = 12.0;
    const beakHeight = 6.0;
    final beakCenterX = w / 2;
    path.moveTo(beakCenterX - beakWidth / 2, h);
    path.lineTo(beakCenterX, h + beakHeight);
    path.lineTo(beakCenterX + beakWidth / 2, h);
    path.close();

    // Drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withAlpha(50)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(path.shift(const Offset(0, 2)), shadowPaint);

    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, bgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
