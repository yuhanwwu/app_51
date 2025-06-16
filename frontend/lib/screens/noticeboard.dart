// import 'dart:nativewrappers/_internal/vm/lib/ffi_patch.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/customWidgets/task_tile.dart';
import 'package:frontend/main.dart';
import 'package:frontend/models/task.dart';
import 'package:frontend/models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/sticky_note.dart';
import 'package:intl/intl.dart';

class NoticeboardPage extends StatefulWidget {
  final FlatUser user;
  final DocumentReference flatRef;
  final DocumentReference userRef;
  final VoidCallback onLogout;
  const NoticeboardPage({
    super.key,
    required this.user,
    required this.flatRef,
    required this.userRef,
    required this.onLogout,
  });

  @override
  State<NoticeboardPage> createState() => _NoticeboardPageState();
}

class _NoticeboardPageState extends State<NoticeboardPage> {
  late CollectionReference notesRef;
  late DocumentReference userRef;
  String? flatName;

  Offset routineBoardPosition = const Offset(40, 40);
  String? routineBoardDocId;

  @override
  void initState() {
    super.initState();
    notesRef = FirebaseFirestore.instance.collection('Noticeboard');
    userRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.user.username);
    _loadFlatName();
    _loadRoutineBoardPosition();
  }

  Future<void> _loadFlatName() async {
    final flatDoc = await widget.flatRef.get();
    setState(() {
      flatName = flatDoc['name'];
    });
  }

  Future<void> _loadRoutineBoardPosition() async {
    final query = await notesRef
        .where('flatRef', isEqualTo: widget.flatRef)
        .where('type', isEqualTo: 'routine')
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) {
      final doc = query.docs.first;
      routineBoardDocId = doc.id;
      final pos = doc['position'];
      setState(() {
        routineBoardPosition = Offset(pos[0], pos[1]);
      });
    } else {
      final docRef = await notesRef.add({
        'type': 'routine',
        'flatRef': widget.flatRef,
        'createdBy': userRef,
        'position': [routineBoardPosition.dx, routineBoardPosition.dy],
      });
      routineBoardDocId = docRef.id;
    }
  }

  void _updateNotePosition(String noteId, List<double> newPosition) {
    notesRef.doc(noteId).update({'position': newPosition});
  }

  Future<void> _updateRoutineBoardPosition(Offset newPos) async {
    setState(() {
      routineBoardPosition = newPos;
    });
    if (routineBoardDocId != null) {
      await notesRef.doc(routineBoardDocId).update({
        'position': [newPos.dx, newPos.dy],
      });
    }
  }

  Widget logoutButton() {
    return IconButton(
      icon: Icon(Icons.logout),
      tooltip: 'Log Out',
      onPressed: () async {
        logout();
      },
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUsername');
    await FirebaseAuth.instance.signOut();
    widget.onLogout();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MyApp()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${flatName ?? ''}'s Noticeboard"),
        actions: [
          logoutButton(),
          // IconButton(
          //   icon: const Icon(Icons.assignment),
          //   tooltip: 'Go to Tasks',
          //   onPressed: () {
          //     Navigator.push(
          //       context,
          //       MaterialPageRoute(
          //         builder: (context) =>
          //             TaskPage(user: widget.user, onLogout: widget.onLogout),
          //       ),
          //     );
          //   },
          // ),
        ],
      ),
      floatingActionButton: widget.user.role == 'guest'
      ? null
      : FloatingActionButton(
        onPressed: () async {
          showModalBottomSheet(
            context: context,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => _AddNoteSheet(
              flatRef: widget.flatRef,
              userRef: userRef,
              user: widget.user,
              notesRef: notesRef,
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: notesRef
            .where('flatRef', isEqualTo: widget.flatRef)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final notes = snapshot.data!.docs
              .map((doc) => StickyNote.fromFirestore(doc))
              .where((note) => note.type != 'routine') // Exclude routine board
              .toList();

          return Stack(
            children: [
              // 1. Routine board (separate, not in notes)
              Positioned(
                left: routineBoardPosition.dx,
                top: routineBoardPosition.dy,
                child: Draggable(
                  feedback: Material(
                    color: Colors.transparent,
                    child: SizedBox(
                      width: 600,
                      child: RoutineBoardWidget(flatRef: widget.flatRef, userRef: widget.userRef,),
                    ),
                  ),
                  childWhenDragging: Opacity(
                    opacity: 0.5,
                    child: SizedBox(
                      width: 600,
                      child: RoutineBoardWidget(flatRef: widget.flatRef, userRef: widget.userRef,),
                    ),
                  ),
                  child: SizedBox(
                    width: 600,
                    child: RoutineBoardWidget(flatRef: widget.flatRef, userRef: widget.userRef,),
                  ),
                  onDragEnd: (details) {
                    _updateRoutineBoardPosition(details.offset);
                  },
                ),
              ),

              // 2. Sticky notes (from Firestore)
              ...notes.map((note) {
                return Positioned(
                  left: note.position[0],
                  top: note.position[1],
                  child: DraggableNote(
                    note: note,
                    onDragEnd: (offset) {
                      _updateNotePosition(note.id, [offset.dx, offset.dy]);
                    },
                    userRef: userRef,
                  ),
                );
              }),

              // 3. Bin
              Positioned(
                left: 32,
                bottom: 32,
                child: DragTarget<String>(
                  builder: (context, candidateData, rejectedData) {
                    if (widget.user.role != 'guest') {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: candidateData.isNotEmpty
                              ? Colors.red[300]
                              : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.delete,
                          size: 40,
                          color: Colors.black54,
                        ),
                      );
                    }
                    // Always return a widget
                    return SizedBox.shrink();
                  },
                  onWillAcceptWithDetails: (noteId) => true,
                  onAcceptWithDetails: (details) async {
                    if (widget.user.role != 'guest') {
                      await notesRef.doc(details.data).delete();
                    }
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class DraggableNote extends StatefulWidget {
  final StickyNote note;
  final void Function(Offset) onDragEnd;
  final VoidCallback? onDragStarted;
  final VoidCallback? onDragCompleted;
  final DocumentReference userRef;

  const DraggableNote({
    super.key,
    required this.note,
    required this.onDragEnd,
    this.onDragStarted,
    this.onDragCompleted,
    required this.userRef,
  });

  @override
  State<DraggableNote> createState() => _DraggableNoteState();
}

class _DraggableNoteState extends State<DraggableNote> {
  late Offset offset;

  @override
  void initState() {
    super.initState();
    offset = Offset(widget.note.position[0], widget.note.position[1]);
  }

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: widget.note.id,
      feedback: Material(
        elevation: 8,
        color: Colors.transparent,
        child: _noteWidget(),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: _noteWidget()),
      onDragStarted: widget.onDragStarted,
      onDragEnd: (details) {
        widget.onDragEnd(details.offset);
        widget.onDragCompleted?.call();
      },
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 120,
          maxWidth: 240,
          minHeight: 80,
          maxHeight: 350,
        ),
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.yellow[200],
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.note.content,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 20,
              ),
            ),
          ),
        ),
      ));
  }

  Widget _noteWidget() {
    final canEdit = widget.userRef.id == widget.note.createdBy.id;

    // If this is a task note and has tasks, show the task list
    if (widget.note.tasks.isNotEmpty) {
      return FutureBuilder<DocumentSnapshot>(
        future: widget.note.createdBy.get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          final username =
              userData?['username'] ?? snapshot.data!.id ?? 'unknown';
          final isCurrentUser = widget.userRef.id == widget.note.createdBy.id;

          return Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: isCurrentUser ? Colors.green : Colors.red,
                width: 3,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            constraints: BoxConstraints(maxWidth: 320, maxHeight: 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrentUser ? Colors.green[100] : Colors.red[100],
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Text(
                    'by $username',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isCurrentUser
                          ? Colors.green[900]
                          : Colors.red[900],
                    ),
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    child: ListView(
                      shrinkWrap: true,
                      children: widget.note.tasks
                          .map(
                            (taskRef) => FutureBuilder<DocumentSnapshot>(
                              future: taskRef.get(),
                              builder: (context, taskSnapshot) {
                                if (!taskSnapshot.hasData) {
                                  return CircularProgressIndicator();
                                }
                                return TaskTile(
                                  task: Task.fromFirestore(taskSnapshot.data!),
                                  user: FlatUser.fromFirestore(snapshot.data!),
                                  userRef: widget.note.createdBy,
                                  canEdit: canEdit,
                                  onDone: () {},
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    if (widget.note.type == 'image') {
      // debugPrint("I'm getting here.");
      return Material(
        elevation: 4,
        color: Colors.yellow[200],
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: 120,
            maxWidth: 240,
            minHeight: 80,
            maxHeight: 350,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              // 'https://media.giphy.com/media/v1.Y2lkPWVjZjA1ZTQ3NG5nMm9pdXhpbDZ3NmI1OTVnMHA0am91am85ZzN5YXIza21iNnAzNyZlcD12MV9naWZzX3NlYXJjaCZjdD1n/26FLb8rHh0T5B576E/giphy.gif',
              widget.note.content, // URL of the image
              fit: BoxFit.cover, // Adjust how the image fits within the note
            ),
          ),
        ),
      );
    }
    // Otherwise, show a simple text note
    return Material(
      elevation: 4,
      color: Colors.yellow[200],
      borderRadius: BorderRadius.circular(8),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 120,
          maxWidth: 240,
          minHeight: 80,
          maxHeight: 350,
        ),
        child: IntrinsicWidth(
          child: IntrinsicHeight(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // <-- Add this line
                children: [
                  Text(
                    widget.note.content,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 20,
                  ),
                  const SizedBox(height: 8),
                  FutureBuilder<DocumentSnapshot>(
                    future: widget.note.createdBy.get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return Text('by ...');
                      final userData = snapshot.data!.data() as Map<String, dynamic>?;
                      final username =
                          userData?['username'] ?? snapshot.data!.id ?? 'unknown';
                      return Text(
                        'by $username',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ));
  }
}

class _AddNoteSheet extends StatefulWidget {
  final DocumentReference flatRef;
  final FlatUser user;
  final CollectionReference notesRef;
  final DocumentReference userRef;

  const _AddNoteSheet({
    required this.flatRef,
    required this.user,
    required this.notesRef,
    required this.userRef,
  });

  @override
  State<_AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<_AddNoteSheet> {
  String _noteText = '';
  bool _isAddingText = true;
  bool _isAddingGif =  false;
  final List<Task> _selectedTasks = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: Text('Text Note'),
                  selected: _isAddingText,
                  onSelected: (val) => setState(() => _isAddingText = true),
                ),
                SizedBox(width: 12),
                ChoiceChip(
                  label: Text('Task Note'),
                  selected: !_isAddingText && !_isAddingGif,
                  onSelected: (val) {
                    setState(() {
                      _isAddingText = false;
                      _isAddingGif = false;
                    });
                  },
                  // onSelected: (val) => setState(() => _isAddingText = false),
                ),
                SizedBox(width: 12),
                ChoiceChip(
                  label: Text('Add img/gif'),
                  selected: !_isAddingText && _isAddingGif, 
                  onSelected: (val) {
                    setState(() {
                      _isAddingText = false;
                      _isAddingGif = true;
                    });
                  },
                  // onSelected: (val) => setState(() => _isAddingText = false),
                )
              ],
            ),
            const SizedBox(height: 16),
            if (_isAddingText)
              Column(
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Sticky Note Text'),
                    onChanged: (val) => _noteText = val,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_noteText.trim().isEmpty) return;
                      await widget.notesRef.add({
                        'content': _noteText.trim(),
                        'position': [100.0, 100.0],
                        'flatRef': widget.flatRef,
                        'createdBy': widget
                            .userRef, //FirebaseFirestore.instance.collection('Users').doc(widget.user.username),
                        'type': 'text',
                        'tasks': [],
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Add Text Note'),
                  ),
                ],
              )
            else if (_isAddingGif)
              Column(
                children: [
                  // Text('GIF/Image functionality is not implemented yet.'),
                  TextField(
                    decoration: InputDecoration(labelText: 'Gif img address'),
                    onChanged: (val) => _noteText = val,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      if (_noteText.trim().isEmpty) return;
                      await widget.notesRef.add({
                        'content': _noteText.trim(),
                        'position': [100.0, 100.0],
                        'flatRef': widget.flatRef,
                        'createdBy': widget
                            .userRef, 
                        'type': 'image',
                        'tasks': [],
                      });
                      Navigator.pop(context);
                    },
                    child: Text('Add Image Note'),
                  ),
                ],
              )
            else
              FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('Tasks')
                    .where('assignedFlat', isEqualTo: widget.flatRef)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  final tasks = snapshot.data!.docs
                      .map((doc) => Task.fromFirestore(doc))
                      .toList();
                  return Column(
                    children: [
                      SizedBox(
                        height: 310,
                        child: ListView.builder(
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final task = tasks[index];
                            final isSelected = _selectedTasks.contains(task);
                            return AnimatedContainer(
                              duration: Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.transparent,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Card(
                                elevation: isSelected ? 4 : 1,
                                color: isSelected ? Colors.green[50] : null,
                                child: CheckboxListTile(
                                  title: Text(task.description),
                                  subtitle: Text(
                                    task.isOneOff ? "One-off" : "Repeat",
                                  ),
                                  value: isSelected,
                                  onChanged: (selected) {
                                    setState(() {
                                      if (selected == true) {
                                        _selectedTasks.add(task);
                                      } else {
                                        _selectedTasks.remove(task);
                                      }
                                    });
                                  },
                                  selected: isSelected,
                                  controlAffinity:
                                      ListTileControlAffinity.leading,
                                  secondary: isSelected
                                      ? Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                        )
                                      : Icon(
                                          Icons.radio_button_unchecked,
                                          color: Colors.grey,
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _selectedTasks.isEmpty
                            ? null
                            : () async {
                                await widget.notesRef.add({
                                  'content': '', // or a summary
                                  'position': [100.0, 100.0],
                                  'flatRef': widget.flatRef,
                                  'createdBy': widget.userRef,
                                  'type': 'task',
                                  'tasks': _selectedTasks
                                      .map((t) => t.taskRef)
                                      .toList(),
                                });
                                Navigator.pop(context);
                              },
                        child: Text('Add Selected Tasks to Note'),
                      ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}


// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart' show StatelessWidget, Card, BuildContext, Widget, EdgeInsets, Colors, BorderRadius, RoundedRectangleBorder, CircularProgressIndicator, Center, SizedBox, CrossAxisAlignment, FontWeight, TextStyle, Text, TextAlign, Padding, Column, Expanded, Row, FutureBuilder;
// import 'package:frontend/models/task.dart';
// import 'package:intl/intl.dart';

class RoutineBoardWidget extends StatelessWidget {
  final DocumentReference flatRef;
  final DocumentReference userRef;
  const RoutineBoardWidget({super.key, required this.flatRef, required this.userRef});

  Future<Map<String, List<Task>>> _fetchRoutineTasks() async {
    final now = DateTime.now();
    final weekDays = List.generate(7, (i) => now.add(Duration(days: i)));

    final query = await FirebaseFirestore.instance
        .collection('Tasks')
        .where('assignedFlat', isEqualTo: flatRef)
        .where('isOneOff', isEqualTo: false)
        .where('isPersonal', isEqualTo: false)
        .get();

    final tasks = query.docs.map((doc) => Task.fromFirestore(doc)).toList();

    Map<String, List<Task>> weekTasks = {
      for (var d in weekDays) DateFormat('yyyy-MM-dd').format(d): []
    };

    for (final task in tasks) {
      DateTime lastDone = task.lastDoneOn != null
          ? DateFormat('yyyy-MM-dd').parse(task.lastDoneOn!)
          : DateFormat('yyyy-MM-dd').parse(task.setDate);
      DateTime nextDue = lastDone.add(Duration(days: task.frequency));

      if (nextDue.isBefore(weekDays[0])) {
        // Overdue: show on today
        weekTasks[DateFormat('yyyy-MM-dd').format(weekDays[0])]!.add(task);
      } else if (nextDue.isAfter(weekDays[6])) {
        // Due after this 7-day window: don't show
        continue;
      } else {
        // Due in next 7 days: show on correct day
        weekTasks[DateFormat('yyyy-MM-dd').format(nextDue)]!.add(task);
      }
    }
    return weekTasks;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekDays = List.generate(7, (i) => now.add(Duration(days: i)));

    return Card(
      elevation: 8,
      color: Colors.teal[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, List<Task>>>(
          future: _fetchRoutineTasks(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return SizedBox(
                  height: 200, child: Center(child: CircularProgressIndicator()));
            }
            final weekTasks = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Routine: Next 7 Days",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20, color: Colors.teal[900])),
                SizedBox(height: 8),
                // Row(
                //   crossAxisAlignment: CrossAxisAlignment.start,
                //   children: weekDays.map((d) {
                //     final dayStr = DateFormat('EEE\ndd/MM').format(d);
                //     final dateKey = DateFormat('yyyy-MM-dd').format(d);
                //     final tasks = weekTasks[dateKey] ?? [];
                //     return Expanded(
                //       child: Column(
                //         children: [
                //           Text(dayStr, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                //           ...tasks.map((t) => Padding(
                //                 padding: const EdgeInsets.symmetric(vertical: 2.0),
                //                 child: Text(
                //                   t.description,
                //                   style: TextStyle(fontSize: 12),
                //                   textAlign: TextAlign.center,
                //                 ),
                //               )),
                //         ],
                //       ),
                //     );
                //   }).toList(),
                // ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: List.generate(weekDays.length * 2 - 1, (i) {
                    if (i.isOdd) {
                      // Insert a divider between days
                      return Container(
                        width: 1,
                        height: 120,
                        color: Colors.grey[300],
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                      );
                    }
                    final d = weekDays[i ~/ 2];
                    final dayStr = DateFormat('EEE\ndd/MM').format(d);
                    final dateKey = DateFormat('yyyy-MM-dd').format(d);
                    final tasks = weekTasks[dateKey] ?? [];
                    return Expanded(
                      child: Column(
                        children: [
                          Text(dayStr, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                          ...tasks.map((t) => Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Text(
                                  t.description,
                                  style: TextStyle(fontSize: 12,
                                  fontWeight: t.assignedTo?.id == userRef.id
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  color: t.assignedTo?.id == userRef.id 
                                        ? Colors.teal[800]
                                        : const Color.fromARGB(255, 152, 152, 152),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
