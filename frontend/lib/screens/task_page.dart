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
import 'package:shared_preferences/shared_preferences.dart';


class TaskPage extends StatefulWidget {
  final FlatUser user;
  final VoidCallback onLogout;
  const TaskPage({Key? key, required this.user, required this.onLogout})
    : super(key: key);

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
  late Future<List<Task>> _userTasks; // All tasks assigned to the user
  late Future<List<Task>> _unclaimedTasks;
  int _helpButtonPressCount = 0; // Add this field to your _TaskPageState

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
    _showTutorialIfFirstTime();
  }
  
  // Move your tutorial dialog code into a separate method for reuse:
  Future<void> _showTutorialDialog() async {
    final prefs = await SharedPreferences.getInstance();
    // Increment the counter
    _helpButtonPressCount = (prefs.getInt('helpButtonPressCount_${user.username}') ?? 0) + 1;
    await prefs.setInt('helpButtonPressCount_${user.username}', _helpButtonPressCount);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Welcome to the Task Page!'),
        content: Text(
          'Here you can manage your tasks, view flatmates\' tasks, and more. '
          'Use the buttons on the left to navigate. Here\'s what you can do: \n'
          ' • Add Task: Create a new task for yourself or others.\n'
          ' • View Flatmates\' Tasks: View all tasks assigned to flatmates, and nudge them.\n'
          ' • Unclaimed Tasks: Pick up tasks that aren\'t assigned to anyone.\n'
          ' • View Archive: Check tasks you have completed.\n'
          ' • Notifications: View notifications related to tasks.\n'
          ' • Show Routine: View the cleaning schedule for your flat.\n'
          ' • Refresh: Reload the tasks to see any updates.\n'
          ' • Noticeboard: Post or view notices for your flat.\n'
          ' • Logout: Sign out of your account.\n'
          'You can also click on tasks to mark them as done or to edit them/see more information. '
          'Click on the help icon in the top right corner to see this tutorial again.'
          '$_helpButtonPressCount',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Future<void> _showTutorialIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('hasSeenTaskTutorial_${user.username}') ?? false;

    if (!hasSeenTutorial) {
      await _showTutorialDialog();
      await prefs.setBool('hasSeenTaskTutorial_${user.username}', true);
    }
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
          color: AppColors.background,
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
    return tasks
        .where((t) => t.assignedTo == userRef && ((t.done ?? false) == false))
        .toList()
      ..sort((a, b) {
        // Prioritize by priority flag then setDate
        final priorityCompare = (b.priority ? 1 : 0) - (a.priority ? 1 : 0);
        if (priorityCompare != 0) return priorityCompare;

        if (a.setDate == null && b.setDate == null) return 0;

        return a.setDate.compareTo(b.setDate);
      });
  }

  Future<List<Task>> fetchUnclaimedTasks(
    Future<List<Task>> allFlatTasks,
  ) async {
    final tasks = await allFlatTasks;
    return tasks.where((t) => t.assignedTo == null && t.isOneOff).toList()
      ..sort((a, b) {
        final priorityCompare = (b.priority ? 1 : 0) - (a.priority ? 1 : 0);
        if (priorityCompare != 0) return priorityCompare;

        if (a.setDate == null && b.setDate == null) return 0;

        return a.setDate.compareTo(b.setDate);
      });
  }

  Future<List<Task>> fetchAllFlatTasks(DocumentReference flat) async {
    List<Task> allFlatTasks = [];
    final queryRef = FirebaseFirestore.instance
        .collection('Tasks')
        .where("assignedFlat", isEqualTo: flat);
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
    return allTasks
        .where(
          (t) =>
              t.assignedTo == userRef &&
              (t.isOneOff || !t.isOneOff) &&
              (t.done ?? false),
        )
        .toList();
  }

  Future<List<FlatUser>> fetchAllUsers(DocumentReference flat) async {
    List<FlatUser> allUsers = [];
    final queryRef = FirebaseFirestore.instance
        .collection('Users')
        .where('flat', isEqualTo: flat);
    final querySnap = await queryRef.get();
    if (querySnap.docs.isNotEmpty) {
      allUsers = querySnap.docs
          .map((doc) => FlatUser.fromFirestore(doc))
          .toList();
    }
    return allUsers;
  }

  void _showUnclaimedTasksModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
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
      backgroundColor: AppColors.background,
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
    final othersTasks = allTasks
        .where((t) => t.assignedTo != null && t.assignedTo != userRef)
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
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
      backgroundColor: AppColors.background,
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
                  builder: (context) =>
                      NudgeUserPage(user: u, allFlatTasks: _allFlatTasks),
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget sidebarAddTaskButton() {
    return FractionallySizedBox(
      widthFactor: 1,
      child: ElevatedButton.icon(
        icon: Icon(Icons.add),
        label: Text('Add Task'),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: AppColors.background,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome, $name'),
      actions: [
          IconButton(
            icon: Icon(Icons.help_outline),
            tooltip: 'Show Tutorial',
            onPressed: _showTutorialDialog,
          ),
        ],),
      
      body: Row(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.all(10),
            child: Container(
              width: 200,
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(70),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary,
                    offset: Offset(0, 0),
                    blurRadius: 4.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      sidebarAddTaskButton(),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.task_alt),
                          label: Text("View Others' Tasks"),
                          onPressed: _showOthersTasksModal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.people),
                          label: Text('View Flatmates\' Tasks'),
                          onPressed: _showFlatmatesModal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.inbox),
                          label: Text('Unclaimed Tasks'),
                          onPressed: _showUnclaimedTasksModal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.archive),
                          label: Text('View Archive'),
                          onPressed: _showArchivedTasksModal,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.notifications),
                          label: Text('Notifications'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    NotificationsPage(username: username),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.schedule),
                          label: Text('Show Routine'),
                          onPressed: () => showRoutineCard(context, flat),
                        ),
                      ),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.refresh),
                          label: Text('Refresh'),
                          onPressed: _loadTasks,
                        ),
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
