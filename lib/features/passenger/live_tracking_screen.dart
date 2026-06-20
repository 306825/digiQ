import 'package:digiQ/core/services/tracking_service.dart';
import 'package:digiQ/models/booking_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String tripId;

  /// Optional context shown in the bottom panel.
  final String? from;
  final String? to;
  final PassengerStatus? passengerStatus;

  const LiveTrackingScreen({
    super.key,
    required this.tripId,
    this.from,
    this.to,
    this.passengerStatus,
  });

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  final TrackingService _tracking = TrackingService();
  GoogleMapController? _mapController;
  LatLng? _driverPosition;
  Set<Marker> _markers = {};

  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  static const _defaultCenter = LatLng(-28.4793, 24.6727);

  // Map bottom padding so the driver marker stays above the bottom panel.
  static const double _panelHeight = 200.0;

  // Minimal map style: removes POI clutter and transit icons.
  static const _mapStyle = '''[
    {"featureType":"poi","stylers":[{"visibility":"off"}]},
    {"featureType":"transit","stylers":[{"visibility":"off"}]},
    {"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#f5f5f5"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#e0e0e0"}]},
    {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#dadada"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#c9e8f5"}]},
    {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f2f2f2"}]}
  ]''';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    );
    _connect();
  }

  Future<void> _connect() async {
    try {
      await _tracking.connect('https://api.digiqueue.co.za');
      _tracking.joinTrip(widget.tripId);
      _tracking.listenToLocation((lat, lng) {
        _onLocationUpdate(LatLng(lat, lng));
      });
    } catch (_) {
      // Connection failed — panel stays in "Locating driver" state;
      // user can pop and re-open to retry.
    }
  }

  void _onLocationUpdate(LatLng position) {
    if (!mounted) return;
    final isFirst = _driverPosition == null;
    setState(() {
      _driverPosition = position;
      _markers = {
        Marker(
          markerId: const MarkerId('driver'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          infoWindow: const InfoWindow(title: 'Your driver'),
        ),
      };
    });

    if (isFirst) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
    } else {
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 15),
        ),
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tracking.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  String get _statusText {
    if (_driverPosition == null) return 'Locating your driver…';
    switch (widget.passengerStatus) {
      case PassengerStatus.pickedUp:
        return 'On your way';
      case PassengerStatus.droppedOff:
        return 'You have arrived';
      default:
        return 'Driver is on the way';
    }
  }

  Color get _statusColor {
    if (_driverPosition == null) return const Color(0xFF9E9E9E);
    switch (widget.passengerStatus) {
      case PassengerStatus.pickedUp:
        return const Color(0xFF2E7D32);
      case PassengerStatus.droppedOff:
        return const Color(0xFF0D47A1);
      default:
        return const Color(0xFF1565C0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // ── Full-screen map ─────────────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _defaultCenter,
                zoom: 6,
              ),
              onMapCreated: (c) {
                _mapController = c;
                c.setMapStyle(_mapStyle);
              },
              markers: _markers,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              // Reserve space so driver marker is never hidden behind the panel.
              padding: const EdgeInsets.only(bottom: _panelHeight),
            ),
          ),

          // ── Floating back button ────────────────────────────────────────
          Positioned(
            top: topPad + 12,
            left: 16,
            child: _FloatingButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
          ),

          // ── Floating "center on driver" button ──────────────────────────
          if (_driverPosition != null)
            Positioned(
              top: topPad + 12,
              right: 16,
              child: _FloatingButton(
                icon: Icons.my_location,
                onTap: () {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_driverPosition!, 15),
                  );
                },
              ),
            ),

          // ── Bottom panel ────────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomPanel(
              driverFound: _driverPosition != null,
              statusText: _statusText,
              statusColor: _statusColor,
              pulseAnimation: _pulseAnimation,
              from: widget.from,
              to: widget.to,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Floating icon button ──────────────────────────────────────────────────────

class _FloatingButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF0D1B2E)),
      ),
    );
  }
}

// ── Bottom panel ──────────────────────────────────────────────────────────────

class _BottomPanel extends StatelessWidget {
  final bool driverFound;
  final String statusText;
  final Color statusColor;
  final Animation<double> pulseAnimation;
  final String? from;
  final String? to;

  const _BottomPanel({
    required this.driverFound,
    required this.statusText,
    required this.statusColor,
    required this.pulseAnimation,
    this.from,
    this.to,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Status row
              Row(
                children: [
                  AnimatedBuilder(
                    animation: pulseAnimation,
                    builder: (_, __) => Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(
                            0.35 + 0.65 * pulseAnimation.value),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  // Car icon chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.directions_car,
                            size: 14, color: Color(0xFF0D47A1)),
                        SizedBox(width: 5),
                        Text(
                          'Live',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Route (only shown when from/to are available)
              if (from != null || to != null) ...[
                const SizedBox(height: 18),
                const Divider(height: 1),
                const SizedBox(height: 16),
                _RouteIndicator(from: from, to: to),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Route indicator ───────────────────────────────────────────────────────────

class _RouteIndicator extends StatelessWidget {
  final String? from;
  final String? to;

  const _RouteIndicator({this.from, this.to});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dot–line–dot column
        Column(
          children: [
            const SizedBox(height: 2),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0D47A1), width: 2),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 2,
              height: 28,
              color: Colors.grey.shade300,
            ),
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF0D47A1),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Labels
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (from != null)
                Text(
                  from!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF56687A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 22),
              if (to != null)
                Text(
                  to!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1B2E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
