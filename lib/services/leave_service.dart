import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_model.dart';

class LeaveService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _leavesCollection => _db.collection('leaves');

  // İzin talebi oluştur
  Future<String> createLeaveRequest({
    required String userId,
    required String userName,
    required DateTime startDate,
    required DateTime endDate,
    required String type,
    String? reason,
  }) async {
    try {
      DocumentReference docRef = await _leavesCollection.add({
        'userId': userId,
        'userName': userName,
        'startDate': Timestamp.fromDate(startDate),
        'endDate': Timestamp.fromDate(endDate),
        'type': type,
        'status': 'pending',
        'reason': reason,
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': null,
        'approvedBy': null,
      });
      
      return docRef.id;
    } catch (e) {
      throw 'İzin talebi oluşturulamadı: $e';
    }
  }

  // Kullanıcının izin taleplerini getir
  Future<List<LeaveModel>> getUserLeaves(String userId) async {
    try {
      QuerySnapshot snapshot = await _leavesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LeaveModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'İzin talepleri getirilemedi: $e';
    }
  }

  // Kullanıcının izin taleplerini stream olarak dinle
  Stream<List<LeaveModel>> userLeavesStream(String userId) {
    return _leavesCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => LeaveModel.fromFirestore(doc))
            .toList());
  }

  // Tüm bekleyen izin taleplerini getir (Admin için)
  Future<List<LeaveModel>> getPendingLeaves() async {
    try {
      QuerySnapshot snapshot = await _leavesCollection
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => LeaveModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw 'Bekleyen izinler getirilemedi: $e';
    }
  }

  // İzin talebini onayla/reddet (Admin için - sonra eklenecek)
  Future<void> updateLeaveStatus({
    required String leaveId,
    required String status,
    required String approvedBy,
  }) async {
    try {
      await _leavesCollection.doc(leaveId).update({
        'status': status,
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': approvedBy,
      });
    } catch (e) {
      throw 'İzin durumu güncellenemedi: $e';
    }
  }

  // İzin talebini sil
  Future<void> deleteLeave(String leaveId) async {
    try {
      await _leavesCollection.doc(leaveId).delete();
    } catch (e) {
      throw 'İzin talebi silinemedi: $e';
    }
  }
}