import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final GoogleMapController _mapController;
  final List<LatLng> _polylinePoints = [];
  Marker? _userMarker;
  Polyline _userPolyline = Polyline(
    polylineId: PolylineId('route'),
    color: Colors.blue,
    width: 5,
    points: [],
  );

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _onLocationPermissionAndServiceEnabled(
    VoidCallback onSuccess,
  ) async {
    // TODO: Check if the app has permission
    bool isPermissionEnabled = await _isLocationPermissionEnable();
    if (isPermissionEnabled) {
      // TODO: Check if the GPS service On/Off
      bool isGpsServiceEnabled = await Location.instance.serviceEnabled();
      if (isGpsServiceEnabled) {
        // TODO: what user want
        onSuccess();
      } else {
        // TODO: If not, then move to gps service settings
        Location.instance.requestService();
      }
    } else {
      // TODO: If not, then request the permission
      bool isPermissionGranted = await _requestPermission();
      if (isPermissionGranted) {
        _listenCurrentLocation();
      }
    }
  }

  Future<void> _listenCurrentLocation() async {
    _onLocationPermissionAndServiceEnabled(() {
      Location.instance.changeSettings(
        accuracy: LocationAccuracy.high,
        interval: 10000,
        distanceFilter: 3,
      );
      Location.instance.onLocationChanged.listen((LocationData location) {
        if (location.latitude == null || location.longitude == null) return;

        final newLatLng = LatLng(location.latitude!, location.longitude!);
        if (_polylinePoints.isNotEmpty &&
            _polylinePoints.last.latitude == newLatLng.latitude &&
            _polylinePoints.last.longitude == newLatLng.longitude) {
          // Same point — skip update
          return;
        }
        setState(() {
          _polylinePoints.add(newLatLng);
          _userPolyline = _userPolyline.copyWith(pointsParam: _polylinePoints);

          _userMarker = Marker(
            markerId: MarkerId('user_marker'),
            position: newLatLng,
            infoWindow: InfoWindow(
              title: 'My current location',
              snippet:
                  'Lat: ${newLatLng.latitude.toStringAsFixed(5)}, Lng: ${newLatLng.longitude.toStringAsFixed(5)}',
            ),
          );
        });

        _mapController.animateCamera(CameraUpdate.newLatLng(newLatLng));
      });
    });
  }

  Future<bool> _isLocationPermissionEnable() async {
    PermissionStatus locationPermission =
        await Location.instance.hasPermission();
    if (locationPermission == PermissionStatus.granted ||
        locationPermission == PermissionStatus.grantedLimited) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> _requestPermission() async {
    PermissionStatus locationPermission =
        await Location.instance.requestPermission();
    if (locationPermission == PermissionStatus.granted ||
        locationPermission == PermissionStatus.grantedLimited) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Map')),
      body: GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
          _listenCurrentLocation(); // Start listening after map is ready
        },
        initialCameraPosition: CameraPosition(target: LatLng(0, 0), zoom: 18),
        markers: _userMarker != null ? {_userMarker!} : {},
        polylines: {_userPolyline},
        myLocationEnabled: true,
      ),
    );
  }
}
