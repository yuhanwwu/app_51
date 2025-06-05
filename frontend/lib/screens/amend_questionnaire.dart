import 'package:flutter/material.dart';

class AmendQuestionnaireScreen extends StatefulWidget {
  final Map<String, int> chores;
  const AmendQuestionnaireScreen({super.key, required this.chores});

  @override
  State<AmendQuestionnaireScreen> createState() => _AmendQuestionnaireScreenState();
}

class _AmendQuestionnaireScreenState extends State<AmendQuestionnaireScreen> {
  late Map<String, TextEditingController> controllers;

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
        return 'Taking out the trash';
      default:
        return key; // Fallback for any other chore
    }
  }

  @override
  void initState() {
    super.initState();
    controllers = {
      for (var entry in widget.chores.entries)
        entry.key: TextEditingController(text: entry.value.toString())
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Amend Chore Frequencies'),
        backgroundColor: Colors.teal[400],
        elevation: 0,
      ),
      backgroundColor: Colors.teal[50],
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              "Adjust how often each chore should repeat.",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: controllers.entries.map((entry) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 2,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            getChoreDescription(entry.key.trim()),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.teal,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: entry.value,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Days',
                              labelStyle: TextStyle(color: Colors.teal[700]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.teal),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final amended = <String, int>{};
                  for (var entry in controllers.entries) {
                    final val = int.tryParse(entry.value.text.trim()) ?? 1;
                    amended[entry.key] = val;
                  }
                  Navigator.pop(context, amended);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal[400],
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Frequencies',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}