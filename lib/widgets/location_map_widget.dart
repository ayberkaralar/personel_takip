import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:personel_takip/services/location_services.dart';

class LocationMapWidget extends StatefulWidget {
  const LocationMapWidget({super.key});

  @override
  State<LocationMapWidget> createState() => _LocationMapWidgetState();
}

class _LocationMapWidgetState extends State<LocationMapWidget> {
  final LocationService _locationService = LocationService();
  GoogleMapController? _mapController;
  Position? _currentPosition;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Marker'lar
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      Position? position = await _locationService.getCurrentLocation();
      
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _isLoading = false;
          
          // Kullanıcı konumuna marker ekle
          _markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: LatLng(position.latitude, position.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
              infoWindow: InfoWindow(
                title: 'Konumunuz',
                snippet: _locationService.formatLocation(position),
              ),
            ),
          );
        });

        // Haritayı konuma odakla
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            16,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 300,
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Konum alınıyor...'),
                    ],
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.location_off,
                              size: 60,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tekrar Dene'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _currentPosition == null
                      ? const Center(child: Text('Konum bulunamadı'))
                      : Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  _currentPosition!.latitude,
                                  _currentPosition!.longitude,
                                ),
                                zoom: 16,
                              ),
                              markers: _markers,
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapType: MapType.normal,
                              onMapCreated: (controller) {
                                _mapController = controller;
                              },
                            ),
                            
                            // Yenile butonu
                            Positioned(
                              top: 16,
                              right: 16,
                              child: FloatingActionButton.small(
                                onPressed: _getCurrentLocation,
                                backgroundColor: Colors.white,
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            
                            // Konum bilgisi
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _locationService.formatLocation(_currentPosition!),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}