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
  CameraPosition? _initialPosition;  // <--- NEW
  List<Position> positions = [];
  String? error;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _getLocation(); // Get location right when screen opens
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
          Container(color: Colors.black.withAlpha(50)),
          if (_initialPosition == null)
            const Center(child: CircularProgressIndicator()) // Loading until location found
          else
            GoogleMap(
              initialCameraPosition: _initialPosition!,
              myLocationEnabled: true,
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
    error = null;

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      error = "Location services are disabled.";
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        error = 'Location permissions are denied. Enable them in settings.';
      }
    }
    if (permission == LocationPermission.deniedForever) {
      error = 'Location permissions are permanently denied.';
    }

    if (error == null) {
      setState(() => isProcessing = true);
      Position pos = await Geolocator.getCurrentPosition();
      positions.add(pos);
      _initialPosition = CameraPosition(
        target: LatLng(pos.latitude, pos.longitude),
        zoom: 14.0,
      );
      isProcessing = false;
    }

    setState(() {});
  }
}
