import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/flat_tasks.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/flat.dart';
import 'add_task.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final DocumentReference flatDoc;
  late final String username;
  late final String name;
  late final User user;
  late final bool questionnaireDone;
  late Future<List<Task>> _oneOffTasks;
  late Future<List<Task>> _repeatTasks;

  @override
  void initState() {
    super.initState();
    flatDoc = widget.user.flat;
    username = widget.user.username;
    name = widget.user.name;
    user = widget.user;
    questionnaireDone = widget.user.questionnaireDone;
    _oneOffTasks = fetchOneOffTasks(flatDoc);
    _repeatTasks = fetchRepeatTasks(flatDoc);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: Text('Welcome, $name')),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("One-Off Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: FutureBuilder<List<Task>>(
            future: _oneOffTasks,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (snapshot.hasData) {
                final oneOffTasks = snapshot.data!;
                if (oneOffTasks.isEmpty) return const Center(child: Text("No one-off tasks left!"));
                return ListView(
                  children: oneOffTasks.map((e) => ListTile(
                    title: Text(e.description),
                    subtitle: const Text("One off"),
                  )).toList(),
                );
              } else {
                return const Center(child: Text("No tasks left!"));
              }
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Repeat Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: FutureBuilder<List<Task>>(
            future: _repeatTasks,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Error: ${snapshot.error}"));
              } else if (snapshot.hasData) {
                final repeatTasks = snapshot.data!;
                if (repeatTasks.isEmpty) return const Center(child: Text("No repeat tasks left!"));
                return ListView(
                  children: repeatTasks.map((e) => ListTile(
                    title: Text(e.description),
                    subtitle: const Text("Repeat"),
                  )).toList(),
                );
              } else {
                return const Center(child: Text("No tasks left!"));
              }
            },
          ),
        ),
      ],
    ),
    bottomNavigationBar: Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16),
      child: Row(
  mainAxisAlignment: MainAxisAlignment.center, // horizontal alignment
  crossAxisAlignment: CrossAxisAlignment.center, // vertical alignment
  children: [
    ElevatedButton(onPressed: () {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true, // allow full height customization
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => FractionallySizedBox(
          heightFactor: 0.8, // 80% of the screen height
          child: TaskInputScreen(curUser: user), 
        ),
      );
      }, 
      child: Text('Add Task')),
  ],
)
      ),
    );
}


  Future<List<Task>> fetchOneOffTasks(DocumentReference flat) async {
    List<Task> oneOffTasks = [];
    print(flat);

    final queryRef = FirebaseFirestore.instance
        .collection('Tasks')
        .where("assignedFlat", isEqualTo: flat)
        .where("isOneOff", isEqualTo: true);

    final querySnap = await queryRef.get();

    if (querySnap.docs.isNotEmpty) {
      print("in one off tasks");
      oneOffTasks = querySnap.docs.map((doc) {
        final data = doc.data();
        return Task.fromFirestore(doc, isOneOff: true);
      }).toList();
    }
    print("end of one off tasks");
    return oneOffTasks;
  }

  Future<List<Task>> fetchRepeatTasks(DocumentReference flat) async {
    final queryRef = FirebaseFirestore.instance
        .collection('Tasks')
        .where("assignedFlat", isEqualTo: flat)
        .where("isOneOff", isEqualTo: false);

    final querySnap = await queryRef.get();

    if (querySnap.docs.isNotEmpty) {
      querySnap.docs.map((doc) {
        final data = doc.data();
        return Task.fromFirestore(doc, isOneOff: false);
      }).toList();
    }
    return [];
  }
}
