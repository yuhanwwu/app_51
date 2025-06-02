import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/user.dart';
import 'package:intl/intl.dart';

Future<Map<String, int>> fetchChorePlan(String plan) async {
  DocumentSnapshot doc = await FirebaseFirestore.instance
      .collection('VibeTemplates')
      .doc(plan)
      .get();

  if (!doc.exists) {
    throw Exception('User not found');
  }


  Map<String, dynamic> data = doc.data() as Map<String, dynamic>;


  // Convert dynamic map to Map<String, int>
  Map<String, int> chores = {};
  data.forEach((key, value) {
    if (value is int) {
      chores[key] = value;
    }
  });

  return chores;
}

class QuestionnairePage extends StatefulWidget {
  final String username;
  final Function(User) onComplete;

  const QuestionnairePage({
    super.key,
    required this.username,
    required this.onComplete,
  });

  @override
  State<QuestionnairePage> createState() => _QuestionnairePageState();
}

class _QuestionnairePageState extends State<QuestionnairePage> {
  int? _expandedIndex;
  bool isSubmitting = false;

  final List<String> vibeOptions = [
    'I like it tidy',
    "I don't mind a bit of mess",
    'I want it super-relaxed',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Set Up Your Routine'),
        backgroundColor: Colors.teal[400],
        elevation: 0,
      ),
      body: Container(
        color: Colors.teal[50],
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text(
                "What's the vibe of your flat?",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: vibeOptions.length,
                  itemBuilder: (context, index) {
                    return _buildExpandableCard(index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableCard(int index) {
    bool isExpanded = _expandedIndex == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isExpanded ? Colors.white : Colors.teal[100],
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          if (isExpanded)
            BoxShadow(
              color: Colors.teal.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
        ],
        border: Border.all(
          color: isExpanded ? Colors.teal : Colors.teal[200]!,
          width: 2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.teal,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vibeOptions[index],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.teal[900],
                      ),
                    ),
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: _buildPlanDetails(vibeOptions[index]),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            setState(() {
                              isSubmitting = true;
                            });
                            String selectedVibe = vibeOptions[index];
                            String plan;
                            switch (selectedVibe) {
                              case 'I like it tidy':
                                plan = 'clean';
                                break;
                              case "I don't mind a bit of mess":
                                plan = 'medium';
                                break;
                              case "I want it super-relaxed":
                                plan = 'dirty';
                                break;
                              default:
                                plan = 'unknown';
                            }

                            try {
                              // Save the plan to Firestore 
                              DocumentSnapshot planDoc = await FirebaseFirestore.instance
                                  .collection('VibeTemplates')
                                  .doc(plan)
                                  .get();

                              Map<String, dynamic> data = planDoc.data() as Map<String, dynamic>;

                              await FirebaseFirestore.instance
                                  .collection('UserPreferences')
                                  .doc(widget.username)
                                  .set(data);

                              // set repeat tasks based on chosen plan
                              populateRepeatTasks(plan);

                              // Mark questionnaire as done
                              await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(widget.username)
                                  .update({'questionnaireDone': true});

                              // Fetch the updated user document
                              final userDoc = await FirebaseFirestore.instance
                                  .collection('Users')
                                  .doc(widget.username)
                                  .get();
                              final user = User.fromFirestore(userDoc);

                              // Call the onComplete callback to update app state and navigate
                              widget.onComplete(user);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                              setState(() {
                                isSubmitting = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal[400],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Choose this',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanDetails(String vibeOption) {
    String plan = 'This string should have been re-assigned.';
    switch (vibeOption) {
      case 'I like it tidy':
        plan = 'clean';
        break;
      case "I don't mind a bit of mess":
        plan = 'medium';
        break;
      case "I want it super-relaxed":
        plan = 'dirty';
        break;
      default:
        plan = 'unknown';
    }

    return FutureBuilder<Map<String, int>>(
      future: fetchChorePlan(plan),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No chores found.');
        }

        final chores = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: chores.entries.map((entry) {
            String chore;
            switch (entry.key.trim()) {
              case 'bathroom':
                chore = 'Cleaning the bathroom';
                break;
              case 'dishes':
                chore = 'Doing the dishes';
                break;
              case 'kitchen':
                chore = 'Cleaning the kitchen';
                break;
              case 'laundry':
                chore = 'Doing laundry';
                break;
              case 'recycling':
                chore = 'Taking out recycling';
                break;
              case 'rubbish':
                chore = 'Taking out the trash';
                break;
              default:
                chore = entry.key;
            }
            int days = entry.value;

            String frequency;
            if (days == 1) {
              frequency = 'Daily';
            } else if (days == 7) {
              frequency = 'Weekly';
            } else {
              frequency = 'Every $days days';
            }

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    chore,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    frequency,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.teal[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList());
          });
        }
        
          void populateRepeatTasks(String plan) async {
            // 1. Fetch the user's flat reference
            final userDoc = await FirebaseFirestore.instance
              .collection('Users')
              .doc(widget.username)
              .get();

            final userRef = FirebaseFirestore.instance
              .collection('Users')
              .doc(widget.username);
            
            final userData = userDoc.data();
            final flatRef = userData!['flat']; // Should be a DocumentReference
            final now = DateTime.now();
            final setDate = DateFormat('yyyy-MM-dd').format(now);

            // 2. Fetch the plan's chores
            final chores = await fetchChorePlan(plan);

            // 3. For each chore, create a repeat task
            for (final entry in chores.entries) {
            String description;
            switch (entry.key.trim()) {
              case 'bathroom':
                description = 'Clean the bathroom';
                break;
              case 'dishes':
                description = 'Do the dishes';
                break;
              case 'kitchen':
                description = 'Clean the kitchen';
                break;
              case 'laundry':
                description = 'Do laundry';
                break;
              case 'recycling':
                description = 'Take out recycling';
                break;
              case 'rubbish':
                description = 'Take out the trash';
                break;
              default:
                description = entry.key;
            }
              await FirebaseFirestore.instance.collection('Tasks').add({
                'description': description,
                'isOneOff': false,
                'assignedFlat': flatRef,
                'assignedTo': userRef,
                'done': null,
                'setDate': setDate,
                'priority': false,
                'frequency': entry.value, // e.g. every X days
                'lastDoneOn': null,
                'lastDoneBy': null,
              });
            }
          }
}