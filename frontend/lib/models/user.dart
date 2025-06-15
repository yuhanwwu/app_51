import 'package:cloud_firestore/cloud_firestore.dart';

class FlatUser {
  final DocumentReference userRef;
  final String username;
  final String name;
  final DocumentReference flat;
  final bool questionnaireDone;
  final String role; 
  bool get isGuest => role == 'guest';

  FlatUser({
    required this.userRef,
    required this.username,
    required this.name,
    required this.flat,
    required this.questionnaireDone,
    required this.role,
  });
  factory FlatUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlatUser(
      userRef: doc.reference,
      username: doc.id,
      name: data['name'] ?? '',
      flat: data['flat'],
      questionnaireDone: data['questionnaireDone'] ?? false,
      role: data['role'] ?? '',
    );
  }
}

