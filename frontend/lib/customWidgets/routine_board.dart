// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart' show StatelessWidget, Card, BuildContext, Widget, EdgeInsets, Colors, BorderRadius, RoundedRectangleBorder, CircularProgressIndicator, Center, SizedBox, CrossAxisAlignment, FontWeight, TextStyle, Text, TextAlign, Padding, Column, Expanded, Row, FutureBuilder;
// import 'package:frontend/models/task.dart';
// import 'package:intl/intl.dart';

// class RoutineBoardWidget extends StatelessWidget {
//   final DocumentReference flatRef;
//   const RoutineBoardWidget({super.key, required this.flatRef});

//   Future<Map<String, List<Task>>> _fetchRoutineTasks() async {
//     final now = DateTime.now();
//     final weekStart = now.subtract(Duration(days: now.weekday - 1)); // Monday
//     final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

//     final query = await FirebaseFirestore.instance
//         .collection('Tasks')
//         .where('assignedFlat', isEqualTo: flatRef)
//         .where('isOneOff', isEqualTo: false)
//         .get();

//     final tasks = query.docs.map((doc) => Task.fromFirestore(doc)).toList();

//     Map<String, List<Task>> weekTasks = {
//       for (var d in weekDays) DateFormat('yyyy-MM-dd').format(d): []
//     };

//     for (final task in tasks) {
//       DateTime lastDone = task.lastDoneOn != null
//           ? DateFormat('yyyy-MM-dd').parse(task.lastDoneOn!)
//           : DateFormat('yyyy-MM-dd').parse(task.setDate);
//       DateTime nextDue = lastDone.add(Duration(days: task.frequency));

//       if (nextDue.isBefore(weekStart)) {
//         // Overdue: show on Monday
//         weekTasks[DateFormat('yyyy-MM-dd').format(weekStart)]!.add(task);
//       } else if (nextDue.isAfter(weekStart.add(Duration(days: 6)))) {
//         // Due after this week: don't show
//         continue;
//       } else {
//         // Due this week: show on correct day
//         weekTasks[DateFormat('yyyy-MM-dd').format(nextDue)]!.add(task);
//       }
//     }
//     return weekTasks;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final now = DateTime.now();
//     final weekStart = now.subtract(Duration(days: now.weekday - 1));
//     final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

//     return Card(
//       elevation: 8,
//       color: Colors.teal[50],
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: FutureBuilder<Map<String, List<Task>>>(
//           future: _fetchRoutineTasks(),
//           builder: (context, snapshot) {
//             if (!snapshot.hasData) {
//               return SizedBox(
//                   height: 200, child: Center(child: CircularProgressIndicator()));
//             }
//             final weekTasks = snapshot.data!;
//             return Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text("Routine This Week",
//                     style: TextStyle(
//                         fontWeight: FontWeight.bold, fontSize: 20, color: Colors.teal[900])),
//                 SizedBox(height: 8),
//                 Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: weekDays.map((d) {
//                     final dayStr = DateFormat('EEE\ndd/MM').format(d);
//                     final dateKey = DateFormat('yyyy-MM-dd').format(d);
//                     final tasks = weekTasks[dateKey] ?? [];
//                     return Expanded(
//                       child: Column(
//                         children: [
//                           Text(dayStr, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
//                           ...tasks.map((t) => Padding(
//                                 padding: const EdgeInsets.symmetric(vertical: 2.0),
//                                 child: Text(
//                                   t.description,
//                                   style: TextStyle(fontSize: 12),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               )),
//                         ],
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ],
//             );
//           },
//         ),
//       ),
//     );
//   }
// }
