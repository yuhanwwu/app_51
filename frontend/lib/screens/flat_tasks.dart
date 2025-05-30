import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/task.dart';
import '../models/user.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class TaskBundle {
  final List<Task> oneOff;
  final List<Task> repeat;

  TaskBundle({required this.oneOff, required this.repeat});
}

class FlatTasksScreen extends StatefulWidget {
  final String username;
  FlatTasksScreen({Key? key, required this.username}) : super(key: key);

  @override
  State<FlatTasksScreen> createState() => _FlatTasksScreenState();
}

class _FlatTasksScreenState extends State<FlatTasksScreen> {
  // final ApiService api = ApiService();

  late Future<List<Task>> repeatTasks = Future.value([]);
  late Future<List<Task>> oneOffTasks = Future.value([]);
  late Future<List<dynamic>> flatTasks = Future.value([]);

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _loadTasks() async {
    final bundle = await fetchFlatTasks(widget.username);
    setState(() {
      oneOffTasks = Future.value(bundle.oneOff);
      repeatTasks = Future.value(bundle.repeat);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flat Tasks (All Users)')),
      body: FractionallySizedBox(
        // alignment: Alignment.topCenter,
        // widthFactor: 0.7,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 10),
              Text(
                'Repeat Tasks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              FutureBuilder<List<Task>>(
                future: repeatTasks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No repeat tasks');
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final task = snapshot.data![index];
                      return ListTile(
                        title: Text("${task.description} - ${task.assignedto}"),
                        subtitle: Text(
                          'Frequency: every ${task.frequency} days',
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                'One-Off Tasks',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              FutureBuilder<List<Task>>(
                future: oneOffTasks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No one-off tasks');
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final task = snapshot.data![index];
                      return ListTile(
                        title: Text("${task.description} - ${task.assignedto}"),
                        subtitle: Text(
                          'Priority: ${task.priority == true ? "High" : "Normal"}',
                        ),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Future<TaskBundle> fetchFlatTasks(String username) async {
  final jsonString = await rootBundle.loadString('assets/data.json');
  final data = jsonDecode(jsonString);

  List<User> flatUsers = [];
  List<Task> oneOff = [];
  List<Task> repeat = [];

  String? flat;

  final entry = data['users'].firstWhere((u) => u['username'] == 'alice');
  flat = entry['flat'];

  for (var u in data['users']) {
    if (u['flat'] == flat) {
      flatUsers.add(User.fromJson(u));
    }
  }

  for (var t in data['one_off_tasks']) {
    if (t['assignedto'].isNotEmpty &&
        flatUsers.any(
          (user) =>
              user.username.toLowerCase() ==
              t['assignedto'].toString().toLowerCase(),
        )) {
      oneOff.add(Task.fromJson(t, isOneOff: true));
    }
  }

  for (var t in data['repeat_tasks']) {
    if (t['assignedto'].isNotEmpty &&
        flatUsers.any(
          (user) =>
              user.username.toLowerCase() ==
              t['assignedto'].toString().toLowerCase(),
        )) {
      repeat.add(Task.fromJson(t, isOneOff: false));
    }
  }

  return TaskBundle(oneOff: oneOff, repeat: repeat);
}

// Future<List<Task>> fetchFlatTasks(String flat) async {
//   final jsonString = await rootBundle.loadString('assets/data.json');
//   final data = jsonDecode(jsonString);
//   List<Task> flatTasks = [];
//   List<User> flatUsers = [];
//   for (var u in data['users']) {
//     if (u['flat'] == flat) {
//       flatUsers.add(User.fromJson(u));
//     }
//   }
//   for (var t in data['one_off_tasks']) {
//     if (t['assignedto'].isNotEmpty &&
//         flatUsers.any((user) => user.username == t['assignedto'])) {
//       // Check if the task is assigned to any user in the flat
//       flatTasks.add(Task.fromJson(t, isOneOff: true));
//     }
//   }
//   for (var t in data['repeat_tasks']) {
//     if (t['assignedto'].isNotEmpty &&
//         flatUsers.any((user) => user.username == t['assignedto'])) {
//       // Check if the task is assigned to any user in the flat
//       flatTasks.add(Task.fromJson(t, isOneOff: false));
//     }
//   }

//   return flatTasks;
// }
