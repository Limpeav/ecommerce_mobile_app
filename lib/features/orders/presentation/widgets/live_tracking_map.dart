import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/constants/app_colors.dart';

class LiveTrackingMap extends StatefulWidget {
  final String orderId;
  final String destinationAddress;
  final LatLng? destinationLatLng;

  const LiveTrackingMap({
    super.key,
    required this.orderId,
    required this.destinationAddress,
    this.destinationLatLng,
  });

  @override
  State<LiveTrackingMap> createState() => _LiveTrackingMapState();
}

class _LiveTrackingMapState extends State<LiveTrackingMap> {
  GoogleMapController? _mapController;
  Timer? _driverMovementTimer;

  // Origin: Cherish Central Warehouse (Samdach Sothearos, BKK1)
  static const LatLng _storeLocation = LatLng(11.5520, 104.9255);
  // Default Customer Destination (or passed in)
  late LatLng _destinationLocation;

  // Simulated live moving driver coordinates
  late LatLng _driverLocation;
  double _routeProgress = 0.65; // 65% towards destination

  final List<LatLng> _routePoints = [
    const LatLng(11.5520, 104.9255), // Store origin
    const LatLng(11.5540, 104.9265),
    const LatLng(11.5564, 104.9282), // Independence Monument
    const LatLng(11.5590, 104.9290),
    const LatLng(11.5620, 104.9280),
    const LatLng(11.5645, 104.9260),
    const LatLng(11.5670, 104.9230),
    const LatLng(11.5695, 104.9200), // Near customer
  ];

  @override
  void initState() {
    super.initState();
    _destinationLocation = widget.destinationLatLng ?? const LatLng(11.5695, 104.9200);

    // Initial driver position along route
    _updateDriverPosition();

    // Subtle simulated courier driver movement
    _driverMovementTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) return;
      setState(() {
        _routeProgress += 0.04;
        if (_routeProgress > 0.95) _routeProgress = 0.50; // loop simulation
        _updateDriverPosition();
      });
    });
  }

  void _updateDriverPosition() {
    final targetIndex = (_routePoints.length - 1) * _routeProgress;
    final lower = targetIndex.floor();
    final upper = targetIndex.ceil();
    final fraction = targetIndex - lower;

    if (lower == upper || upper >= _routePoints.length) {
      _driverLocation = _routePoints[lower.clamp(0, _routePoints.length - 1)];
    } else {
      final p1 = _routePoints[lower];
      final p2 = _routePoints[upper];
      _driverLocation = LatLng(
        p1.latitude + (p2.latitude - p1.latitude) * fraction,
        p1.longitude + (p2.longitude - p1.longitude) * fraction,
      );
    }
  }

  @override
  void dispose() {
    _driverMovementTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    return {
      // Store Origin Marker
      const Marker(
        markerId: MarkerId('store_origin'),
        position: _storeLocation,
        infoWindow: InfoWindow(
          title: 'Cherish Fulfillment Center',
          snippet: 'Dispatched from Store #1',
        ),
      ),
      // Destination Marker
      Marker(
        markerId: const MarkerId('customer_dest'),
        position: _destinationLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Your Delivery Address',
          snippet: widget.destinationAddress,
        ),
      ),
      // Live Courier Driver Marker
      Marker(
        markerId: const MarkerId('courier_driver'),
        position: _driverLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(
          title: '🛵 Sokha Meng (Courier)',
          snippet: 'Express Motorbike Delivery',
        ),
        zIndexInt: 10,
      ),
    };
  }

  Set<Polyline> _buildPolylines() {
    return {
      Polyline(
        polylineId: const PolylineId('delivery_route'),
        points: _routePoints,
        color: AppColors.accent,
        width: 5,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  void _fitRouteBounds() {
    if (_mapController == null) return;
    HapticFeedback.selectionClick();
    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            _storeLocation.latitude < _destinationLocation.latitude
                ? _storeLocation.latitude - 0.005
                : _destinationLocation.latitude - 0.005,
            _storeLocation.longitude < _destinationLocation.longitude
                ? _storeLocation.longitude - 0.005
                : _destinationLocation.longitude - 0.005,
          ),
          northeast: LatLng(
            _storeLocation.latitude > _destinationLocation.latitude
                ? _storeLocation.latitude + 0.005
                : _destinationLocation.latitude + 0.005,
            _storeLocation.longitude > _destinationLocation.longitude
                ? _storeLocation.longitude + 0.005
                : _destinationLocation.longitude + 0.005,
          ),
        ),
        50,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 320,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Live Interactive Google Map
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: LatLng(11.5600, 104.9260),
                zoom: 14.5,
              ),
              markers: _buildMarkers(),
              polylines: _buildPolylines(),
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              buildingsEnabled: true,
              trafficEnabled: true,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),

            // Top Status Overlay Pill
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF202124).withAlpha(230) : Colors.white.withAlpha(240),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Live Courier Tracking: On The Way',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ETA: 15 mins',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Re-center Route Button (Right side)
            Positioned(
              right: 12,
              bottom: 90,
              child: Material(
                color: isDark ? const Color(0xFF282828) : Colors.white,
                shape: const CircleBorder(),
                elevation: 3,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _fitRouteBounds,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.center_focus_strong_rounded, size: 20, color: Color(0xFF1A73E8)),
                  ),
                ),
              ),
            ),

            // Bottom Driver Quick Info Card
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.accent.withAlpha(25),
                      child: const Icon(Icons.two_wheeler_rounded, size: 20, color: AppColors.accent),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Sokha Meng (Driver)',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                              SizedBox(width: 2),
                              Text('4.9 • Honda Wave (1-KG 8942)', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 20),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Calling courier driver Sokha Meng (+855 12 345 678)...'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
