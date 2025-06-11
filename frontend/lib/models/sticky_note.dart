import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/task.dart';

class StickyNote {
  final String id;
  final String content;
  final List<double> position;
  final DocumentReference flatRef;
  final DocumentReference createdBy;
  final String type;
  final List<DocumentReference> tasks;

  StickyNote({
    required this.id,
    required this.content,
    required this.position,
    required this.flatRef,
    required this.createdBy,
    required this.type,
    required this.tasks,
  });

  factory StickyNote.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StickyNote(
      id: doc.id,
      content: data['content'] ?? '',
      position: List<double>.from(data['position'] ?? [0.0, 0.0]),
      flatRef: data['flatRef'],
      createdBy: data['createdBy'] as DocumentReference,
      type: data['type'] ?? 'Empty Note',
      tasks: List<DocumentReference>.from(
        (data['tasks'] ?? [].map((t) => t as DocumentReference)),
      ), //,.map((t) => (Task.fromMap(t as Map<String, dynamic>)))),
    );
  }

  Map<String, dynamic> toMap() => {
    'content': content,
    'position': position,
    'flatRef': flatRef,
    'createdBy': createdBy,
    'type': type,
    'tasks': tasks,
  };
}
