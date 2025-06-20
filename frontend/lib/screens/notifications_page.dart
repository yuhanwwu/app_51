import 'dart:async';

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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _nudgesFuture = _fetchNudges();
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
    setState(() {
      _nudgesFuture = _fetchNudges();
    });
  });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<List<QueryDocumentSnapshot>> _fetchNudges() async {
    final query = await FirebaseFirestore.instance
        .collection('Nudges')
        .where('userId', isEqualTo: widget.username)
        .where('read', isEqualTo: false)
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
    await FirebaseFirestore.instance.collection('Nudges').doc(nudgeId).update({'read': true});

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
              final type = data['type'] ?? 'nudge';

              if (type == 'freq_change') {
                // Frequency change notification
                return ListTile(
                  leading: const Icon(
                    Icons.sticky_note_2, // Notice/announcement icon
                    color: Colors.orange,
                  ),
                  title: Text(data['message'] ?? 'Frequency of a task was changed.'),
                  subtitle: Text('${date.toLocal()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Delete',
                    onPressed: () => _deleteNudge(nudge.id),
                  ),
                );
              } else {
                // Regular nudge notification
                final taskId = data['taskId'] as String;
                return FutureBuilder<String>(
                  future: _getTaskDescription(taskId),
                  builder: (context, taskSnap) {
                    final description = taskSnap.data ?? 'a task';
                    return ListTile(
                      leading: const Icon(
                        Icons.notifications_active,
                        color: Colors.teal,
                      ),
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
              }
            },
          );
        },
      ),
    );
  }
}
