import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/flat_tasks.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../models/flat.dart';

// class TaskTile extends StatelessWidget {
//   final Task task;
//   final VoidCallback? onDone;
//   final String curUser;

//   const TaskTile({Key? key, required this.task, this.onDone, required this.curUser}) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return ListTile(
//       title: Text(task.description),
//       subtitle: Text(task.isOneOff
//           ? 'Priority: ${task.priority ? "High" : "Normal"}'
//           : 'Frequency: every ${task.frequency} days'),
//       trailing: Icon(Icons.chevron_right),
//       onTap: onTap,
//     );
//   }

// }

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'models/task.dart'; // your Task class
import 'package:intl/intl.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final DocumentReference userRef;
  final VoidCallback? onDone;

  const TaskTile({
    Key? key,
    required this.task,
    required this.userRef,
    required this.onDone,
  }) : super(key: key);

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
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error claiming task: $e')));
    }
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
  }

  @override
  Widget build(BuildContext context) {
    if (task.isOneOff == true) {
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
                      ? null
                      : _markDone,
                  child: Text(
                    task.isOneOff && task.done == true
                        ? 'Already Done'
                        : 'Mark as Done',
                  ),
                ),

              if (task.assignedTo != null && task.assignedTo != widget.userRef)
                Text("Claimed by: ${task.assignedTo.toString()}"),
            ],
          ),
        ),
      );
    } else {
      return FutureBuilder(
        future: getUserFromDocRef(task.assignedTo!),
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
                  if (task.lastDoneOn != null)
                    Text(
                      "Last done on: ${task.lastDoneOn} by ${task.lastDoneBy ?? "Unknown"}",
                    ), //should never be unknown tho
                  Text("Assigned to: ${snapshot.data}"),
                  SizedBox(height: 20),

                  if (task.assignedTo == widget.userRef)
                    ElevatedButton(
                      onPressed: _markDone,
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

  Future<String> getUserFromDocRef(DocumentReference dref) async {
    final data = await dref.get();
    return data['name'];
  }
}
