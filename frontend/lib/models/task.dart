import 'package:cloud_firestore/cloud_firestore.dart';

// //TODO maybe tasks only come up when they are freq no. days after last done?

class Task {
  // final String description;
  // final bool isOneOff;
  // final bool? priority; // only for one-off tasks
  // final String? lastdoneon; // only for repeat tasks
  // final int? frequency; // only for repeat tasks
  // final String assignedto; // added for user assignment

  // Task({
  //   required this.description,
  //   this.priority,
  //   this.lastdoneon,
  //   required this.isOneOff,
  //   this.frequency,
  //   required this.assignedto,
  // });

  // factory Task.fromJson(Map<String, dynamic> json, {required bool isOneOff}) {
  //   return Task(
  //     description: json['description'] ?? '',
  //     isOneOff: isOneOff,
  //     priority: isOneOff ? json['priority'] as bool? : null,
  //     lastdoneon: isOneOff ? null : json['lastdoneon'] as String?,
  //     frequency: isOneOff ? null : json['frequency'] as int?,
  //     assignedto: json['assignedto'] ?? '',
  //   );
  // }

  // factory Task.fromFirestore(DocumentSnapshot doc, {required bool isOneOff}) {
  // // final data = doc.data() as Map<String, dynamic>;
  // return Task(
  //   description: data['description'] ?? '',
  //   isOneOff: isOneOff,
  //   priority: isOneOff ? data['priority'] as bool? : null,
  //   lastdoneon: isOneOff ? null : data['lastdoneon'] as String?,
  //   frequency: isOneOff ? null : data['frequency'] as int?,
  //   assignedto: data['assignedto'] ?? '',
  // );
  // }

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
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isOneOff = data['isOneOff'] as bool;
    return Task(
      taskRef: doc.reference as DocumentReference,
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
    );
  }
}
