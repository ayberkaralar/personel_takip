import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final String userName;
  final DateTime checkInTime;
  final DateTime? checkOutTime;
  final GeoPoint checkInLocation;
  final GeoPoint? checkOutLocation;
  final String date; // YYYY-MM-DD formatında
  final String? notes;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.checkInTime,
    this.checkOutTime,
    required this.checkInLocation,
    this.checkOutLocation,
    required this.date,
    this.notes,
  });

  // Firestore'dan veri çekerken
  factory AttendanceModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return AttendanceModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      checkInTime: (data['checkInTime'] as Timestamp).toDate(),
      checkOutTime: data['checkOutTime'] != null 
          ? (data['checkOutTime'] as Timestamp).toDate() 
          : null,
      checkInLocation: data['checkInLocation'] as GeoPoint,
      checkOutLocation: data['checkOutLocation'] != null 
          ? data['checkOutLocation'] as GeoPoint 
          : null,
      date: data['date'] ?? '',
      notes: data['notes'],
    );
  }

  // Firestore'a veri kaydederken
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'checkInTime': Timestamp.fromDate(checkInTime),
      'checkOutTime': checkOutTime != null 
          ? Timestamp.fromDate(checkOutTime!) 
          : null,
      'checkInLocation': checkInLocation,
      'checkOutLocation': checkOutLocation,
      'date': date,
      'notes': notes,
    };
  }

  // Çalışma süresini hesapla (saat ve dakika)
  Duration? get workDuration {
    if (checkOutTime == null) return null;
    return checkOutTime!.difference(checkInTime);
  }

  // Çalışma süresini metin olarak formatla
  String get formattedWorkDuration {
    if (workDuration == null) return 'Devam ediyor...';
    
    int hours = workDuration!.inHours;
    int minutes = workDuration!.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    } else {
      return '${minutes}dk';
    }
  }

  // Check-out yapılmış mı?
  bool get isCheckedOut => checkOutTime != null;

  // Bugün mü?
  bool get isToday {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return date == today;
  }

  // Copy with (güncelleme için)
  AttendanceModel copyWith({
    String? id,
    String? userId,
    String? userName,
    DateTime? checkInTime,
    DateTime? checkOutTime,
    GeoPoint? checkInLocation,
    GeoPoint? checkOutLocation,
    String? date,
    String? notes,
  }) {
    return AttendanceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
      checkInLocation: checkInLocation ?? this.checkInLocation,
      checkOutLocation: checkOutLocation ?? this.checkOutLocation,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}