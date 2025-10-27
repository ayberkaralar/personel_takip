import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/location_model.dart';
import 'location_services.dart';

class LocationTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocationService _locationService = LocationService();

  StreamSubscription<Position>? _locationSubscription;

  // Collection adı
  static const String _collectionName = 'user_locations';

  // Kullanıcının konumunu güncelle
  Future<void> updateUserLocation({
    required String userId,
    required String userName,
    required Position position,
  }) async {
    try {
      final locationData = LocationModel(
        userId: userId,
        userName: userName,
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        isActive: true,
      );

      // Kullanıcının konum dokümanını güncelle (yoksa oluştur)
      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .set(locationData.toMap());
    } catch (e) {
      throw 'Konum güncellenemedi: $e';
    }
  }

  // Kullanıcının mevcut konumunu al ve güncelle
  Future<void> updateCurrentLocation({
    required String userId,
    required String userName,
  }) async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (position != null) {
        await updateUserLocation(
          userId: userId,
          userName: userName,
          position: position,
        );
      }
    } catch (e) {
      throw 'Konum güncellenemedi: $e';
    }
  }

  // Konum paylaşımını başlat (periyodik güncelleme)
  void startLocationSharing({
    required String userId,
    required String userName,
  }) {
    // Önceki subscription varsa iptal et
    stopLocationSharing();

    // Konum akışını dinle
    _locationSubscription = _locationService.getLocationStream().listen(
      (position) {
        updateUserLocation(
          userId: userId,
          userName: userName,
          position: position,
        );
      },
      onError: (error) {
        print('Konum paylaşım hatası: $error');
      },
    );
  }

  // Konum paylaşımını durdur
  void stopLocationSharing() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
  }

  // Kullanıcının konum paylaşımını devre dışı bırak
  Future<void> disableLocationSharing(String userId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .update({'isActive': false});
    } catch (e) {
      print('Konum paylaşımı kapatılamadı: $e');
    }
  }

  // Kullanıcının konum paylaşımını aktif et
  Future<void> enableLocationSharing(String userId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .update({'isActive': true});
    } catch (e) {
      print('Konum paylaşımı açılamadı: $e');
    }
  }

  // Tek bir kullanıcının konumunu getir (stream)
  Stream<LocationModel?> getUserLocationStream(String userId) {
    return _firestore
        .collection(_collectionName)
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return LocationModel.fromFirestore(snapshot);
    });
  }

  // Tek bir kullanıcının konumunu getir (future)
  Future<LocationModel?> getUserLocation(String userId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(userId)
          .get();

      if (!doc.exists) return null;
      return LocationModel.fromFirestore(doc);
    } catch (e) {
      print('Kullanıcı konumu alınamadı: $e');
      return null;
    }
  }

  // Tüm aktif kullanıcıların konumlarını getir (stream)
  Stream<List<LocationModel>> getAllActiveLocationsStream() {
    return _firestore
        .collection(_collectionName)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    });
  }

  // Tüm aktif kullanıcıların konumlarını getir (future)
  Future<List<LocationModel>> getAllActiveLocations() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Konumlar alınamadı: $e');
      return [];
    }
  }

  // Güncel konumları getir (son 5 dakika içinde güncellenenler)
  Future<List<LocationModel>> getRecentLocations() async {
    try {
      final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('isActive', isEqualTo: true)
          .where('timestamp', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
          .get();

      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Güncel konumlar alınamadı: $e');
      return [];
    }
  }

  // Güncel konumları getir (stream)
  Stream<List<LocationModel>> getRecentLocationsStream() {
    final fiveMinutesAgo = DateTime.now().subtract(const Duration(minutes: 5));

    return _firestore
        .collection(_collectionName)
        .where('isActive', isEqualTo: true)
        .where('timestamp', isGreaterThan: Timestamp.fromDate(fiveMinutesAgo))
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => LocationModel.fromFirestore(doc))
          .toList();
    });
  }

  // Kullanıcının konum dokümanını sil
  Future<void> deleteUserLocation(String userId) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .delete();
    } catch (e) {
      print('Konum silinemedi: $e');
    }
  }

  // Cleanup - kaynakları temizle
  void dispose() {
    stopLocationSharing();
  }
}
