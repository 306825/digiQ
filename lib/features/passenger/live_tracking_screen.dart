import 'package:digiQ/core/services/tracking_service.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LiveTrackingScreen extends StatefulWidget {
  /// The trip ID to subscribe to — passed in from BookingDetailsScreen.
  final String tripId;

  const LiveTrackingScreen({super.key, required this.tripId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final TrackingService _tracking = TrackingService();

  GoogleMapController? _mapController;
  LatLng? _driverPosition;
  Set<Marker> _markers = {};

  // South Africa center — shown before the first location arrives
  static const _defaultCenter = LatLng(-28.4793, 24.6727);

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    await _tracking.connect(
      'https://nonembryonal-terese-unveritable.ngrok-free.dev',
    );

    _tracking.joinTrip(widget.tripId);

    _tracking.listenToLocation((lat, lng) {
      _onLocationUpdate(LatLng(lat, lng));
    });
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Driver'),
        ),
      };
    });

    if (isFirst) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15),
      );
    } else {
      _mapController?.animateCamera(CameraUpdate.newLatLng(position));
    }
  }

  @override
  void dispose() {
    _tracking.disconnect();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Tracking'),
        centerTitle: true,
        elevation: 0.5,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _defaultCenter,
              zoom: 6,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: _markers,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          // Waiting banner — hidden once we have a position
          if (_driverPosition == null)
            Positioned(
              bottom: 32,
              left: 24,
              right: 24,
              child: _WaitingBanner(),
            ),
        ],
      ),
    );
  }
}

class _WaitingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text(
            'Waiting for driver location…',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
