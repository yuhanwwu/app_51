import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final DocumentReference userRef;
  final String username;
  final String name;
  final DocumentReference flat;
  final bool questionnaireDone;

  User({required this.username, required this.name, required this.flat, required this.questionnaireDone});

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      userRef: doc.reference, 
      username: doc.id,
      name: data['name'],
      flat: data['flat'],
      questionnaireDone: data['questionnaireDone']
      );
  }
}
