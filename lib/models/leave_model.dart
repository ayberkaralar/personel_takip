import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveModel {
  final String id;
  final String userId;
  final String userName;
  final DateTime startDate;
  final DateTime endDate;
  final String type; // annual, sick, unpaid
  final String status; // pending, approved, rejected
  final String? reason;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;

  LeaveModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.status,
    this.reason,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
  });

  // Firestore'dan veri çekerken
  factory LeaveModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return LeaveModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      type: data['type'] ?? 'annual',
      status: data['status'] ?? 'pending',
      reason: data['reason'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      approvedAt: data['approvedAt'] != null 
          ? (data['approvedAt'] as Timestamp).toDate() 
          : null,
      approvedBy: data['approvedBy'],
    );
  }

  // Firestore'a veri kaydederken
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'type': type,
      'status': status,
      'reason': reason,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'approvedBy': approvedBy,
    };
  }

  // İzin gün sayısını hesapla
  int get totalDays {
    return endDate.difference(startDate).inDays + 1;
  }

  // Durum rengi
  String get statusText {
    switch (status) {
      case 'pending':
        return 'Onay Bekliyor';
      case 'approved':
        return 'Onaylandı';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Bilinmiyor';
    }
  }

  // İzin tipi metni
  String get typeText {
    switch (type) {
      case 'annual':
        return 'Yıllık İzin';
      case 'sick':
        return 'Hastalık İzni';
      case 'unpaid':
        return 'Ücretsiz İzin';
      default:
        return 'Diğer';
    }
  }
}