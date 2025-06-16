import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user.dart';

class NudgeUserPage extends StatelessWidget {
  final FlatUser user;
  final Future<List<Task>> allFlatTasks;

  const NudgeUserPage({
    required this.user,
    required this.allFlatTasks,
    super.key,
  });

  Future<List<Task>> fetchUserTasks(Future<List<Task>> allFlatTasks) async {
    final tasks = await allFlatTasks;
    return tasks.where((t) => t.assignedTo == user.userRef).toList();
    // Replace with actual fetch logic based on the user
    // return await getTasksForUser(user.id);
  }

Future<void> adjustTaskFrequencyIfNeeded(DocumentReference flatRef, String taskType, {int nudgeThreshold = 3}) async {
  final oneWeekAgo = DateTime.now().subtract(Duration(days: 7));
  final nudgesQuery = await FirebaseFirestore.instance
      .collection('Nudges')
      .where('flatRef', isEqualTo: flatRef)
      .where('taskType', isEqualTo: taskType)
      .where('timestamp', isGreaterThan: Timestamp.fromDate(oneWeekAgo))
      .where('counted', isEqualTo: false)
      .get();

  final nudgeCount = nudgesQuery.docs.length;

  if (nudgeCount >= nudgeThreshold) {
    final flatDoc = await flatRef.get();
    final flatData = flatDoc.data() as Map<String, dynamic>;
    final currentFreq = flatData[taskType];


    if (currentFreq > 1) {
      final newFreq = currentFreq - 1;
      await flatRef.update({taskType: newFreq});

      for (var doc in nudgesQuery.docs) {
        await doc.reference.update({'counted': true});
      }

      final usersQuery = await FirebaseFirestore.instance
          .collection('Users')
          .where('flat', isEqualTo: flatRef)
          .get();

      for (var userDoc in usersQuery.docs) {
        await FirebaseFirestore.instance.collection('Nudges').add({
          'userId': userDoc.id, 
          'flatRef': flatRef,
          'taskType': taskType,
          'oldFreq': currentFreq,
          'newFreq': newFreq,
          'timestamp': Timestamp.now(),
          'message':
              'The frequency of "${getChoreDescription(taskType)}" was changed from $currentFreq to $newFreq due to nudging.',
          'read': false,
          'type': 'freq_change'
        });
      }
    }

    }
  }

  String getChoreDescription(String key) {
    switch (key.trim()) {
      case 'bathroom':
        return 'Cleaning the bathroom';
      case 'dishes':
        return 'Doing the dishes';
      case 'kitchen':
        return 'Cleaning the kitchen';
      case 'laundry':
        return 'Doing laundry';
      case 'recycling':
        return 'Taking out recycling';
      case 'rubbish':
        return 'Taking out the rubbish';
      default:
        return key; // Fallback for any other chore
    }
  }

  String getTaskTypeFromDesc(String desc) {
    switch (desc.trim()) {
      case 'Cleaning the bathroom': return 'bathroom';
      case 'Doing the dishes': return 'dishes';
      case 'Cleaning the kitchen': return 'kitchen';
      case 'Doing laundry': return 'laundry';
      case 'Taking out recycling': return 'recycling';
      case 'Taking out the trash': return 'rubbish';
      default: return desc;
    }
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
            if (tasks.isEmpty) {
              return const Center(child: Text("No tasks found."));
            }
            return ListView(
              children: tasks
                  .map(
                    (e) => ListTile(
                      title: Text(e.description),
                      subtitle: Text(e.isOneOff ? "One-off" : "Repeat"),
                      trailing: IconButton(
                        icon: Icon(Icons.notifications_active),
                        tooltip: 'Nudge',
                        onPressed: () async {

                          await FirebaseFirestore.instance
                              .collection('Nudges')
                              .add({
                                'userId': user
                                    .username, // or user.username if that's your doc ID
                                'taskId': e.taskId,
                                'flatRef': user.flat, 
                                'taskType': getTaskTypeFromDesc(e.description), 
                                'timestamp': Timestamp.now(),
                                'read': false,
                                'counted': false, 
                                'type': 'nudge', 
                              });

                          await adjustTaskFrequencyIfNeeded(user.flat, getTaskTypeFromDesc(e.description));

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Nudge sent to ${user.name}'),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                  .toList(),
            );
          } else {
            return const Center(child: Text("No tasks."));
          }
        },
      ),
    );
  }
}
