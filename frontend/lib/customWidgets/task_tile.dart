import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/flat_tasks.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../models/flat.dart';
import '../screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'models/task.dart'; // your Task class
import 'package:intl/intl.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final DocumentReference userRef;
  final VoidCallback onDone;

  const TaskTile({
    super.key,
    required this.task,
    required this.userRef,
    required this.onDone,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  late Task task;

  @override
  void initState() {
    super.initState();
    task = widget.task;
  }

  IconData getChoreIcon(String key) {
  switch (key.trim()) {
    case 'Cleaning the kitchen':
      return Icons.kitchen;
    case 'Cleaning the bathroom':
      return Icons.bathtub;
    case 'Doing laundry':
      return Icons.local_laundry_service;
    case 'Doing the dishes':
      return Icons.restaurant;
    case 'Taking out recycling':
      return Icons.recycling;
    case 'Taking out the trash':
      return Icons.delete;
    default:
      return Icons.task_alt; // fallback icon
  }
}

  Future<void> _claimTask() async {
    try {
      await FirebaseFirestore.instance
          .collection('Tasks')
          .doc(task.taskId)
          .update({'assignedTo': widget.userRef});

      setState(() {
        task = Task(
          description: task.description,
          isOneOff: task.isOneOff,
          taskId: task.taskId,
          assignedFlat: task.assignedFlat,
          assignedTo: widget.userRef,
          done: task.done,
          setDate: task.setDate,
          priority: task.priority,
          frequency: task.frequency,
          lastDoneOn: task.lastDoneOn,
          lastDoneBy: task.lastDoneBy,
          // isPersonal: task.isPersonal,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error claiming task: $e')));
    }
    widget.onDone();
  }

   Future<void> _markDone() async {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final updateData = task.isOneOff
        ? {'done': true}
        : {'lastDoneOn': now, 'lastDoneBy': widget.userRef};

    try {
      await FirebaseFirestore.instance
          .collection('Tasks')
          .doc(task.taskId)
          .update(updateData);

      setState(() {
        task = Task(
          description: task.description,
          isOneOff: task.isOneOff,
          taskId: task.taskId,
          assignedFlat: task.assignedFlat,
          assignedTo: task.assignedTo,
          done: task.isOneOff ? true : task.done,
          setDate: task.setDate,
          priority: task.priority,
          frequency: task.frequency,
          lastDoneOn: task.isOneOff ? null : now,
          lastDoneBy: task.isOneOff ? null : widget.userRef,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error marking task as done: $e')));
    }
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    if (task.isOneOff == true) {
      return FutureBuilder(
        future: getNameFromDocRef(task.assignedTo), 
        builder: (context, snapshot) {
        return Card(
        margin: EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.description,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (task.setDate != null) Text("Date created: ${task.setDate}"),
              if (task.priority)
                Text("High priority!!", style: TextStyle(color: Colors.red)),
              // if (!task.isOneOff && task.lastDoneOn != null) Text("Last done on: ${task.lastDoneOn} by ${task.lastDoneBy ?? "Unknown"}"),
              SizedBox(height: 20),

              if (task.assignedTo == null)
                ElevatedButton(
                  onPressed: _claimTask,
                  child: Text('Claim Task'),
                ),

              if (task.assignedTo == widget.userRef)
                ElevatedButton(
                  onPressed: task.isOneOff && task.done == true
                      ? null : _markDone,
                      // : () {_markDone(widget.userRef);},
                  child: Text(
                    task.isOneOff && task.done == true
                        ? 'Already Done'
                        : 'Mark as Done',
                  ),
                ),

              if (task.assignedTo != null && task.assignedTo != widget.userRef)
                Text("Claimed by: ${snapshot.data}"),
            ],
          ),
        ),
      );
        }
      );
    } else {
      return FutureBuilder(
        future: getNameFromDocRef(task.assignedTo),
        builder: (context, snapshot) {
          return Card(
            margin: EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(getChoreIcon(task.description), color: const Color.fromARGB(255, 20, 0, 150), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          task.description,
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  
                  Text("Frequency: ${formatDisplayFrequency(task.frequency)}"),
                  if (task.lastDoneOn != null && task.lastDoneBy != null)
                    FutureBuilder<String>(
                      future: getNameFromDocRef(task.lastDoneBy),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Text("Last done on: ${task.lastDoneOn} by ...");
                        }
                        return Text(
                          "Last done on: ${task.lastDoneOn} by ${snapshot.data ?? "Unknown"}",
                        );
                      },
                    ),
                  Text("Assigned to: ${snapshot.data}"),
                  SizedBox(height: 20),

                  if (task.assignedTo == widget.userRef)
                    ElevatedButton(onPressed : _markDone,
                      // onPressed: () async {
                      //   DocumentReference next = widget.userRef;
                      //   if (!task.isPersonal) {
                      //     final users = await fetchAllUserRefs(task.assignedFlat);
                      //     final nextIndex = (users.indexOf(widget.userRef) + 1) % users.length;
                      //     next = users[nextIndex];
                      //   }
                      //   await _markDone(next);
                      // },
                      child: Text('Mark as Done'),
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Future<String> getNameFromDocRef(DocumentReference? dref) async {
    if (dref != null) {
      final data = await dref.get();
      return data['name'];
    } else {
      return "Nobody";
    }
  }
  
  formatDisplayFrequency(int frequency) {
    if (frequency == 1) {
      return 'Daily';
    } else if (frequency == 7) {
      return 'Weekly';
    } else {
      return 'Every $frequency days';
    }
  }
}
  Future<List<DocumentReference>> fetchAllUserRefs(DocumentReference flat) async {
    List<DocumentReference> allUsers = [];
    final queryRef = FirebaseFirestore.instance
        .collection('Users')
        .where('flat', isEqualTo: flat)
        .orderBy('name');
    final querySnap = await queryRef.get();
    if (querySnap.docs.isNotEmpty) {
      // print("in flat tasks");
      allUsers = querySnap.docs.map((doc) =>
         doc.reference).toList();
    }
    return allUsers;
  }
