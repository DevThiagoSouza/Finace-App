import 'package:cloud_firestore/cloud_firestore.dart';

class HouseholdNotification {
  const HouseholdNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.authorUid,
  });

  final String id;
  final String title;
  final String message;
  final int createdAt;
  final String authorUid;

  factory HouseholdNotification.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return HouseholdNotification(
      id: doc.id,
      title: (data['title'] ?? 'Atualização') as String,
      message: (data['message'] ?? '') as String,
      createdAt: ((data['createdAt'] ?? 0) as num).toInt(),
      authorUid: (data['authorUid'] ?? '') as String,
    );
  }
}
