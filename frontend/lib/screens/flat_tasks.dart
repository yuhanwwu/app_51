import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FlatTasksScreen extends StatefulWidget {
  const FlatTasksScreen({Key? key}) : super(key: key);

  @override
  State<FlatTasksScreen> createState() => _FlatTasksScreenState();
}

class _FlatTasksScreenState extends State<FlatTasksScreen> {
  final ApiService api = ApiService();

  late Future<List<dynamic>> repeatTasks;
  late Future<List<dynamic>> oneOffTasks;

  @override
  void initState() {
    super.initState();
    repeatTasks = api.getAllRepeatTasks();
    oneOffTasks = api.getAllOneOffTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flat Tasks (All Users)'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text('Repeat Tasks', style: Theme.of(context).textTheme.titleLarge),
            FutureBuilder<List<dynamic>>(
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
                      title: Text(task['description']),
                      subtitle: Text('Frequency: every ${task['frequency']} days'),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Text('One-Off Tasks', style: Theme.of(context).textTheme.titleLarge),
            FutureBuilder<List<dynamic>>(
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
                      title: Text(task['description']),
                      subtitle: Text('Priority: ${task['priority'] ? "High" : "Normal"}'),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
