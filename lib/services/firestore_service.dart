import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Kullanıcı koleksiyonu
  CollectionReference get _usersCollection => _db.collection('users');

  // Yeni kullanıcı oluştur
  Future<void> createUser({
    required String uid,
    required String email,
    required String name,
    String role = 'employee',
  }) async {
    try {
      await _usersCollection.doc(uid).set({
        'email': email,
        'name': name,
        'role': role,
        'phone': null,
        'department': null,
        'hireDate': null,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw 'Kullanıcı kaydedilemedi: $e';
    }
  }

  // Kullanıcı bilgilerini getir
  Future<UserModel?> getUser(String uid) async {
    try {
      DocumentSnapshot doc = await _usersCollection.doc(uid).get();
      
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw 'Kullanıcı bilgileri alınamadı: $e';
    }
  }

  // Kullanıcı bilgilerini güncelle
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersCollection.doc(uid).update(data);
    } catch (e) {
      throw 'Kullanıcı güncellenemedi: $e';
    }
  }

  // Kullanıcı bilgilerini stream olarak dinle
  Stream<UserModel?> userStream(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Tüm kullanıcıları getir (Admin için)
  Future<List<UserModel>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _usersCollection.get();
      return snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
    } catch (e) {
      throw 'Kullanıcılar getirilemedi: $e';
    }
  }
}