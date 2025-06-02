import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../models/flat.dart';
import 'home_page.dart';

class NudgeUserPage extends StatelessWidget {
  final User user;
  final Future<List<Task>> allFlatTasks;

  const NudgeUserPage({required this.user, required this.allFlatTasks, super.key});

  Future<List<Task>> fetchUserTasks(Future<List<Task>> allFlatTasks) async {
    final tasks = await allFlatTasks;
    return tasks.where((t) => t.assignedTo == user.userRef).toList();
    // Replace with actual fetch logic based on the user
    // return await getTasksForUser(user.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${user.name}'s Tasks")),
      body: FutureBuilder<List<Task>>(
        future: fetchUserTasks(allFlatTasks),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (snapshot.hasData) {
            final tasks = snapshot.data!;
            if (tasks.isEmpty) return const Center(child: Text("No tasks found."));
            return ListView(
              children: tasks.map((e) => ListTile(
                title: Text(e.description),
                subtitle: Text(e.isOneOff ? "One-off" : "Repeat"),
                trailing: IconButton(
                  icon: Icon(Icons.notifications_active),
                  tooltip: 'Nudge',
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('nudges').add({
                      'userId': user.username,       // or user.username if that's your doc ID
                      'taskId': e.taskId,
                      'timestamp': Timestamp.now(),
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Nudge sent to ${user.name}')),
                    );
                  },
                ),
              )).toList(),
            );
          } else {
            return const Center(child: Text("No tasks."));
          }
        },
      ),
    );
  }
}

Future<void> sendNudgeNotification(User user, Task task) async {
  // Assume you store the FCM token in the user document
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.username)
      .get();

  final token = userDoc['fcmToken'];

  // if (token != null) {
  //   await sendFCM(
  //     token: token,
  //     title: "Nudge: ${task.description}",
  //     body: "${user.name}, please check this task.",
  //   );
  // }
}