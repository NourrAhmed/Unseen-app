import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? address;
  final String title;

  const MapView({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.title,
  }) : super(key: key);

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  MapboxMap? _mapboxMap;
  PointAnnotationManager? _pointAnnotationManager;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          // Address Info Card
          if (widget.address != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: const Color(0xC9D8D3E7),
              child: Row(
                children: [
                  const Icon(Icons.place, color: Color(0xFF2E2A68)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.address!,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Map with Pin Overlay - EXACTLY like LocationPickerScreen
          Expanded(
            child: Stack(
              children: [
                // Mapbox Map
                MapWidget(
                  key: const ValueKey("mapWidget"),
                  cameraOptions: CameraOptions(
                    center: Point(
                      coordinates: Position(widget.longitude, widget.latitude),
                    ),
                    zoom: 14.0,
                  ),
                  styleUri: MapboxStyles.OUTDOORS,
                  textureView: true,
                  onMapCreated: _onMapCreated,
                ),
                
                // Centered pin icon overlay - EXACT copy from LocationPickerScreen
                Center(
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
                      // Offset to account for pin bottom point
                      SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onMapCreated(MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;
    
    // Create annotation manager
    _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    
    // Add marker with emoji - same as your original code
    await _pointAnnotationManager?.create(
      PointAnnotationOptions(
        geometry: Point(
          coordinates: Position(widget.longitude, widget.latitude),
        ),
        textField: "📍",
        textSize: 40.0,
        textColor: Colors.red.value,
        textOffset: [0.0, -2.0],
      ),
    );
  }
}