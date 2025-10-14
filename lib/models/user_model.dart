import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? department;
  final DateTime? hireDate;
  final bool isActive;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.department,
    this.hireDate,
    this.isActive = true,
    required this.createdAt,
  });

  // Firestore'dan veri çekerken kullanılır
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: data['role'] ?? 'employee',
      phone: data['phone'],
      department: data['department'],
      hireDate: data['hireDate'] != null 
          ? (data['hireDate'] as Timestamp).toDate() 
          : null,
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Firestore'a veri kaydederken kullanılır
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'phone': phone,
      'department': department,
      'hireDate': hireDate,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Kullanıcı bilgilerini güncellerken kullanılır
  UserModel copyWith({
    String? uid,
    String? email,
    String? name,
    String? role,
    String? phone,
    String? department,
    DateTime? hireDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      hireDate: hireDate ?? this.hireDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}