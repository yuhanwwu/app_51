import 'package:cloud_firestore/cloud_firestore.dart';

// //TODO maybe tasks only come up when they are freq no. days after last done?

class Task {
  //needed for all tasks
  final DocumentReference taskRef;
  final String description;
  final bool isOneOff;
  final String taskId;
  final DocumentReference assignedFlat;
  final DocumentReference? assignedTo; //? for one off, required for repeat
  final String setDate;

  //one off tasks
  final bool? done;
  final bool priority; //False for repeat

  //repeat tasks
  final int frequency; //0 for one off
  final String? lastDoneOn; //? for repeat
  final DocumentReference? lastDoneBy; //? for repeat
  final bool isPersonal; //false for one off

  // final DocumentReference noteId;

  Task({
    required this.taskRef,
    required this.description,
    required this.isOneOff,
    required this.taskId,
    required this.assignedFlat,
    this.assignedTo,
    this.done,
    required this.setDate,
    required this.priority,
    required this.frequency,
    this.lastDoneOn,
    this.lastDoneBy,
    required this.isPersonal,
    // required this.noteId,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isOneOff = data['isOneOff'] as bool;
    return Task(
      taskRef: doc.reference,
      description: data['description'],
      isOneOff: data['isOneOff'] ?? false,
      taskId: doc.id,
      assignedFlat: data['assignedFlat'] as DocumentReference,
      assignedTo: isOneOff
          ? data['assignedTo'] as DocumentReference?
          : data['assignedTo'] as DocumentReference,
      done: isOneOff ? data['done'] : null,
      setDate: data['setDate'],
      priority: isOneOff ? (data['priority'] as bool? ?? false) : false,
      frequency: isOneOff ? 0 : data['frequency'] as int,
      // frequency: isOneOff ? 0 : (data['frequency'] as int? ?? 0),
      lastDoneOn: isOneOff ? null : data['lastDoneOn'] as String?,
      lastDoneBy: isOneOff ? null : data['lastDoneBy'] as DocumentReference?,
      isPersonal: isOneOff ? false : data['isPersonal'] as bool,
      // noteId: data['noteId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'description': description,
      'isOneOff': isOneOff,
      'assignedFlat': assignedFlat,
      'assignedTo': assignedTo,
      'done': done,
      'setDate': setDate,
      'priority': priority,
      'frequency': frequency,
      'lastDoneOn': lastDoneOn,
      'lastDoneBy': lastDoneBy,
      'isPersonal': isPersonal,
      // 'noteId': noteId,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      taskRef:
          map['taskRef'] as DocumentReference? ??
          FirebaseFirestore.instance
              .collection('Tasks')
              .doc(map['taskId'] ?? ''), // fallback if not present
      description: map['description'] ?? '',
      isOneOff: map['isOneOff'] ?? false,
      taskId: map['taskId'],
      assignedFlat: map['assignedFlat'],
      assignedTo: map['assignedTo'],
      done: map['done'] ?? false,
      setDate: map['setDate'],
      priority: map['priority'],
      frequency: map['frequency'],
      lastDoneOn: map['lastDoneOn'],
      lastDoneBy: map['lastDoneBy'],
      isPersonal: map['isPersonal'] ?? false,
      // noteId: map['noteId'],
      // add other fields as needed
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          runtimeType == other.runtimeType &&
          taskId == other.taskId;

  @override
  int get hashCode => taskId.hashCode;
}
