import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final DocumentReference userRef;
  final String username;
  final String name;
  final DocumentReference flat;

  User({
    required this.userRef,
    required this.username,
    required this.name,
    required this.flat,
  });

  // factory User.fromJson(Map<String, dynamic> json) {
  //   return User(
  //     username: json['username'] ?? '',
  //     name: json['name'] ?? '',
  //     flat: json['flat'] ?? '',
  //   );
  // }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      userRef: doc.reference,
      username: doc.id,
      name: data['name'],
      flat: data['flat'],
    );
  }
}
