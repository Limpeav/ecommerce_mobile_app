import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class StoreBranch {
  final String id;
  final String name;
  final String address;
  final String district;
  final String city;
  final String openHours;
  final String phone;
  final LatLng coordinates;
  final List<String> highlights;
  final String imageUrl;

  const StoreBranch({
    required this.id,
    required this.name,
    required this.address,
    required this.district,
    required this.city,
    required this.openHours,
    required this.phone,
    required this.coordinates,
    required this.highlights,
    required this.imageUrl,
  });
}

class StoreLocatorPage extends StatefulWidget {
  const StoreLocatorPage({super.key});

  @override
  State<StoreLocatorPage> createState() => _StoreLocatorPageState();
}

class _StoreLocatorPageState extends State<StoreLocatorPage> {
  GoogleMapController? _mapController;
  int _selectedView = 0; // 0 = Map, 1 = List
  StoreBranch? _selectedStore;
  Position? _userPosition;
  String _selectedFilter = 'All';

  static const List<StoreBranch> _branches = [
    StoreBranch(
      id: 'store_bkk1',
      name: 'Cherish Flagship Boutique (BKK1)',
      address: '#45, Street 302, Sangkat Boeung Keng Kang 1',
      district: 'Boeung Keng Kang',
      city: 'Phnom Penh',
      openHours: '8:30 AM – 9:30 PM (Daily)',
      phone: '+855 23 888 123',
      coordinates: LatLng(11.5520, 104.9255),
      highlights: ['Full Collection', 'Nursery Design Studio', 'Curbside Pickup'],
      imageUrl: 'https://images.unsplash.com/photo-1555529771-7888783a18d3?w=600&auto=format&fit=crop&q=60',
    ),
    StoreBranch(
      id: 'store_aeon2',
      name: 'Cherish Outlet (Aeon Mall Sen Sok)',
      address: '2nd Floor, St 1003, Bayab Village, Sen Sok',
      district: 'Sen Sok',
      city: 'Phnom Penh',
      openHours: '9:00 AM – 10:00 PM (Daily)',
      phone: '+855 23 999 456',
      coordinates: LatLng(11.6033, 104.8814),
      highlights: ['Stroller Demos', 'Car Seat Fitting', 'Instant Pickup'],
      imageUrl: 'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=600&auto=format&fit=crop&q=60',
    ),
    StoreBranch(
      id: 'store_tk',
      name: 'Cherish Baby Boutique (TK Avenue)',
      address: 'Ground Floor, Corner St 315 & St 516',
      district: 'Toul Kork',
      city: 'Phnom Penh',
      openHours: '9:00 AM – 9:00 PM (Daily)',
      phone: '+855 23 777 789',
      coordinates: LatLng(11.5831, 104.8988),
      highlights: ['Newborn Essentials', 'Organic Apparel', 'Gift Registry'],
      imageUrl: 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=600&auto=format&fit=crop&q=60',
    ),
    StoreBranch(
      id: 'store_olympia',
      name: 'Cherish Store (Olympia City Mall)',
      address: 'Level 1, Monireth Blvd (217), 7 Makara',
      district: '7 Makara',
      city: 'Phnom Penh',
      openHours: '9:00 AM – 9:30 PM (Daily)',
      phone: '+855 23 666 321',
      coordinates: LatLng(11.5619, 104.9126),
      highlights: ['Nursery Furniture', 'Express Pickup', 'Toy Studio'],
      imageUrl: 'https://images.unsplash.com/photo-1528698827591-e19ccd7bc23d?w=600&auto=format&fit=crop&q=60',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedStore = _branches.first;
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        final pos = await Geolocator.getLastKnownPosition();
        if (mounted && pos != null) {
          setState(() => _userPosition = pos);
        }
      }
    } catch (_) {}
  }

  double _calculateDistanceKm(LatLng pos) {
    if (_userPosition == null) return 2.5;
    const earthRadiusKm = 6371.0;
    final dLat = (pos.latitude - _userPosition!.latitude) * math.pi / 180;
    final dLon = (pos.longitude - _userPosition!.longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_userPosition!.latitude * math.pi / 180) *
            math.cos(pos.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  Set<Marker> _buildMarkers() {
    return _branches.map((store) {
      final isSelected = _selectedStore?.id == store.id;
      return Marker(
        markerId: MarkerId(store.id),
        position: store.coordinates,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isSelected ? BitmapDescriptor.hueRed : BitmapDescriptor.hueViolet,
        ),
        infoWindow: InfoWindow(
          title: store.name,
          snippet: store.district,
        ),
        onTap: () {
          setState(() => _selectedStore = store);
          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(target: store.coordinates, zoom: 15.5, tilt: 25),
            ),
          );
        },
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Outlets & Pickup'),
        actions: [
          // View Mode Switcher
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, icon: Icon(Icons.map_outlined, size: 18)),
                ButtonSegment(value: 1, icon: Icon(Icons.view_list_rounded, size: 18)),
              ],
              selected: {_selectedView},
              onSelectionChanged: (set) {
                HapticFeedback.selectionClick();
                setState(() => _selectedView = set.first);
              },
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
      body: _selectedView == 0 ? _buildMapView(isDark) : _buildListView(isDark),
    );
  }

  Widget _buildMapView(bool isDark) {
    return Stack(
      children: [
        // Google Map
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(11.5650, 104.9150),
            zoom: 13.0,
          ),
          markers: _buildMarkers(),
          myLocationEnabled: _userPosition != null,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          buildingsEnabled: true,
          onMapCreated: (controller) => _mapController = controller,
        ),

        // Top Filter Chips
        Positioned(
          top: 12,
          left: 16,
          right: 16,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: ['All', 'BKK1', 'Sen Sok', 'Toul Kork', '7 Makara'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(filter, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    selected: isSelected,
                    selectedColor: AppColors.accent,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                    onSelected: (val) {
                      setState(() => _selectedFilter = filter);
                      if (filter != 'All') {
                        final store = _branches.firstWhere((s) => s.district.contains(filter));
                        setState(() => _selectedStore = store);
                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: store.coordinates, zoom: 15.5, tilt: 20),
                          ),
                        );
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Bottom Selected Store Card Slider
        if (_selectedStore != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildStoreCard(_selectedStore!, isDark),
          ),
      ],
    );
  }

  Widget _buildStoreCard(StoreBranch store, bool isDark) {
    final dist = _calculateDistanceKm(store.coordinates);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(35),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  store.imageUrl,
                  width: 76,
                  height: 76,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 76,
                    height: 76,
                    color: AppColors.accent.withAlpha(20),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.accent, size: 36),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Colors.green, size: 10),
                              SizedBox(width: 3),
                              Text('Open Now', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '~${dist.toStringAsFixed(1)} km away',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      store.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.address,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Hours & Phone
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(store.openHours, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              const Spacer(),
              const Icon(Icons.phone_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(store.phone, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling ${store.name} (${store.phone})...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.call_rounded, size: 16),
                  label: const Text('Call Store', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).pop(store);
                  },
                  icon: const Icon(Icons.check_rounded, size: 16, color: Colors.white),
                  label: const Text('Select for Pickup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _branches.length,
      itemBuilder: (context, i) {
        final store = _branches[i];
        final dist = _calculateDistanceKm(store.coordinates);

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        store.imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 80,
                          height: 80,
                          color: AppColors.accent.withAlpha(20),
                          child: const Icon(Icons.storefront_rounded, color: AppColors.accent, size: 36),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withAlpha(30),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text('Open 8:30 AM – 9:30 PM', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const Spacer(),
                              Text(
                                '~${dist.toStringAsFixed(1)} km',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A73E8)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(store.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(store.address, style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: store.highlights.map((h) {
                    return Chip(
                      label: Text(h, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    );
                  }).toList(),
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedStore = store;
                          _selectedView = 0;
                        });
                        _mapController?.animateCamera(
                          CameraUpdate.newCameraPosition(
                            CameraPosition(target: store.coordinates, zoom: 16),
                          ),
                        );
                      },
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('View on Map'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(store),
                      icon: const Icon(Icons.shopping_bag_outlined, size: 16, color: Colors.white),
                      label: const Text('Choose Store', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
