import 'package:cloud_firestore/cloud_firestore.dart';

class Flat {
  final String id;
  final String name;

  Flat({required this.id, required this.name});

  //   factory User.fromJson(Map<String, dynamic> json) {
  //     return User(
  //       username: json['username'] ?? '',
  //       name: json['name'] ?? '',
  //       flat: json['flat'] ?? '',
  //     );

  factory Flat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Flat(id: doc.id, name: data['name']);
  }
}
