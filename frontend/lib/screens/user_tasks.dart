// // screens/task_page.dart
// import 'dart:convert';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/screens/flat_tasks.dart';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../services/api_service.dart'; // fetchUserTasks

// <<<<<<< render_db
// Future<List<Task>> fetchUserTasks(String username) async {
//   final url = Uri.parse('http://127.0.0.1:5000/api/users/$username/');
//   final res = await http.get(url);
// =======
// // Future<List<Task>> fetchUserTasks(String username) async {
// //   final url = Uri.parse('http://127.0.0.1:8000/api/users/$username/');
// //   final res = await http.get(url);
// >>>>>>> master

//   if (res.statusCode == 200) {
//     final data = jsonDecode(res.body);
//     List<Task> tasks = [];

//     for (var t in data['assigned_repeat_tasks']) {
//       tasks.add(Task.fromJson(t, isOneOff: false));
//     }
//     for (var t in data['assigned_oneoff_tasks']) {
//       tasks.add(Task.fromJson(t, isOneOff: true));
//     }

//     return tasks;
//   } else {
//     throw Exception("Failed to load tasks");
//   }
// }

class TaskPage extends StatelessWidget {
  final String username;
  TaskPage({required this.username});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Task>>(
      future: fetchUserTasks(username),
      builder: (context, snapshot) {
        if (snapshot.hasData) { 
          final tasks = snapshot.data!;
          return Scaffold(appBar: AppBar(
            title: Text("Tasks for $username"),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  children: tasks.map((task) => ListTile(
                    title: Text(task.description),
                    subtitle: task.isOneOff
                        ? Text("One-off" + (task.priority == true ? " (Urgent)" : ""))
                        : Text("Repeat task - last done: ${task.lastdoneon ?? 'Never'}"),
                  )).toList(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FlatTasksScreen(),
                      ),
                    );
                  },
                  child: const Text('View Flat Tasks'),
                ),
              ),
            ],
          ));
        } else if (snapshot.hasError) {
          return Text("Error: ${snapshot.error}");
        }
        return CircularProgressIndicator();
      },
    );
  }
}

Future<List<Task>> fetchUserTasks(String username) async {
  final jsonString = await rootBundle.loadString('assets/data.json');
  final data = jsonDecode(jsonString);

  List<Task> oneOffTasks = [];
  List<Task> repeatTasks = [];

  for (var t in data['one_off_tasks']) {
    if (t['assignedto'] == username) {
      oneOffTasks.add(Task.fromJson(t, isOneOff: false));
    }
  }
    for (var t in data['repeat_tasks']) {
      if (t['assignedto'] == username) {
      repeatTasks.add(Task.fromJson(t, isOneOff: true));
      }
    }
    return oneOffTasks + repeatTasks;
  }