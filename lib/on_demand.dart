import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class OnDemandScreen extends StatefulWidget {
  const OnDemandScreen({super.key});

  @override
  State<OnDemandScreen> createState() => _OnDemandScreenState();
}

class _OnDemandScreenState extends State<OnDemandScreen> {
  String userLocation = '';
  String error = '';
  bool isProcessing = false;

  // Hardcoded list of hospitals near UNCW (this would be a mock example)
  final List<String> hospitals = [
    "UNCW Medical Center",
    "Wilmington Health - Hospital",
    "Novant Health Brunswick Medical Center",
    "NHRMC Emergency Department",
  ];

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allows content to extend behind the AppBar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Nearby Hospitals"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0, // Remove shadow
        titleTextStyle: const TextStyle(
          fontSize: 24,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 181, 184, 184),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/Login.jpg', // Make sure this image is in the correct path
            fit: BoxFit.cover,
          ),
          // Semi-transparent overlay to make the text readable
          Container(color: Colors.black.withAlpha(38)),
          // Main content (location and hospital list)
          isProcessing
              ? const Center(child: CircularProgressIndicator())
              : error.isNotEmpty
                  ? Center(child: Text(error, style: const TextStyle(color: Colors.white, fontSize: 16)))
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Hospitals near UNCW:",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Your current location: $userLocation',
                            style: const TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          const SizedBox(height: 20),
                          // Display hardcoded hospitals
                          ...hospitals.map((hospital) => Text(
                                hospital,
                                style: const TextStyle(fontSize: 16, color: Colors.white),
                              )),
                        ],
                      ),
                    ),
        ],
      ),
    );
  }

  Future<void> _getLocation() async {
    setState(() {
      isProcessing = true;
      error = '';
    });

    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        error = "Location services are disabled.";
      });
      setState(() {
        isProcessing = false;
      });
      return;
    }

    // Request location permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          error = 'Location permissions are denied. Enable them in settings.';
        });
        setState(() {
          isProcessing = false;
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        error = 'Location permissions are permanently denied.';
      });
      setState(() {
        isProcessing = false;
      });
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition();

    // Update the location string
    setState(() {
      userLocation = "${position.latitude}, ${position.longitude}";
      isProcessing = false;
    });
  }
}
