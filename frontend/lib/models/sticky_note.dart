import 'package:cloud_firestore/cloud_firestore.dart';

class StickyNote {
  final String id;
  final String content;
  final List<double> position;
  final DocumentReference flatRef;
  final String createdBy;

  StickyNote({
    required this.id,
    required this.content,
    required this.position,
    required this.flatRef,
    required this.createdBy,
  });

  factory StickyNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StickyNote(
      id: doc.id,
      content: data['content'] ?? '',
      position: List<double>.from(data['position'] ?? [0.0, 0.0]),
      flatRef: data['flatRef'],
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'content': content,
    'position': position,
    'flatRef': flatRef,
  };
}