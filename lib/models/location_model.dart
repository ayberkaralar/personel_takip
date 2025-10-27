import 'package:cloud_firestore/cloud_firestore.dart';

class LocationModel {
  final String userId;
  final String userName;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final bool isActive;

  LocationModel({
    required this.userId,
    required this.userName,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.isActive = true,
  });

  // Firestore'dan veri çekerken kullanılır
  factory LocationModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return LocationModel(
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  // Firestore'a veri kaydederken kullanılır
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': Timestamp.fromDate(timestamp),
      'isActive': isActive,
    };
  }

  // Konum bilgisinin metin formatı
  String get formattedLocation {
    return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
  }

  // Son güncelleme zamanının formatlanmış hali
  String get formattedTime {
    final now = DateTime.now();
    final diff = now.difference(timestamp);

    if (diff.inMinutes < 1) {
      return 'Az önce';
    } else if (diff.inHours < 1) {
      return '${diff.inMinutes} dakika önce';
    } else if (diff.inDays < 1) {
      return '${diff.inHours} saat önce';
    } else {
      return '${diff.inDays} gün önce';
    }
  }

  // Konumun güncel olup olmadığını kontrol et (5 dakikadan eski değilse güncel)
  bool get isRecent {
    final diff = DateTime.now().difference(timestamp);
    return diff.inMinutes < 5;
  }

  LocationModel copyWith({
    String? userId,
    String? userName,
    double? latitude,
    double? longitude,
    DateTime? timestamp,
    bool? isActive,
  }) {
    return LocationModel(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timestamp: timestamp ?? this.timestamp,
      isActive: isActive ?? this.isActive,
    );
  }
}
