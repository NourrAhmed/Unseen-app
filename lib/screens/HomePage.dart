import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  runApp(const FigmaToCodeApp());
}

class FigmaToCodeApp extends StatelessWidget {
  const FigmaToCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color.fromARGB(255, 18, 32, 47),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MapboxMap? _mapboxMap;

  double _latitude = 30.0444; // Default Cairo
  double _longitude = 31.2357;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// Get user location
  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint("Location services are disabled.");
        return;
      }

      geo.LocationPermission permission =
          await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) return;
      }
      if (permission == geo.LocationPermission.deniedForever) return;

      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      await _updateMapLocation();
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  /// Update map camera
  Future<void> _updateMapLocation() async {
    if (_mapboxMap == null) return;

    // Move camera
    _mapboxMap!.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(_longitude, _latitude)),
        zoom: 12.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Mapbox Map
          Positioned.fill(
            top: 44,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: MapWidget(
                key: const ValueKey("mapWidget"),
                cameraOptions: CameraOptions(
                  center: Point(coordinates: Position(_longitude, _latitude)),
                  zoom: 12.0,
                ),
                styleUri: MapboxStyles.MAPBOX_STREETS,
                onMapCreated: (mapboxMap) {
                  _mapboxMap = mapboxMap;
                },
              ),
            ),
          ),

          // Centered pin icon overlay (stays at user's location visually)
          Positioned.fill(
            top: 44,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 50,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  SizedBox(height: 50),
                ],
              ),
            ),
          ),

          // Top container
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Color(0xFF2E2A68), width: 3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "UnSeen",
                        style: TextStyle(
                          color: Color(0xFF2E2A68),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Discover hidden gems nearby",
                        style: TextStyle(
                          color: Color(0xFF635F5F),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Color(0xFF2E2A68), width: 3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.explore,
                        color: Color(0xFF2E2A68),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Refresh button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.small(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.refresh, color: Color(0xFF2E2A68)),
            ),
          ),
        ],
      ),
    );
  }
}
