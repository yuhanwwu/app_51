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
  // const HomePage({super.key, required this.user});
  const TaskPage({super.key, required this.user, required this.onLogout});

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
  late Future<List<Task>> _userOneOffTasks;
  late Future<List<Task>> _repeatTasks;
  late Future<List<Task>> _allFlatTasks;
  late Future<List<Task>> _unclaimedTasks;
  List<Task> _userTasks = [];

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
    final allTasks = await fetchAllFlatTasks(flatDoc);
    setState(() {
      _allFlatTasks = fetchAllFlatTasks(flatDoc);
      _userTasks = allTasks.where((t) => t.assignedTo == userRef && !(t.done ?? false))
          .toList();
      _userOneOffTasks = fetchUserOneOffTasks(_allFlatTasks);
      _repeatTasks = fetchRepeatTasks(_allFlatTasks);
      _unclaimedTasks = fetchUnclaimedTasks(_allFlatTasks);
    });
  }

  void _showUnclaimedTasks(BuildContext context) async {
    final tasks = await fetchAllFlatTasks(flatDoc);
    final unclaimed = tasks
        .where((t) => t.assignedTo == null && t.isOneOff)
        .toList();

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
          appBar: AppBar(title: Text("Unclaimed Tasks")),
          body: unclaimed.isEmpty
              ? Center(child: Text("No unclaimed tasks."))
              : ListView(
                  children: unclaimed
                      .map((task) => TaskTile(
                            task: task,
                            user: user,
                            userRef: userRef,
                            onDone: _loadEverything,
                          ))
                      .toList(),
                ),
        ),
      ),
    );
  }

  // void _showOthersTasks(BuildContext context) async {
  //   final allTasks = await fetchAllFlatTasks(flatDoc);
  //   final others = allTasks
  //       .where((t) => t.assignedTo != null && t.assignedTo != userRef && !t.isOneOff)
  //       .toList();

  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.white,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //     ),
  //     builder: (context) => FractionallySizedBox(
  //       heightFactor: 0.8,
  //       child: Scaffold(
  //         appBar: AppBar(title: Text("Others' Repeat Tasks")),
  //         body: others.isEmpty
  //             ? Center(child: Text("No repeat tasks assigned to others."))
  //             : ListView(
  //                 children: others
  //                     .map((task) => TaskTile(
  //                           task: task,
  //                           user: user,
  //                           userRef: userRef,
  //                           onDone: _loadEverything,
  //                         ))
  //                     .toList(),
  //               ),
  //       ),
  //     ),
  //   );
  // }

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
      //offset: const Offset(-16, 70),
      alignment: Alignment.center,
      useSafeArea: true,
      dimBackground: true,
    );
  }
  void _showAddTaskScreen(BuildContext context) {
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
          onTaskSubmitted: _loadEverything,
        ),
      ),
    );
  }

  void _showFlatmates(BuildContext context) async {
    final users = await fetchAllUsers(flatDoc);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        children: users
            .where((u) => u.username != user.username)
            .map((u) => ListTile(
                  title: Text(u.name),
                  onTap: () {
                    Navigator.pop(context);
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
                ))
            .toList(),
      ),
    );
  }

  Widget getChoreAndFreqCol(Flat flat) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly, // horizontal alignment
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

  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('Welcome, $name'),
  //       actions: [
  //         logoutButton(),
  //         TextButton(
  //           onPressed: () {
  //             showRoutineCard(context, flat);
  //           },
  //           child: Text('Show Routine', style: TextStyle(color: Colors.black)),
  //         ),
  //         StreamBuilder<QuerySnapshot>(
  //           stream: FirebaseFirestore.instance
  //               .collection('Nudges')
  //               .where('userId', isEqualTo: username)
  //               .where('read', isEqualTo: false)
  //               .snapshots(),
  //           builder: (context, snapshot) {
  //             int unreadCount = 0;
  //             if (snapshot.hasData) {
  //               unreadCount = snapshot.data!.docs.length;
  //             }
  //             return Stack(
  //               children: [
  //                 IconButton(
  //                   icon: Icon(Icons.notifications),
  //                   tooltip: 'Notifications',
  //                   onPressed: () {
  //                     Navigator.push(
  //                       context,
  //                       MaterialPageRoute(
  //                         builder: (context) =>
  //                             NotificationsPage(username: username),
  //                       ),
  //                     );
  //                   },
  //                 ),
  //                 if (unreadCount > 0)
  //                   Positioned(
  //                     right: 8,
  //                     top: 8,
  //                     child: Container(
  //                       padding: const EdgeInsets.all(2),
  //                       decoration: BoxDecoration(
  //                         color: Colors.red,
  //                         borderRadius: BorderRadius.circular(10),
  //                       ),
  //                       constraints: const BoxConstraints(
  //                         minWidth: 16,
  //                         minHeight: 16,
  //                       ),
  //                       child: Text(
  //                         unreadCount.toString(),
  //                         style: const TextStyle(
  //                           color: Colors.white,
  //                           fontSize: 10,
  //                         ),
  //                         textAlign: TextAlign.center,
  //                       ),
  //                     ),
  //                   ),
  //               ],
  //             );
  //           },
  //         ),
  //         IconButton(
  //           icon: Icon(Icons.refresh),
  //           tooltip: 'Refresh page',
  //           onPressed: () {
  //             _loadTasks();
  //           },
  //         ),
  //       ],
  //     ),
  //     body: Column(
  //       children: [
  //         Expanded(
  //           child: Row(
  //             mainAxisAlignment:
  //                 MainAxisAlignment.spaceEvenly, // horizontal alignment
  //             crossAxisAlignment:
  //                 CrossAxisAlignment.center, // vertical alignment
  //             children: [
  //               Expanded(
  //                 child: Column(
  //                   children: [
  //                     Padding(
  //                       padding: const EdgeInsets.all(8.0),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: [
  //                           Text(
  //                             "One-Off Tasks",
  //                             style: TextStyle(
  //                               fontSize: 18,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                           TextButton(
  //                             onPressed: () async {
  //                               final allTasks = await _allFlatTasks;
  //                               final archivedTasks = allTasks
  //                                   .where(
  //                                     (t) =>
  //                                         t.assignedTo == userRef &&
  //                                         t.isOneOff &&
  //                                         (t.done ?? false),
  //                                   )
  //                                   .toList();
  //                               // ..sort((a, b) => b.setDate?.compareTo(a.setDate ?? DateTime(0)) ?? 0);

  //                               showModalBottomSheet(
  //                                 context: context,
  //                                 isScrollControlled: true,
  //                                 backgroundColor: Colors.white,
  //                                 shape: RoundedRectangleBorder(
  //                                   borderRadius: BorderRadius.vertical(
  //                                     top: Radius.circular(20),
  //                                   ),
  //                                 ),
  //                                 builder: (context) => FractionallySizedBox(
  //                                   heightFactor: 0.8,
  //                                   child: Scaffold(
  //                                     appBar: AppBar(
  //                                       title: Text('Archived One-Off Tasks'),
  //                                     ),
  //                                     body: archivedTasks.isEmpty
  //                                         ? Center(
  //                                             child: Text(
  //                                               'No archived tasks found.',
  //                                             ),
  //                                           )
  //                                         : ListView(
  //                                             children: archivedTasks.map((
  //                                               task,
  //                                             ) {
  //                                               return TaskTile(
  //                                                 task: task,
  //                                                 user: user,
  //                                                 userRef: userRef,
  //                                                 onDone: _loadTasks,
  //                                                 // disableDone: true, // You can customize TaskTile to handle this
  //                                               );
  //                                             }).toList(),
  //                                           ),
  //                                   ),
  //                                 ),
  //                               );
  //                             },
  //                             child: Text("View Archive"),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                     Expanded(
  //                       child: FutureBuilder<List<Task>>(
  //                         future: _userOneOffTasks,
  //                         builder: (context, snapshot) {
  //                           if (snapshot.connectionState ==
  //                               ConnectionState.waiting) {
  //                             return const Center(
  //                               child: CircularProgressIndicator(),
  //                             );
  //                           } else if (snapshot.hasError) {
  //                             return Center(
  //                               child: Text("Error: ${snapshot.error}"),
  //                             );
  //                           } else if (snapshot.hasData) {
  //                             final oneOffTasks = snapshot.data!;
  //                             if (oneOffTasks.isEmpty) {
  //                               return const Center(
  //                                 child: Text("No one-off tasks left!"),
  //                               );
  //                             }
  //                             return ListView(
  //                               children: oneOffTasks
  //                                   .map(
  //                                     (e) => TaskTile(
  //                                       task: e,
  //                                       user: user,
  //                                       userRef: userRef,
  //                                       onDone: _loadTasks,
  //                                     ),
  //                                   )
  //                                   .toList(),
  //                             );
  //                           } else {
  //                             return const Center(
  //                               child: Text("No tasks left!"),
  //                             );
  //                           }
  //                         },
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),

  //               Expanded(
  //                 child: Column(
  //                   children: [
  //                     Padding(
  //                       padding: const EdgeInsets.all(8.0),
  //                       child: Row(
  //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                         children: [
  //                           Text(
  //                             "Repeat Tasks",
  //                             style: TextStyle(
  //                               fontSize: 18,
  //                               fontWeight: FontWeight.bold,
  //                             ),
  //                           ),
  //                           TextButton(
  //                             onPressed: () async {
  //                               final allTasks = await _allFlatTasks;
  //                               final othersRepeatTasks = allTasks
  //                                   .where(
  //                                     (t) =>
  //                                         !t.isOneOff &&
  //                                         t.assignedTo != null &&
  //                                         t.assignedTo != userRef,
  //                                   )
  //                                   .toList();

  //                               showModalBottomSheet(
  //                                 context: context,
  //                                 isScrollControlled: true,
  //                                 backgroundColor: Colors.white,
  //                                 shape: RoundedRectangleBorder(
  //                                   borderRadius: BorderRadius.vertical(
  //                                     top: Radius.circular(20),
  //                                   ),
  //                                 ),
  //                                 builder: (context) => FractionallySizedBox(
  //                                   heightFactor: 0.8,
  //                                   child: Scaffold(
  //                                     appBar: AppBar(
  //                                       title: Text("Others' Repeat Tasks"),
  //                                     ),
  //                                     body: othersRepeatTasks.isEmpty
  //                                         ? Center(
  //                                             child: Text(
  //                                               "No repeat tasks assigned to others.",
  //                                             ),
  //                                           )
  //                                         : ListView(
  //                                             children: othersRepeatTasks.map((
  //                                               task,
  //                                             ) {
  //                                               return TaskTile(
  //                                                 task: task,
  //                                                 user: user,
  //                                                 userRef: userRef,
  //                                                 onDone: _loadTasks,
  //                                                 // You could add: disableDone: true
  //                                               );
  //                                             }).toList(),
  //                                           ),
  //                                   ),
  //                                 ),
  //                               );
  //                             },
  //                             child: Text("View Others' Tasks"),
  //                           ),
  //                         ],
  //                       ),
  //                     ),

  //                     Expanded(
  //                       child: FutureBuilder<List<Task>>(
  //                         future: _repeatTasks,
  //                         builder: (context, snapshot) {
  //                           if (snapshot.connectionState ==
  //                               ConnectionState.waiting) {
  //                             return const Center(
  //                               child: CircularProgressIndicator(),
  //                             );
  //                           } else if (snapshot.hasError) {
  //                             return Center(
  //                               child: Text("Error: ${snapshot.error}"),
  //                             );
  //                           } else if (snapshot.hasData) {
  //                             final repeatTasks = snapshot.data!;
  //                             if (repeatTasks.isEmpty) {
  //                               return const Center(
  //                                 child: Text("No repeat tasks left!"),
  //                               );
  //                             }
  //                             return ListView(
  //                               children: repeatTasks
  //                                   .where((e) => e.assignedTo == userRef)
  //                                   .map(
  //                                     (e) => TaskTile(
  //                                       task: e,
  //                                       user: user,
  //                                       userRef: userRef,
  //                                       onDone: _loadTasks,
  //                                     ),
  //                                   )
  //                                   .toList(),
  //                             );
  //                           } else {
  //                             return const Center(
  //                               child: Text("No tasks left!"),
  //                             );
  //                           }
  //                         },
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         Expanded(
  //           child: Column(
  //             children: [
  //               Padding(
  //                 padding: const EdgeInsets.all(8.0),
  //                 child: Text(
  //                   "Unclaimed Tasks",
  //                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //                 ),
  //               ),
  //               Expanded(
  //                 child: FutureBuilder<List<Task>>(
  //                   future: _unclaimedTasks,
  //                   builder: (context, snapshot) {
  //                     if (snapshot.connectionState == ConnectionState.waiting) {
  //                       return const Center(child: CircularProgressIndicator());
  //                     } else if (snapshot.hasError) {
  //                       return Center(child: Text("Error: ${snapshot.error}"));
  //                     } else if (snapshot.hasData) {
  //                       final repeatTasks = snapshot.data!;
  //                       if (repeatTasks.isEmpty) {
  //                         return const Center(
  //                           child: Text("No unclaimed tasks left!"),
  //                         );
  //                       }
  //                       return ListView(
  //                         children: repeatTasks
  //                             .map(
  //                               (e) => TaskTile(
  //                                 task: e,
  //                                 user: user,
  //                                 userRef: userRef,
  //                                 onDone: _loadTasks,
  //                               ),
  //                             )
  //                             .toList(),
  //                       );
  //                     } else {
  //                       return const Center(
  //                         child: Text("No unclaimed tasks left!"),
  //                       );
  //                     }
  //                   },
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ],
  //     ),
  //     bottomNavigationBar: Container(
  //       color: Colors.grey[200],
  //       padding: const EdgeInsets.all(16),
  //       child: Row(
  //         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         crossAxisAlignment: CrossAxisAlignment.center,
  //         children: [
  //           ElevatedButton(
  //             onPressed: () {
  //               showModalBottomSheet(
  //                 context: context,
  //                 isScrollControlled: true,
  //                 backgroundColor: Colors.white,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.vertical(
  //                     top: Radius.circular(20),
  //                   ),
  //                 ),
  //                 builder: (context) => FractionallySizedBox(
  //                   heightFactor: 0.8,
  //                   child: TaskInputScreen(
  //                     curUser: user,
  //                     userRef: userRef,
  //                     onTaskSubmitted: _loadTasks,
  //                   ),
  //                 ),
  //               );
  //             },
  //             child: Text('Add Task'),
  //           ),
  //           ElevatedButton(
  //             onPressed: () async {
  //               final users = await fetchAllUsers(
  //                 flatDoc,
  //               ); // You need to define this function
  //               showModalBottomSheet(
  //                 context: context,
  //                 backgroundColor: Colors.white,
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.vertical(
  //                     top: Radius.circular(20),
  //                   ),
  //                 ),
  //                 builder: (context) => ListView(
  //                   shrinkWrap: true,
  //                   children: users
  //                       .where((u) => u.username != user.username)
  //                       .map(
  //                         (u) => ListTile(
  //                           title: Text(u.name),
  //                           onTap: () {
  //                             Navigator.pop(context); // Close the sheet
  //                             Navigator.push(
  //                               context,
  //                               MaterialPageRoute(
  //                                 builder: (context) => NudgeUserPage(
  //                                   user: u,
  //                                   allFlatTasks: _allFlatTasks,
  //                                 ),
  //                               ),
  //                             );
  //                           },
  //                         ),
  //                       )
  //                       .toList(),
  //                 ),
  //               );
  //             },
  //             child: Text('View Flatmates\' Tasks'),
  //           ),
            
  //         ],
  //       ),
  //     ),
  //   );
  // }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 200,
            color: Colors.grey[200],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () => _showAddTaskScreen(context),
                  child: Text("Add Task"),
                ),
                ElevatedButton(
                  onPressed: () => _showUnclaimedTasks(context),
                  child: Text("Unclaimed Tasks"),
                ),
                // ElevatedButton(
                //   onPressed: () => _showOthersTasks(context),
                //   child: Text("View Others' Tasks"),
                // ),
                ElevatedButton(
                  onPressed: () => _showFlatmates(context),
                  child: Text("View Flatmates"),
                ),
                logoutButton(),
              ],
            ),
          ),

          // Main Task List
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    "Your Tasks",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _userTasks.isEmpty
                        ? Center(child: Text("No tasks assigned to you."))
                        : ListView(
                            children: _userTasks
                                .map((task) => TaskTile(
                                      task: task,
                                      user: user,
                                      userRef: userRef,
                                      onDone: _loadEverything,
                                    ))
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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

  Future<List<FlatUser>> fetchAllUsers(DocumentReference flat) async {
    List<FlatUser> allUsers = [];
    final queryRef = FirebaseFirestore.instance
        .collection('Users')
        .where('flat', isEqualTo: flat);
    final querySnap = await queryRef.get();
    if (querySnap.docs.isNotEmpty) {
      allUsers = querySnap.docs.map((doc) {
        return FlatUser.fromFirestore(doc);
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
        return Task.fromFirestore(doc);
      }).toList();
    }
    return allFlatTasks;
  }

  Future<List<Task>> fetchUserOneOffTasks(
    Future<List<Task>> allFlatTasks,
  ) async {
    final tasks = await allFlatTasks;
    return tasks
        .where(
          (t) =>
              (t.assignedTo == userRef) &&
              (t.isOneOff) &&
              ((t.done ?? false) ? false : true),
        )
        .toList()
      ..sort((a, b) {
        final priorityCompare = (b.priority ? 1 : 0) - (a.priority ? 1 : 0);
        if (priorityCompare != 0) return priorityCompare;

        if (a.setDate == null && b.setDate == null) return 0; // 🚀 a comes before

        return a.setDate.compareTo(b.setDate);
      });
  }

  Future<List<Task>> fetchRepeatTasks(Future<List<Task>> allFlatTasks) async {
    final tasks = await allFlatTasks;
    final now = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return tasks.where((t) => !t.isOneOff).toList()..sort((a, b) {
      DateTime parseDate(String? dateStr) {
        try {
          return dateStr != null
              ? DateFormat('yyyy-MM-dd').parse(dateStr)
              : DateTime(2000);
        } catch (_) {
          return DateTime(2000);
        }
      }

      DateTime aLastDone = a.lastDoneOn != null
          ? DateFormat('yyyy-MM-dd').parse(a.lastDoneOn!)
          : parseDate(a.setDate);
      DateTime bLastDone = b.lastDoneOn != null
          ? DateFormat('yyyy-MM-dd').parse(b.lastDoneOn!)
          : parseDate(b.setDate);
      DateTime aExpected = aLastDone.add(Duration(days: a.frequency));
      DateTime bExpected = bLastDone.add(Duration(days: b.frequency));
      return aExpected.compareTo(bExpected);
    });
  }

  Future<List<Task>> fetchUnclaimedTasks(
    Future<List<Task>> allFlatTasks,
  ) async {
    final tasks = await allFlatTasks;
    return tasks.where((t) => (t.assignedTo == null && t.isOneOff)).toList()
      ..sort((a, b) {
        final priorityCompare = (b.priority ? 1 : 0) - (a.priority ? 1 : 0);
        if (priorityCompare != 0) return priorityCompare;

        if (a.setDate == null && b.setDate == null) return 0; // 🚀 a comes before

        return a.setDate.compareTo(b.setDate);
      });
  }
}
