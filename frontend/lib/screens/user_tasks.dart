// // // screens/task_page.dart
// // import 'dart:convert';

// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:frontend/screens/flat_tasks.dart';
// import 'package:http/http.dart' as http;
// import '../models/task.dart';
// import '../services/api_service.dart'; // fetchUserTasks
// import '../constants/colors.dart';

// class TaskPage extends StatelessWidget {
//   final String username;
//   TaskPage({required this.username});

//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<Task>>(
//       future: fetchUserTasks(username),
//       builder: (context, snapshot) {
//         if (snapshot.hasData) {
//           final tasks = snapshot.data!;
//           return Scaffold(
//             backgroundColor: AppColors.beige,
//             appBar: AppBar(
//               title: Text(
//                 "Tasks for $username",
//                 style: TextStyle(color: Colors.black),
//               ),
//             ),
//             body: Center(
//               child: FractionallySizedBox(
//                 widthFactor: 0.7,
//                 heightFactor: 0.7,
//                 child: Container(
//                   child: Column(
//                     children: [
//                       Expanded(
//                         child: ListView(
//                           children: tasks
//                               .map(
//                                 (task) => Container(
//                                   margin: const EdgeInsets.symmetric(
//                                     vertical: 5.0,
//                                   ),
//                                   decoration: BoxDecoration(
//                                     color: task.isOneOff
//                                         ? AppColors.lightGreen
//                                         : AppColors.green,
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   child: ListTile(
//                                     title: Text(task.description),
//                                     subtitle: task.isOneOff
//                                         ? Text(
//                                             "One-off" +
//                                                 (task.priority == true
//                                                     ? " (Urgent)"
//                                                     : ""),
//                                           )
//                                         : Text(
//                                             "Repeat task - last done: ${task.lastdoneon ?? 'Never'}",
//                                           ),
//                                   ),
//                                 ),
//                               )
//                               .toList(),
//                         ),
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.all(8.0),
//                         child: ElevatedButton(
//                           onPressed: () {
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) =>
//                                     FlatTasksScreen(username: username),
//                               ),
//                             );
//                           },
//                           child: const Text('View Flat Tasks'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           );
//         } else if (snapshot.hasError) {
//           return Text("Error: ${snapshot.error}");
//         }
//         return CircularProgressIndicator();
//       },
//     );
//   }
// }

// Future<List<Task>> fetchUserTasks(String username) async {
//   final jsonString = await rootBundle.loadString('assets/data.json');
//   final data = jsonDecode(jsonString);

//   List<Task> oneOffTasks = [];
//   List<Task> repeatTasks = [];

//   for (var t in data['one_off_tasks']) {
//     if (t['assignedto'] == username) {
//       oneOffTasks.add(Task.fromFirestore(t, isOneOff: false));
//     }
//   }
//   for (var t in data['repeat_tasks']) {
//     if (t['assignedto'] == username) {
//       repeatTasks.add(Task.fromFirestore(t, isOneOff: true));
//     }
//   }
//   return oneOffTasks + repeatTasks;
// }
