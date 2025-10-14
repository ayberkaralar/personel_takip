import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/attendance_model.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _attendancesCollection => _db.collection('attendances');

  // Bugünün tarihini formatla (YYYY-MM-DD)
  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // Check-in yap
  Future<String> checkIn({
    required String userId,
    required String userName,
    required Position position,
    String? notes,
  }) async {
    try {
      final today = _getTodayDate();
      
      // Bugün zaten check-in yapılmış mı kontrol et
      final existingAttendance = await getTodayAttendance(userId);
      if (existingAttendance != null) {
        throw 'Bugün zaten giriş yaptınız!';
      }

      // Yeni attendance kaydı oluştur
      DocumentReference docRef = await _attendancesCollection.add({
        'userId': userId,
        'userName': userName,
        'checkInTime': FieldValue.serverTimestamp(),
        'checkOutTime': null,
        'checkInLocation': GeoPoint(position.latitude, position.longitude),
        'checkOutLocation': null,
        'date': today,
        'notes': notes,
      });

      return docRef.id;
    } catch (e) {
      throw 'Check-in yapılamadı: $e';
    }
  }

  // Check-out yap
  Future<void> checkOut({
    required String userId,
    required Position position, required String attendanceId,
  }) async {
    try {
      // Bugünkü attendance kaydını bul
      final attendance = await getTodayAttendance(userId);
      
      if (attendance == null) {
        throw 'Önce giriş yapmalısınız!';
      }

      if (attendance.isCheckedOut) {
        throw 'Bugün zaten çıkış yaptınız!';
      }

      // Check-out bilgilerini güncelle
      await _attendancesCollection.doc(attendance.id).update({
        'checkOutTime': FieldValue.serverTimestamp(),
        'checkOutLocation': GeoPoint(position.latitude, position.longitude),
      });
    } catch (e) {
      throw 'Check-out yapılamadı: $e';
    }
  }

  // Bugünkü attendance kaydını getir
  Future<AttendanceModel?> getTodayAttendance(String userId) async {
    try {
      final today = _getTodayDate();
      
      QuerySnapshot snapshot = await _attendancesCollection
          .where('userId', isEqualTo: userId)
          .where('date', isEqualTo: today)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return AttendanceModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      throw 'Bugünkü kayıt alınamadı: $e';
    }
  }

  // Bugünkü attendance'ı stream olarak dinle
  Stream<AttendanceModel?> todayAttendanceStream(String userId) {
    final today = _getTodayDate();
    
    return _attendancesCollection
        .where('userId', isEqualTo: userId)
        .where('date', isEqualTo: today)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return AttendanceModel.fromFirestore(snapshot.docs.first);
    });
  }

  // Kullanıcının tüm mesai kayıtlarını getir
  Future<List<AttendanceModel>> getUserAttendances(String userId) async {
    try {
      QuerySnapshot snapshot = await _attendancesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('checkInTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Mesai kayıtları getirilemedi: $e';
    }
  }

  // Kullanıcının mesai kayıtlarını stream olarak dinle
  Stream<List<AttendanceModel>> userAttendancesStream(String userId) {
    return _attendancesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('checkInTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromFirestore(doc))
            .toList());
  }

  // Belirli tarih aralığındaki kayıtları getir
  Future<List<AttendanceModel>> getAttendancesByDateRange({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      QuerySnapshot snapshot = await _attendancesCollection
          .where('userId', isEqualTo: userId)
          .where('checkInTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('checkInTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('checkInTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Tarih aralığı kayıtları getirilemedi: $e';
    }
  }

  // Tüm kullanıcıların bugünkü kayıtlarını getir (Admin için)
  Future<List<AttendanceModel>> getTodayAllAttendances() async {
    try {
      final today = _getTodayDate();
      
      QuerySnapshot snapshot = await _attendancesCollection
          .where('date', isEqualTo: today)
          .get();

      List<AttendanceModel> attendances = snapshot.docs
          .map((doc) => AttendanceModel.fromFirestore(doc))
          .toList();

      // Giriş saatine göre sırala (manuel, çünkü orderBy ile where birlikte index gerektirir)
      attendances.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));

      return attendances;
    } catch (e) {
      throw 'Bugünkü kayıtlar getirilemedi: $e';
    }
  }
}