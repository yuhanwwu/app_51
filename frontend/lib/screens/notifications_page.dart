import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  final String username;
  const NotificationsPage({super.key, required this.username});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late Future<List<QueryDocumentSnapshot>> _nudgesFuture;

  @override
  void initState() {
    super.initState();
    _nudgesFuture = _fetchNudges();
    markNudgesAsRead();
  }

  Future<void> markNudgesAsRead() async {
  final query = await FirebaseFirestore.instance
      .collection('Nudges')
      .where('userId', isEqualTo: widget.username)
      .where('read', isEqualTo: false)
      .get();
  for (var doc in query.docs) {
    doc.reference.update({'read': true});
  }
}

  Future<List<QueryDocumentSnapshot>> _fetchNudges() async {
    final query = await FirebaseFirestore.instance
        .collection('Nudges')
        .where('userId', isEqualTo: widget.username)
        .orderBy('timestamp', descending: true)
        .get();
    return query.docs;
  }

  Future<String> _getTaskDescription(String taskId) async {
    final taskSnap = await FirebaseFirestore.instance
        .collection('Tasks')
        .doc(taskId)
        .get();
    if (taskSnap.exists) {
      final taskData = taskSnap.data() as Map<String, dynamic>;
      return taskData['description'];
    }
    return 'a task';
  }

  void _deleteNudge(String nudgeId) async {
    await FirebaseFirestore.instance.collection('Nudges').doc(nudgeId).delete();
    setState(() {
      _nudgesFuture = _fetchNudges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _nudgesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No nudges yet!'));
          }
          final nudges = snapshot.data!;
          return ListView.builder(
            itemCount: nudges.length,
            itemBuilder: (context, index) {
              final nudge = nudges[index];
              final data = nudge.data() as Map<String, dynamic>;
              final date = (data['timestamp'] as Timestamp).toDate();
              final taskId = data['taskId'] as String;
              return FutureBuilder<String>(
                future: _getTaskDescription(taskId),
                builder: (context, taskSnap) {
                  final description = taskSnap.data ?? 'a task';
                  return ListTile(
                    leading: const Icon(Icons.notifications_active, color: Colors.teal),
                    title: Text('You were nudged for: $description'),
                    subtitle: Text('${date.toLocal()}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _deleteNudge(nudge.id),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

