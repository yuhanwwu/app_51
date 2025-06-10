import 'package:cloud_firestore/cloud_firestore.dart';

class Flat {
  final String id;
  final String name;
  final int numOfCompletedQuestionnaires;
  final int bathroom;
  final int kitchen;
  final int laundry;
  final int recycling;
  final int rubbish;
  final int dishes;

  Flat({
    required this.id,
    required this.name,
    required this.numOfCompletedQuestionnaires,
    required this.bathroom,
    required this.kitchen,
    required this.laundry,
    required this.recycling,
    required this.rubbish,
    required this.dishes,
  });

  //   factory User.fromJson(Map<String, dynamic> json) {
  //     return User(
  //       username: json['username'] ?? '',
  //       name: json['name'] ?? '',
  //       flat: json['flat'] ?? '',
  //     );

  factory Flat.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Flat(
      id: doc.id,
      name: data['name'],
      numOfCompletedQuestionnaires: data['numOfCompletedQuestionnaires'] ?? 0,
      bathroom: data['bathroom'] ?? 0,
      kitchen: data['kitchen'] ?? 0,
      laundry: data['laundry'] ?? 0,
      recycling: data['recycling'] ?? 0,
      rubbish: data['rubbish'] ?? 0,
      dishes: data['dishes'] ?? 0,
    );
  }
}
