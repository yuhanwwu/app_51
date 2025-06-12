import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/flat_tasks.dart';
import 'package:frontend/screens/login.dart';
import 'package:intl/intl.dart';
import 'package:frontend/screens/notifications_page.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/flat.dart';
import 'add_task.dart';
import 'noticeboard.dart';
import 'nudge_user.dart';
import '../customWidgets/task_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_popup_card/flutter_popup_card.dart';
import '../constants/colors.dart';
import '../main.dart';

class TaskPage extends StatefulWidget {
  final FlatUser user;
  final VoidCallback onLogout;
  const TaskPage({Key? key, required this.user, required this.onLogout}) : super(key: key);

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  late final DocumentReference flatDoc;
  late final String username;
  late final String name;
  late final FlatUser user;
  late final DocumentReference userRef;
  late final bool questionnaireDone;
  late final Flat flat;
  late Future<List<Task>> _allFlatTasks;
  late Future<List<Task>> _userTasks;  // All tasks assigned to the user
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
    _loadEverything();
  }

  void _loadEverything() async {
    _loadTasks();
    flat = await _loadFlat();
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

  Future<Flat> _loadFlat() async {
    DocumentSnapshot flatSnap = await flatDoc.get();
    return Flat.fromFirestore(flatSnap);
  }

  void _loadTasks() async {
    setState(() {
      _allFlatTasks = fetchAllFlatTasks(flatDoc);
      _userTasks = fetchUserTasks(_allFlatTasks);
      _unclaimedTasks = fetchUnclaimedTasks(_allFlatTasks);
    });
  }

  Future<void> showRoutineCard(BuildContext context, flat) {
    return showPopupCard(
      context: context,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.5,
        widthFactor: 0.5,
        child: PopupCard(
          elevation: 8,
          color: AppColors.beige,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Container(child: getChoreAndFreqCol(flat)),
          ),
        ),
      ),
      alignment: Alignment.center,
      useSafeArea: true,
      dimBackground: true,
    );
  }

  Widget getChoreAndFreqCol(Flat flat) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cleaning the bathroom: ${flat.bathroom.toString()}'),
        Text('Doing the dishes: ${flat.dishes.toString()}'),
        Text('Cleaning the kitchen: ${flat.kitchen.toString()}'),
        Text('Doing laundry: ${flat.laundry.toString()}'),
        Text('Taking out recycling: ${flat.recycling.toString()}'),
        Text('Taking out the rubbish: ${flat.rubbish.toString()}'),
      ],
    );
  }

  Future<List<Task>> fetchUserTasks(Future<List<Task>> allFlatTasks) async {
    final tasks = await allFlatTasks;
    // Filter all tasks assigned to the current user and not done
    return tasks.where((t) => t.assignedTo == userRef && ((t.done ?? false) == false)).toList()
      ..sort((a, b) {
        // Prioritize by priority flag then setDate
        final priorityCompare = (b.priority ? 1 : 0) - (a.priority ? 1 : 0);
        if (priorityCompare != 0) return priorityCompare;

        if (a.setDate == null && b.setDate == null) return 0;
        if (a.setDate == null) return 1;
        if (b.setDate == null) return -1;

        return a.setDate!.compareTo(b.setDate!);
      });
  }

  Future<List<Task>> fetchUnclaimedTasks(Future<List<Task>> allFlatTasks) async {
    final tasks = await allFlatTasks;
    return tasks.where((t) => t.assignedTo == null && t.isOneOff).toList()
      ..sort((a, b) {
        final priorityCompare = (b.priority ? 1 : 0) - (a.priority ? 1 : 0);
        if (priorityCompare != 0) return priorityCompare;

        if (a.setDate == null && b.setDate == null) return 0;
        if (a.setDate == null) return 1;
        if (b.setDate == null) return -1;

        return a.setDate!.compareTo(b.setDate!);
      });
  }

  Future<List<Task>> fetchAllFlatTasks(DocumentReference flat) async {
    List<Task> allFlatTasks = [];
    final queryRef = FirebaseFirestore.instance.collection('Tasks').where("assignedFlat", isEqualTo: flat);
    final querySnap = await queryRef.get();
    if (querySnap.docs.isNotEmpty) {
      allFlatTasks = querySnap.docs.map((doc) {
        return Task.fromFirestore(doc);
      }).toList();
    }
    return allFlatTasks;
  }

  Future<List<Task>> fetchArchivedTasks() async {
    final allTasks = await _allFlatTasks;
    return allTasks.where((t) =>
      t.assignedTo == userRef &&
      (t.isOneOff || !t.isOneOff) &&
      (t.done ?? false)
    ).toList();
  }

  Future<List<FlatUser>> fetchAllUsers(DocumentReference flat) async {
    List<FlatUser> allUsers = [];
    final queryRef = FirebaseFirestore.instance.collection('Users').where('flat', isEqualTo: flat);
    final querySnap = await queryRef.get();
    if (querySnap.docs.isNotEmpty) {
      allUsers = querySnap.docs.map((doc) => FlatUser.fromFirestore(doc)).toList();
    }
    return allUsers;
  }

  void _showUnclaimedTasksModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: FutureBuilder<List<Task>>(
          future: _unclaimedTasks,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text("No unclaimed tasks left!"));
            } else {
              final unclaimedTasks = snapshot.data!;
              return ListView(
                children: unclaimedTasks.map((task) {
                  return TaskTile(
                    task: task,
                    user: user,
                    userRef: userRef,
                    onDone: _loadTasks,
                  );
                }).toList(),
              );
            }
          },
        ),
      ),
    );
  }

  void _showArchivedTasksModal() async {
    final archivedTasks = await fetchArchivedTasks();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Scaffold(
          appBar: AppBar(title: Text('Archived Tasks')),
          body: archivedTasks.isEmpty
              ? Center(child: Text('No archived tasks found.'))
              : ListView(
                  children: archivedTasks.map((task) {
                    return TaskTile(
                      task: task,
                      user: user,
                      userRef: userRef,
                      onDone: _loadTasks,
                    );
                  }).toList(),
                ),
        ),
      ),
    );
  }
  

  void _showOthersTasksModal() async {
    final allTasks = await _allFlatTasks;
    final othersTasks = allTasks.where((t) => t.assignedTo != null && t.assignedTo != userRef).toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8,
        child: Scaffold(
          appBar: AppBar(title: Text("Others' Tasks")),
          body: othersTasks.isEmpty
              ? Center(child: Text("No tasks assigned to others."))
              : ListView(
                  children: othersTasks.map((task) {
                    return TaskTile(
                      task: task,
                      user: user,
                      userRef: userRef,
                      onDone: _loadTasks,
                    );
                  }).toList(),
                ),
        ),
      ),
    );
  }

  void _showFlatmatesModal() async {
    final users = await fetchAllUsers(flatDoc);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: users.where((u) => u.username != user.username).map((u) {
          return ListTile(
            title: Text(u.name),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NudgeUserPage(user: u, allFlatTasks: _allFlatTasks),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome $name, here are your tasks.'),
      ),
      body: Row(
        children: [
          Container(
            width: 200,
            color: Colors.grey[100],
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add Task'),
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
                          child: TaskInputScreen(
                            curUser: user,
                            userRef: userRef,
                            onTaskSubmitted: _loadTasks,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.task_alt),
                    label: Text("View Others' Tasks"),
                    onPressed: _showOthersTasksModal,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.people),
                    label: Text('View Flatmates\' Tasks'),
                    onPressed: _showFlatmatesModal,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.inbox),
                    label: Text('Unclaimed Tasks'),
                    onPressed: _showUnclaimedTasksModal,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.archive),
                    label: Text('View Archive'),
                    onPressed: _showArchivedTasksModal,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.notifications),
                    label: Text('Notifications'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => NotificationsPage(username: username)),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.schedule),
                    label: Text('Show Routine'),
                    onPressed: () => showRoutineCard(context, flat),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh),
                    label: Text('Refresh'),
                    onPressed: _loadTasks,
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.sticky_note_2),
                    label: Text('Noticeboard'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoticeboardPage(
                            user: user,
                            flatRef: flatDoc,
                            userRef: userRef,
                            onLogout: widget.onLogout,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Logout'),
                    onTap: logout,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Task>>(
              future: _userTasks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (snapshot.hasData) {
                  final tasks = snapshot.data!;
                  if (tasks.isEmpty) {
                    return Center(child: Text("No tasks assigned to you."));
                  }
                  return ListView(
                    children: tasks.map((task) {
                      return TaskTile(
                        task: task,
                        user: user,
                        userRef: userRef,
                        onDone: _loadTasks,
                      );
                    }).toList(),
                  );
                } else {
                  return Center(child: Text("No tasks assigned to you."));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
