import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Konum izni kontrolü ve isteme
  Future<bool> requestLocationPermission() async {
    // İzin durumunu kontrol et
    PermissionStatus permission = await Permission.location.status;

    if (permission.isGranted) {
      return true;
    }

    // İzin reddedilmişse tekrar iste
    if (permission.isDenied) {
      permission = await Permission.location.request();
      return permission.isGranted;
    }

    // Kalıcı olarak reddedilmişse ayarlara yönlendir
    if (permission.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }

    return false;
  }

  // Konum servisinin açık olup olmadığını kontrol et
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Mevcut konumu al
  Future<Position?> getCurrentLocation() async {
    try {
      // İzin kontrolü
      bool hasPermission = await requestLocationPermission();
      if (!hasPermission) {
        throw 'Konum izni verilmedi';
      }

      // Konum servisi kontrolü
      bool serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Konum servisi kapalı. Lütfen GPS\'i açın.';
      }

      // Konumu al
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return position;
    } catch (e) {
      throw 'Konum alınamadı: $e';
    }
  }

  // Konum değişikliklerini dinle (canlı takip için)
  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // 10 metre değişince güncelle
      ),
    );
  }

  // İki konum arasındaki mesafeyi hesapla (metre cinsinden)
  double calculateDistance(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  // Konumun metin formatı
  String formatLocation(Position position) {
    return 'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
  }
}