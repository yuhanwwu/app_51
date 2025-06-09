import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/screens/task_page.dart';
import '../models/sticky_note.dart';

class NoticeboardPage extends StatefulWidget {
  final User user;
  final DocumentReference flatRef;
  const NoticeboardPage({super.key, required this.user, required this.flatRef});


  @override
  State<NoticeboardPage> createState() => _NoticeboardPageState();
}

class _NoticeboardPageState extends State<NoticeboardPage> {
  late CollectionReference notesRef;
  late DocumentReference userRef;
  String? flatName;
  
  @override
  void initState() {
    super.initState();
    notesRef = FirebaseFirestore.instance.collection('Noticeboard');
    userRef = FirebaseFirestore.instance.collection('Users').doc(widget.user.username);
    _loadFlatName();
  } 

  Future<void> _loadFlatName() async {
    final flatDoc = await widget.flatRef.get();
    setState(() {
      flatName = flatDoc['name'];
    });
  }

  void _addNote() async {
    final userDoc = await userRef.get();
    final flatRef = userDoc['flat'];
    await notesRef.add({
      'content': 'New Note',
      'position': [100.0, 100.0],
      'flatRef': flatRef,
      'createdBy': widget.user.username,
    });
  }

  void _updateNotePosition(String noteId, List<double> newPosition) {
    notesRef.doc(noteId).update({'position': newPosition});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${flatName ?? ''}'s Noticeboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment),
            tooltip: 'Go to Tasks',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TaskPage(user: widget.user),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add)),
      body: 
      StreamBuilder<QuerySnapshot>(
        stream: notesRef.where('flatRef', isEqualTo: widget.flatRef).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final notes = snapshot.data!.docs.map((doc) => StickyNote.fromFirestore(doc)).toList();

          return Stack(
            children: [
              ...notes.map((note) {
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: note.position[0],
                  top: note.position[1],
                  child: DraggableNote(
                    note: note,
                    onDragEnd: (offset) {
                      _updateNotePosition(note.id, [offset.dx, offset.dy]);
                    },
                  ),
                );
              }).toList(),
              Positioned(
                left: 32,
                bottom: 32,
                child: DragTarget<String>(
                  builder: (context, candidateData, rejectedData) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty ? Colors.red[300] : Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.delete, size: 40, color: Colors.black54),
                    );
                  },
                  onWillAcceptWithDetails: (noteId) => true,
                  onAcceptWithDetails: (details) async {
                    await notesRef.doc(details.data).delete();
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

  const DraggableNote({
    super.key,
    required this.note,
    required this.onDragEnd,
    this.onDragStarted,
    this.onDragCompleted,
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
        child: Container(
          width: 160,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.yellow[200],
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          padding: const EdgeInsets.all(12),
          child: Text(widget.note.content),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _noteWidget(),
      ),
      child: _noteWidget(),
      onDragStarted: widget.onDragStarted,
      onDragEnd: (details) {
        widget.onDragEnd(details.offset);
        widget.onDragCompleted?.call();
      },
    );
  }

  Widget _noteWidget() {
  return Material(
    elevation: 4,
    color: Colors.yellow[200],
    borderRadius: BorderRadius.circular(8),
    child: Container(
      width: 160,
      height: 120,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.note.content),
          const Spacer(),
          Text(
            'by ${widget.note.createdBy}',
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}
}