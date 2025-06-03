import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/flat_tasks.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/flat.dart';
import 'add_task.dart';
import 'nudge_user.dart';
import '../customWidgets/task_tile.dart';

class HomePage extends StatefulWidget {
  final User user;
  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final DocumentReference flatDoc;
  late final String username;
  late final String name;
  late final User user;
  late final DocumentReference userRef;
  late final bool questionnaireDone;
  late Future<List<Task>> _userOneOffTasks;
  late Future<List<Task>> _repeatTasks;
  late Future<List<Task>> _allFlatTasks;
  late Future<List<Task>> _unclaimedTasks;

  @override
  void initState() {
    super.initState();
    userRef = widget.user.userRef;
    flatDoc = widget.user.flat;
    username = widget.user.username;
    name = widget.user.name;
    user = widget.user;
    questionnaireDone = widget.user.questionnaireDone;
    _loadTasks();
  }

  void _loadTasks() async {
    setState(() {
      _allFlatTasks = fetchAllFlatTasks(flatDoc);
      _userOneOffTasks = fetchUserOneOffTasks(_allFlatTasks);
      _repeatTasks = fetchRepeatTasks(_allFlatTasks);
      _unclaimedTasks = fetchUnclaimedTasks(_allFlatTasks);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome, $name')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // horizontal alignment
              crossAxisAlignment:
                  CrossAxisAlignment.center, // vertical alignment
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "One-Off Tasks",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<List<Task>>(
                          future: _userOneOffTasks,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text("Error: ${snapshot.error}"),
                              );
                            } else if (snapshot.hasData) {
                              final oneOffTasks = snapshot.data!;
                              if (oneOffTasks.isEmpty)
                                return const Center(
                                  child: Text("No one-off tasks left!"),
                                );
                              return ListView(
                                children: oneOffTasks
                                    .map(
                                      (e) => TaskTile(
                                        task: e,
                                        userRef: userRef,
                                        onDone: _loadTasks,
                                      ),
                                    )
                                    .toList(),
                              );
                            } else {
                              return const Center(
                                child: Text("No tasks left!"),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Repeat Tasks",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<List<Task>>(
                          future: _repeatTasks,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                child: Text("Error: ${snapshot.error}"),
                              );
                            } else if (snapshot.hasData) {
                              final repeatTasks = snapshot.data!;
                              if (repeatTasks.isEmpty) {
                                return const Center(
                                  child: Text("No repeat tasks left!"),
                                );
                              }
                              return ListView(
                                children: repeatTasks
                                    .map(
                                      (e) => TaskTile(
                                        task: e,
                                        userRef: userRef,
                                        onDone: _loadTasks,
                                      ),
                                    )
                                    .toList(),
                              );
                            } else {
                              return const Center(
                                child: Text("No tasks left!"),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Unclaimed tasks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Task>>(
                    future: _unclaimedTasks,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      } else if (snapshot.hasData) {
                        final repeatTasks = snapshot.data!;
                        if (repeatTasks.isEmpty) {
                          return const Center(
                            child: Text("No unclaimed tasks left!"),
                          );
                        }
                        return ListView(
                          children: repeatTasks
                              .map(
                                (e) => TaskTile(
                                  task: e,
                                  userRef: userRef,
                                  onDone: _loadTasks,
                                ),
                              )
                              .toList(),
                        );
                      } else {
                        return const Center(
                          child: Text("No unclaimed tasks left!"),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
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
                    child: TaskInputScreen(curUser: user, userRef: userRef, onTaskSubmitted: _loadTasks),
                  ),
                );
              },
              child: Text('Add Task'),
            ),
            ElevatedButton(
              onPressed: () async {
                final users = await fetchAllUsers(
                  flatDoc,
                ); // You need to define this function
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  builder: (context) => ListView(
                    shrinkWrap: true,
                    children: users
                        .where((u) => u.username != user.username)
                        .map(
                          (u) => ListTile(
                            title: Text(u.name),
                            onTap: () {
                              Navigator.pop(context); // Close the sheet
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NudgeUserPage(
                                    user: u,
                                    allFlatTasks: _allFlatTasks,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  ),
                );
              },
              child: Text('View Flatmates\' Tasks'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<User>> fetchAllUsers(DocumentReference flat) async {
    List<User> allUsers = [];
    final queryRef = FirebaseFirestore.instance
        .collection('Users')
        .where('flat', isEqualTo: flat);
    final querySnap = await queryRef.get();
    if (querySnap.docs.isNotEmpty) {
      // print("in flat tasks");
      allUsers = querySnap.docs.map((doc) {
        return User.fromFirestore(doc);
      }).toList();
    }
    return allUsers;
  }

  Future<List<Task>> fetchAllFlatTasks(DocumentReference flat) async {
    List<Task> allFlatTasks = [];

    final queryRef = FirebaseFirestore.instance
        .collection('Tasks')
        .where("assignedFlat", isEqualTo: flat);

    final querySnap = await queryRef.get();

    if (querySnap.docs.isNotEmpty) {
      allFlatTasks = querySnap.docs.map((doc) {
        final data = doc.data();
        return Task.fromFirestore(doc, isOneOff: true);
      }).toList();
    }
    return allFlatTasks;
  }

  // Future<List<Task>> fetchOneOffTasks(Future<List<Task>> allFlatTasks) async {
  //   final tasks = await allFlatTasks;
  //   return tasks.where((t) => t.isOneOff).toList();
  // }

  Future<List<Task>> fetchUserOneOffTasks(
    Future<List<Task>> allFlatTasks,
  ) async {
    final tasks = await allFlatTasks;
    return tasks.where((t) => t.assignedTo == userRef && t.isOneOff).toList();
  }

  Future<List<Task>> fetchRepeatTasks(Future<List<Task>> allFlatTasks) async {
    final tasks = await allFlatTasks;
    return tasks.where((t) => !t.isOneOff).toList();
  }

  Future<List<Task>> fetchUnclaimedTasks(
    Future<List<Task>> allFlatTasks,
  ) async {
    final tasks = await allFlatTasks;
    return tasks.where((t) => (t.assignedTo == null && t.isOneOff)).toList();
  }
}
