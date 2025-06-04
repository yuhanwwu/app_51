import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/edit_task.dart';
import 'package:http/http.dart';
import '../../models/task.dart';
import '../../models/user.dart';
// import 'models/task.dart'; // your Task class
import 'package:intl/intl.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final User user;
  final DocumentReference userRef;
  final VoidCallback onDone;

  const TaskTile({
    super.key,
    required this.user,
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

  Future<void> _deleteTask() async {
      await widget.task.taskRef.delete();
  }

  Future<void> _claimTask() async {
    try {
      await FirebaseFirestore.instance
          .collection('Tasks')
          .doc(task.taskId)
          .update({'assignedTo': widget.userRef});

      setState(() {
        task = Task(
          taskRef: task.taskRef,
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
          isPersonal: task.isPersonal,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error claiming task: $e')));
    }
    widget.onDone();
  }

  // modify so that for a 'flat task', will assign to next flatmate in round robin manner
  Future<void> _markDone(DocumentReference nextUser) async {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // final allUsers = await fetchAllUsers(widget.assignedFlat);
    final updateData = task.isOneOff
        ? {'done': true}
        : (task.isPersonal
              ? {'lastDoneOn': now, 'lastDoneBy': widget.userRef}
              : {
                  'lastDoneOn': now,
                  'lastDoneBy': widget.userRef,
                  'assignedTo': nextUser,
                });
    // : {'lastDoneOn': now, 'lastDoneBy': widget.userRef};

    try {
      await FirebaseFirestore.instance
          .collection('Tasks')
          .doc(task.taskId)
          .update(updateData);

      setState(() {
        task = Task(
          taskRef: task.taskRef,
          description: task.description,
          isOneOff: task.isOneOff,
          taskId: task.taskId,
          assignedFlat: task.assignedFlat,
          assignedTo: nextUser,
          done: task.isOneOff ? true : task.done,
          setDate: task.setDate,
          priority: task.priority,
          frequency: task.frequency,
          lastDoneOn: task.isOneOff ? null : now,
          lastDoneBy: task.isOneOff ? null : widget.userRef,
          isPersonal: task.isOneOff ? false : task.isPersonal,
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error marking task as done: $e')));
    }
    widget.onDone();
  }

  Widget claimButton() {
    return ElevatedButton(onPressed: _claimTask, child: Text('Claim Task'));
  }

  Widget doneRepeatButton() {
    return ElevatedButton(
      //onPressed : _markDone,
      onPressed: () async {
        DocumentReference next = widget.userRef;
        if (!task.isPersonal) {
          final users = await fetchAllUserRefs(task.assignedFlat);
          final nextIndex = (users.indexOf(widget.userRef) + 1) % users.length;
          next = users[nextIndex];
        }
        await _markDone(next);
      },
      child: Text('Mark as Done'),
    );
  }

  Widget doneOneOffButton() {
    return ElevatedButton(
      onPressed: task.isOneOff && task.done == true
          ? null //: _markDone,
          : () {
              _markDone(widget.userRef);
            },
      child: Text(
        task.isOneOff && task.done == true ? 'Already Done' : 'Mark as Done',
      ),
    );
  }

  Widget deleteButton() {
    return ElevatedButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => FractionallySizedBox(
            heightFactor: 0.8,
            child: ElevatedButton(onPressed: () {_deleteTask(); widget.onDone(); Navigator.pop(context);}, child: Text('Confirm Delete?'))
          )
        );
      },
      child: Text('Delete Task'));
  }

  Widget editButton() {
    return ElevatedButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => FractionallySizedBox(
            heightFactor: 0.8,
            child: EditTaskPage(
              curUser: widget.user,
              onTaskSubmitted: widget.onDone,
              task: widget.task,
            ),
          ),
        );
      },
      child: Text('Edit Task'),
    );
  }

  Widget buildOneOffTile(BuildContext context) {
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
                  Row(children: [claimButton(), editButton(), deleteButton()]),

                if (task.assignedTo == widget.userRef)
                  Row(children: [doneOneOffButton(), editButton(), deleteButton()]),

                if (task.assignedTo != null &&
                    task.assignedTo != widget.userRef)
                  Text("Claimed by: ${snapshot.data}"),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildRepeatTile(BuildContext context) {
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
                Text("Frequency: every ${task.frequency} day(s)"),
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
                
                  SizedBox(height: 10),
                  Text("Frequency: every ${task.frequency} day(s)"),
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
                  // Text("Assigned to: ${snapshot.data}"),
                  SizedBox(height: 20),

                if (task.assignedTo == widget.userRef) 
                  Row(
                    children: [
                      doneRepeatButton(),
                      editButton(),
                      deleteButton(),
                    ],
                  )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (task.isOneOff == true) {
      return buildOneOffTile(context);
    } else {
      return buildRepeatTile(context);
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
}

Future<List<DocumentReference>> fetchAllUserRefs(DocumentReference flat) async {
  List<DocumentReference> allUsers = [];
  final queryRef = FirebaseFirestore.instance
      .collection('Users')
      .where('flat', isEqualTo: flat)
      .orderBy('name');
  final querySnap = await queryRef.get();
  if (querySnap.docs.isNotEmpty) {
    allUsers = querySnap.docs.map((doc) => doc.reference).toList();
  }
  return allUsers;
}
