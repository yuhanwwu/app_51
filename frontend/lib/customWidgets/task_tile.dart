import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/edit_task.dart';
import 'package:http/http.dart';
import '../../models/task.dart';
import '../../models/user.dart';
import '../../models/flat.dart';
import '../screens/task_page.dart';
import 'package:flutter/material.dart';
// import 'models/task.dart'; // your Task class
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

class TaskTile extends StatefulWidget {
  final Task task;
  final FlatUser user;
  final DocumentReference userRef;
  final VoidCallback onDone;
  final bool canEdit;

  const TaskTile({
    super.key,
    required this.user,
    required this.task,
    required this.userRef,
    required this.onDone,
    this.canEdit = true,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  late Task task;
  bool _isVisible = true;
  bool _showSuccess = false;

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
        return Icons.task_alt;
    }
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

  Future<void> _markDone(DocumentReference nextUser) async {
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final updateData = task.isOneOff
        ? {'done': true}
        : (task.isPersonal
              ? {'lastDoneOn': now, 'lastDoneBy': widget.userRef}
              : {
                  'lastDoneOn': now,
                  'lastDoneBy': widget.userRef,
                  'assignedTo': nextUser,
                });

    try {
      await FirebaseFirestore.instance
          .collection('Tasks')
          .doc(task.taskId)
          .update(updateData);

      setState(() {
        //  _isVisible = false;
        _showSuccess = true;
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
      await Future.delayed(Duration(milliseconds: 1500));
      setState(() {
        _isVisible = false;
      });
      await Future.delayed(Duration(milliseconds: 300));
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
            child: ElevatedButton(
              onPressed: () {
                _deleteTask();
                widget.onDone();
                Navigator.pop(context);
              },
              child: Text('Confirm Delete?'),
            ),
          ),
        );
      },
      child: Text('Delete Task'),
    );
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
                  Row(
                    children: [
                      doneOneOffButton(),
                      editButton(),
                      deleteButton(),
                    ],
                  ),

                if (task.assignedTo != null &&
                    task.assignedTo != widget.userRef)
                  Text("Claimed by: ${snapshot.data}"),
              ],
            ),
          ),
          // <<<<<<< edit_task
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
                Row(
                  children: [
                    Icon(
                      getChoreIcon(task.description),
                      color: const Color.fromARGB(255, 20, 0, 150),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.description,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                SizedBox(height: 20),

                if (task.assignedTo == widget.userRef)
                  Row(
                    children: [
                      doneRepeatButton(),
                      editButton(),
                      deleteButton(),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDetailsPopup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    task.description,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(),
              SizedBox(height: 16),

              if (task.isOneOff) ...[
                if (task.setDate != null) Text("Date created: ${task.setDate}"),
                if (task.priority)
                  Text("High priority!!", style: TextStyle(color: Colors.red)),
              ] else ...[
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
              ],

              Spacer(),

              // Claim Task button
              if (task.assignedTo == null)
                ElevatedButton(
                  onPressed: _claimTask,
                  child: Text('Claim Task'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),

              // Mark as Done button
              if (task.assignedTo == widget.userRef)
                ElevatedButton(
                  onPressed: () async {
                    DocumentReference next = widget.userRef;
                    if (!task.isPersonal) {
                      final users = await fetchAllUserRefs(task.assignedFlat);
                      final nextIndex =
                          (users.indexOf(widget.userRef) + 1) % users.length;
                      next = users[nextIndex];
                    }
                    await _markDone(next);
                    Navigator.pop(context);
                  },
                  child: Text('Mark as Done'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                  ),
                ),

              SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Confirm Delete'),
                            content: Text(
                              'Are you sure you want to delete this task?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  _deleteTask();
                                  widget.onDone();
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Text('Delete Task'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[100],
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override

Widget build(BuildContext context) {
  return AnimatedSize(
    duration: Duration(milliseconds: 300),
    curve: Curves.easeInOut,
    child: AnimatedOpacity(
      opacity: _isVisible ? 1 : 0,
      duration: Duration(milliseconds: 300),
      child: _isVisible
          ? Stack(
              alignment: Alignment.center,
              children: [
                ListTile(
                  leading: Icon(getChoreIcon(task.description)),
                  title: Text(
                    task.description,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      decoration: task.isOneOff && task.done!
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (task.assignedTo == null && widget.canEdit)
                        TextButton(
                          onPressed: _claimTask,
                          child: Text('Claim'),
                        ),
                      if (task.assignedTo == widget.userRef && widget.canEdit)
                        Checkbox(
                          value: task.isOneOff && task.done!,
                          onChanged: (value) async {
                            DocumentReference next = widget.userRef;
                            if (!task.isPersonal) {
                              final users =
                                  await fetchAllUserRefs(task.assignedFlat);
                              final nextIndex =
                                  (users.indexOf(widget.userRef) + 1) %
                                      users.length;
                              next = users[nextIndex];
                            }
                            await _markDone(next);
                          },
                        ),
                      if (widget.canEdit)
                        IconButton(
                          icon: Icon(Icons.more_vert),
                          onPressed: () => _showDetailsPopup(context),
                        ),
                    ],
                  ),
                ),
                if (_showSuccess)
                  Positioned.fill(
                    child: Container(
                      color: Colors.white.withAlpha(204), // Optional overlay color
                      alignment: Alignment.center,
                      child: ClipRect( // Clips the animation to its bounding box
                        child: Align(
                          alignment: Alignment.center, // Centers the animation
                          child: Lottie.asset(
                            'animations/success2.json',
                            repeat: false,
                            fit: BoxFit.contain, // Ensures the animation fits within its bounds
                          ),
                        ),
                      ),
                    ),
                  )
              ],
            )
          : SizedBox.shrink(),
    ),
  );
}


  Future<String> getNameFromDocRef(DocumentReference? dref) async {
    if (dref != null) {
      final data = await dref.get();
      return data['name'];
    } else {
      return "Nobody";
    }
  }

  String formatDisplayFrequency(int frequency) {
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
    allUsers = querySnap.docs.map((doc) => doc.reference).toList();
  }
  return allUsers;
}
