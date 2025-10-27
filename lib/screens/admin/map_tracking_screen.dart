import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:personel_takip/models/location_model.dart';
import 'package:personel_takip/services/location_tracking_service.dart';

class MapTrackingScreen extends StatefulWidget {
  const MapTrackingScreen({super.key});

  @override
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> {
  final LocationTrackingService _locationTrackingService = LocationTrackingService();
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LocationModel? _selectedLocation;

  // Türkiye merkezi koordinatları (başlangıç konumu)
  static const LatLng _defaultCenter = LatLng(39.9334, 32.8597);

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _updateMarkers(List<LocationModel> locations) {
    setState(() {
      _markers.clear();

      for (final location in locations) {
        // Sadece aktif ve güncel konumları göster
        if (location.isActive) {
          _markers.add(
            Marker(
              markerId: MarkerId(location.userId),
              position: LatLng(location.latitude, location.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                location.isRecent
                    ? BitmapDescriptor.hueGreen  // Güncel konum yeşil
                    : BitmapDescriptor.hueOrange, // Eski konum turuncu
              ),
              infoWindow: InfoWindow(
                title: location.userName,
                snippet: location.formattedTime,
              ),
              onTap: () {
                setState(() {
                  _selectedLocation = location;
                });
              },
            ),
          );
        }
      }
    });

    // İlk konum eklendiğinde haritayı oraya odakla
    if (locations.isNotEmpty && _mapController != null) {
      final firstLocation = locations.first;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(firstLocation.latitude, firstLocation.longitude),
          12,
        ),
      );
    }
  }

  void _zoomToUser(LocationModel location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(location.latitude, location.longitude),
        16,
      ),
    );
    setState(() {
      _selectedLocation = location;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personel Konum Takibi'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _selectedLocation = null;
              });
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: StreamBuilder<List<LocationModel>>(
        stream: _locationTrackingService.getAllActiveLocationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Konumlar yükleniyor...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Hata: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final locations = snapshot.data ?? [];

          // Marker'ları güncelle
          if (locations.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateMarkers(locations);
            });
          }

          return Stack(
            children: [
              // Harita
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _defaultCenter,
                  zoom: 6,
                ),
                markers: _markers,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapType: MapType.normal,
                onMapCreated: (controller) {
                  _mapController = controller;

                  // Konumlar varsa ilk konuma odakla
                  if (locations.isNotEmpty) {
                    final firstLocation = locations.first;
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(firstLocation.latitude, firstLocation.longitude),
                        12,
                      ),
                    );
                  }
                },
                onTap: (_) {
                  // Haritaya tıklanınca seçimi kaldır
                  setState(() {
                    _selectedLocation = null;
                  });
                },
              ),

              // Üst bilgi kartı
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.people,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${locations.length} Personel',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Aktif konum paylaşımı',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Yeşil ve turuncu nokta açıklaması
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Güncel', style: TextStyle(fontSize: 11)),
                            const SizedBox(width: 8),
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('Eski', style: TextStyle(fontSize: 11)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Seçili kullanıcı detayları
              if (_selectedLocation != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  _selectedLocation!.userName.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedLocation!.userName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      _selectedLocation!.formattedTime,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _selectedLocation = null;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Colors.grey.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _selectedLocation!.formattedLocation,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                _selectedLocation!.isRecent
                                    ? Icons.circle
                                    : Icons.warning_amber_rounded,
                                size: 16,
                                color: _selectedLocation!.isRecent
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedLocation!.isRecent
                                    ? 'Konum güncel'
                                    : 'Konum güncel değil',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedLocation!.isRecent
                                      ? Colors.green
                                      : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Personel listesi butonu
              if (locations.isNotEmpty)
                Positioned(
                  bottom: _selectedLocation != null ? 200 : 16,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'listButton',
                    onPressed: () {
                      _showLocationsList(locations);
                    },
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.list,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),

              // Konumlar boşsa bilgilendirme
              if (locations.isEmpty)
                Center(
                  child: Card(
                    margin: const EdgeInsets.all(24),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_off,
                            size: 60,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz konum paylaşan personel yok',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Personel konum paylaşımını açtığında burada görünecek',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showLocationsList(List<LocationModel> locations) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Personel Listesi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: location.isRecent
                            ? Colors.green.shade100
                            : Colors.orange.shade100,
                        child: Text(
                          location.userName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: location.isRecent
                                ? Colors.green.shade700
                                : Colors.orange.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        location.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(location.formattedTime),
                      trailing: Icon(
                        Icons.location_on,
                        color: location.isRecent ? Colors.green : Colors.orange,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _zoomToUser(location);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
