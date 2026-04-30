import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationPickerScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const LocationPickerScreen({
    Key? key,
    this.initialLatitude = 30.0444, 
    this.initialLongitude = 31.2357,
  }) : super(key: key);

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;
  double _selectedLatitude = 30.0444;
  double _selectedLongitude = 31.2357;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _selectedLatitude = widget.initialLatitude;
    _selectedLongitude = widget.initialLongitude;
    _getCurrentLocation();
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      
      const accessToken = String.fromEnvironment('MAPBOX_TOKEN');
      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?access_token=$accessToken&limit=5',
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final features = data['features'] as List;

        setState(() {
          _searchResults = features.map((feature) {
            final coords = feature['center'] as List;
            return {
              'name': feature['place_name'] as String,
              'longitude': coords[0] as double,
              'latitude': coords[1] as double,
            };
          }).toList();
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching location: $e');
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    setState(() {
      _selectedLatitude = result['latitude'];
      _selectedLongitude = result['longitude'];
      _searchResults = [];
      _searchController.clear();
    });

    // Update map camera
    if (_mapboxMap != null) {
      _mapboxMap!.setCamera(
        CameraOptions(
          center: Point(coordinates: Position(_selectedLongitude, _selectedLatitude)),
          zoom: 15.0,
        ),
      );
      _updateMarker();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      geo.LocationPermission permission = await geo.Geolocator.checkPermission();
      if (permission == geo.LocationPermission.denied) {
        permission = await geo.Geolocator.requestPermission();
        if (permission == geo.LocationPermission.denied) {
          return;
        }
      }

      if (permission == geo.LocationPermission.deniedForever) {
        return;
      }

      geo.Position position = await geo.Geolocator.getCurrentPosition(
        desiredAccuracy: geo.LocationAccuracy.high,
      );

      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
      });

      // Update map to current location
      if (_mapboxMap != null) {
        _mapboxMap!.setCamera(
          CameraOptions(
            center: Point(coordinates: Position(_selectedLongitude, _selectedLatitude)),
            zoom: 15.0,
          ),
        );
        Future.delayed(const Duration(milliseconds: 300), () {
          _updateLocationFromCamera();
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _onMapCreated(MapboxMap mapboxMap) {
    _mapboxMap = mapboxMap;

    // Set initial camera position
    mapboxMap.setCamera(
      CameraOptions(
        center: Point(coordinates: Position(_selectedLongitude, _selectedLatitude)),
        zoom: 15.0,
      ),
    );

    // Initialize point annotation manager
    mapboxMap.annotations.createPointAnnotationManager().then((manager) {
      setState(() {
        _pointAnnotationManager = manager;
      });
      _updateMarker();
      
      // Start listening to camera changes
      _startCameraListener();
    });
  }

  void _startCameraListener() {
    // Periodically update location from camera center when map is dragged
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (_mapboxMap != null && mounted) {
        await _updateLocationFromCamera();
        // Continue listening
        if (mounted) {
          _startCameraListener();
        }
      }
    });
  }

  Future<void> _updateLocationFromCamera() async {
    if (_mapboxMap == null) return;
    
    try {
      final cameraState = await _mapboxMap!.getCameraState();
      final center = cameraState.center;
      // Extract coordinates from Point
      // Position is a list [longitude, latitude]
      final coords = center.coordinates;
      if (coords is List && coords.length >= 2) {
        setState(() {
          _selectedLongitude = (coords[0] as num).toDouble();
          _selectedLatitude = (coords[1] as num).toDouble();
        });
        _updateMarker();
      }
    } catch (e) {
      debugPrint('Error getting camera state: $e');
    }
  }

  Future<void> _updateMarker() async {
    if (_pointAnnotationManager == null) return;

    // Remove all existing markers
    await _pointAnnotationManager!.deleteAll();

    await _pointAnnotationManager!.create(
      PointAnnotationOptions(
        geometry: Point(coordinates: Position(_selectedLongitude, _selectedLatitude)),
        textField: "📍",
        textSize: 30.0,
        textColor: Colors.red.value,
        textOffset: [0.0, -1.0],
      ),
    );
  }


  void _confirmLocation() {
    Navigator.pop(context, {
      'latitude': _selectedLatitude,
      'longitude': _selectedLongitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: const Color(0xFF2E2952),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          
          GestureDetector(
            onTapDown: (details) {
              // Convert tap position to coordinates
              
              _updateLocationFromCamera();
            },
            child: MapWidget(
              key: const ValueKey("locationPickerMap"),
              onMapCreated: _onMapCreated,
              cameraOptions: CameraOptions(
                center: Point(coordinates: Position(_selectedLongitude, _selectedLatitude)),
                zoom: 15.0,
              ),
              styleUri: MapboxStyles.MAPBOX_STREETS,
            ),
          ),

          // Centered pin icon overlay that stays in the middle of the screen
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
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
                // Offset to account for pin bottom point
                const SizedBox(height: 50),
              ],
            ),
          ),

          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search location...',
                      prefixIcon: const Icon(Icons.search, color: Color(0xFF2E2952)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchResults = [];
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      _searchLocation(value);
                    },
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final result = _searchResults[index];
                        return ListTile(
                          leading: const Icon(Icons.location_on, color: Color(0xFF2E2952)),
                          title: Text(
                            result['name'],
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () => _selectSearchResult(result),
                        );
                      },
                    ),
                  ),
                if (_isSearching)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),

          // Selected coordinates display
          Positioned(
            bottom: 100,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location:',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_selectedLatitude.toStringAsFixed(6)}, ${_selectedLongitude.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF2E2952),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Confirm button
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: ElevatedButton(
              onPressed: _confirmLocation,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E2952),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Confirm Location',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // My Location button
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(
                Icons.my_location,
                color: Color(0xFF2E2952),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
