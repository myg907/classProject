import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class OnDemandScreen extends StatefulWidget {
  const OnDemandScreen({super.key});

  @override
  State<OnDemandScreen> createState() => _OnDemandScreenState();
}

class _OnDemandScreenState extends State<OnDemandScreen> {
  GoogleMapController? _mapController;
  CameraPosition? _initialPosition;
  List<Position> positions = [];
  String? error;
  bool isProcessing = false;

  Set<Marker> _markers = {}; // for hospital markers

  final String _googleApiKey = "AIzaSyA-JMFRJFPrFKl6KmbpgMnuQbpVafKaPkE"; 

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "On Demand Location",
          style: TextStyle(
            fontSize: 22,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Color.fromARGB(255, 181, 184, 184),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/Login.jpg', fit: BoxFit.cover),
          Container(color: Colors.black.withAlpha(38)),
          if (error != null)
            Center(child: Text(error!, style: TextStyle(color: Colors.red)))
          else if (_initialPosition == null)
            const Center(child: CircularProgressIndicator()) // Loading
          else
            GoogleMap(
              initialCameraPosition: _initialPosition!,
              myLocationEnabled: true,
              markers: _markers, // show hospital markers
              onMapCreated: (controller) => _mapController = controller,
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              setState(() => positions.clear());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: const Text(
              "Clear",
              style: TextStyle(fontFamily: 'Poppins'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _getLocation() async {
    try {
      error = null;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          error = "Location services are disabled.";
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            error = 'Location permissions are denied. Enable them in settings.';
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          error = 'Location permissions are permanently denied.';
        });
        return;
      }

      // Once permission is granted, get the current position
      setState(() => isProcessing = true);
      Position pos = await Geolocator.getCurrentPosition();
      positions.add(pos);
      _initialPosition = CameraPosition(
        target: LatLng(pos.latitude, pos.longitude),
        zoom: 14.0,
      );

      await _getNearbyHospitals(pos.latitude, pos.longitude); // Search for hospitals

      setState(() {
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        error = "An error occurred: $e";
      });
    }
  }

  Future<void> _getNearbyHospitals(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=$lat,$lng'
        '&radius=5000' // 5 km radius
        '&type=hospital'
        '&key=$_googleApiKey',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['results'] != null) {
          Set<Marker> newMarkers = {};

          for (var hospital in data['results']) {
            final hospitalName = hospital['name'];
            final hospitalLat = hospital['geometry']['location']['lat'];
            final hospitalLng = hospital['geometry']['location']['lng'];

            newMarkers.add(
              Marker(
                markerId: MarkerId(hospitalName),
                position: LatLng(hospitalLat, hospitalLng),
                infoWindow: InfoWindow(title: hospitalName),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
            );
          }

          setState(() {
            _markers = newMarkers;
          });
        }
      } else {
        print('Failed to load nearby hospitals');
      }
    } catch (e) {
      print('Error fetching nearby hospitals: $e');
    }
  }
}
