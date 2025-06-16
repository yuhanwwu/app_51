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
import 'dart:async';
import 'package:share_plus/share_plus.dart';

class TaskPage extends StatefulWidget {
  final FlatUser user;
  final VoidCallback onLogout;
  const TaskPage({super.key, required this.user, required this.onLogout});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  Timer? _taskRefreshTimer;
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
  final int _helpButtonPressCount = 0; // Add this field to your _TaskPageState
  int _unreadNotifications = 0;
  final GlobalKey sidebarKey = GlobalKey();
  final GlobalKey moreMenuKey = GlobalKey();

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
    _fetchUnreadNotifications();
    _startAutoTaskRefresh();
  }

  // CHANGE REFRESH RATE HERE SECONDS
  void _startAutoTaskRefresh() {
    _taskRefreshTimer = Timer.periodic(
      const Duration(seconds: 300),
      (_) => _loadEverything(),
    );
  }

  @override
  void dispose() {
    _taskRefreshTimer?.cancel();
    super.dispose();
  }

  void _loadEverything() async {
    _loadTasks();
    _fetchUnreadNotifications();
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

  Future<void> _fetchUnreadNotifications() async {
    final query = await FirebaseFirestore.instance
        .collection('Nudges')
        .where('userId', isEqualTo: username)
        .where('read', isEqualTo: false)
        .get();
    setState(() {
      _unreadNotifications = query.docs.length;
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
            child: FutureBuilder<DocumentSnapshot>(
            future: flatDoc.get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading routine.'));
              } else if (!snapshot.hasData || !snapshot.data!.exists) {
                return Center(child: Text('Routine not found.'));
              } else {
                final flat = Flat.fromFirestore(snapshot.data!);
                return getChoreAndFreqCol(flat);
              }
            },
          ),
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // horizontal alignment
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cleaning the bathroom: Every ${flat.bathroom.toString()} day(s)'),
        Text('Doing the dishes: Every ${flat.dishes.toString()} day(s)'),
        Text('Cleaning the kitchen: Every ${flat.kitchen.toString()} day(s)'),
        Text('Doing laundry: Every ${flat.laundry.toString()} day(s)'),
        Text('Taking out recycling: Every ${flat.recycling.toString()} day(s)'),
        Text('Taking out the rubbish: Every ${flat.rubbish.toString()} day(s)'),
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
        children: users.where((u) => u.username != user.username).where((u) => u.username != '${flat.name}_guest').map((u) {
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

// ...existing code...

void _showGuestLoginDialog() {
  final guestUsername = '${flat.name}_guest';
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Guest Username:'),
      content: Row(
        children: [
          Expanded(
            child: SelectableText(
              guestUsername,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy to clipboard',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: guestUsername));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Guest username copied!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share',
            onPressed: () {
              Share.share('Check out our Homely at https://yuhanwwu.github.io/app_51 using the guest username:\n\n$guestUsername');
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $name'),
      ),

      body: Row(
        children: [
          Padding(
            padding: EdgeInsetsGeometry.all(10),
            child: Container(
              key: sidebarKey, 
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
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.sticky_note_2, color: Color.fromARGB(255, 0, 0, 0)),
                          label: Text(
                            'Flat Noticeboard',
                            style: TextStyle(
                              color: Color.fromARGB(255, 11, 132, 0),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color.fromARGB(255, 11, 132, 0), width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white,
                          ),
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
                      ),
                      const SizedBox(height: 16),
                      sidebarAddTaskButton(),
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.people),
                          label: Text('Nudge Flatmates\' Tasks'),
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
                          icon: Stack(
                            children: [
                              Icon(Icons.notifications),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('Nudges')
                                    .where('userId', isEqualTo: username)
                                    .where('read', isEqualTo: false)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  int unread = 0;
                                  if (snapshot.hasData) {
                                    unread = snapshot.data!.docs.length;
                                  }
                                  if (unread == 0) return SizedBox.shrink();
                                  return Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '$unread',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          label: Text('Notifications'),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotificationsPage(username: username),
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
                      const SizedBox(height: 8),
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.person_search),
                          label: Text('Get Guest Login Details'),
                          onPressed: _showGuestLoginDialog,
                        ),
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
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "Your Tasks",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          children: tasks.map((task) {
                            return TaskTile(
                              task: task,
                              user: user,
                              userRef: userRef,
                              onDone: _loadTasks,
                            );
                          }).toList(),
                        ),
                      ),
                    ],
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
