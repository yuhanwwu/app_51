import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/screens/amend_questionnaire.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final Function(FlatUser) onComplete;

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
  int _helpButtonPressCount = 0;

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

  String getPlanDescription(String plan) {
    switch (plan) {
      case 'I like it tidy':
        return plan = 'clean';

      case "I don't mind a bit of mess":
        return plan = 'medium';

      case "I want it super-relaxed":
        return plan = 'dirty';

      default:
        return plan;
    }
  }

  final List<String> vibeOptions = [
    'I like it tidy',
    "I don't mind a bit of mess",
    'I want it super-relaxed',
  ];

  @override
  void initState() {
    super.initState();
    // _showTutorialIfFirstTime();
  }

  Future<void> _showTutorialIfFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenTutorial = prefs.getBool('hasSeenQuestionnaireTutorial_${widget.username}') ?? false;
    if (!hasSeenTutorial) {
      await _showTutorialDialog();
      await prefs.setBool('hasSeenQuestionnaireTutorial_${widget.username}', true);
    }
  }

  Future<void> _showTutorialDialog() async {
  final prefs = await SharedPreferences.getInstance();
  final key = 'questionnaireHelpButtonPressCount_${widget.username}';
  _helpButtonPressCount = (prefs.getInt(key) ?? 0) + 1;
  await prefs.setInt(key, _helpButtonPressCount);

  await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(
        'How to Set Up Your Routine',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: 800, // Makes the dialog wider
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "• Pick the vibe that fits your flat.",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "• View the chore schedules which correspond to each vibe.",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "• Answer honestly: your choice will help set up the flat's cleaning routine, by taking an average of everyones' response.",
                style: TextStyle(fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "• Don't worry, you can customise these frequencies in the next page!",
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Tap the help icon anytime for this guide.",
              style: TextStyle(fontSize: 16, color: Colors.teal),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it!', style: TextStyle(fontSize: 18)),
        ),
      ],
    ),
  );
}

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
              const SizedBox(height: 8),
              const Text(
                "Choose the option that best matches your personal cleaning style. "
                "The average of everyone's responses determines a fair routine for everyone.",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
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
                            String plan = getPlanDescription(selectedVibe);

                            try {
                              final chores = await fetchChorePlan(plan);

                              // Navigate to amend screen
                              final amendedChores =
                                  await Navigator.push<Map<String, int>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AmendQuestionnaireScreen(
                                            chores: chores,
                                          ),
                                    ),
                                  );

                              // If user cancels, don't proceed
                              if (amendedChores == null) {
                                setState(() => isSubmitting = false);
                                return;
                              }

                              await FirebaseFirestore.instance
                                  .collection('UserPreferences')
                                  .doc(widget.username)
                                  .set(amendedChores);

                              // set repeat tasks based on chosen plan
                              await populateRepeatTasks(amendedChores);

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
                              final user = FlatUser.fromFirestore(userDoc);

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
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
    String plan = getPlanDescription(vibeOption);

    return FutureBuilder<Map<String, int>>(
      future: fetchChorePlan(plan),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: const TextStyle(color: Colors.red),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Text('No chores found.');
        }

        final chores = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: chores.entries.map((entry) {
            String chore = getChoreDescription(entry.key.trim());
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
                  Text(chore, style: const TextStyle(fontSize: 16)),
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
          }).toList(),
        );
      },
    );
  }

  Future<void> populateRepeatTasks(Map<String, int> plan) async {
    // 1. Fetch the user's flat reference
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.username)
        .get();

    final userData = userDoc.data();
    final flatRef = userData!['flat']; // Should be a DocumentReference
    final now = DateTime.now();
    final setDate = DateFormat('yyyy-MM-dd').format(now);

    // 2. Fetch all flatmates in this flat
    final flatmatesQuery = await FirebaseFirestore.instance
        .collection('Users')
        .where('flat', isEqualTo: flatRef)
        .get();
    final flatmateDocs = flatmatesQuery.docs;
    if (flatmateDocs.length < 2) {
      throw Exception('Not enough flatmates to assign tasks.');
    }
    final flatmateRefs = flatmateDocs
        .where((doc) => doc.data().containsKey('role') ? doc['role'] != 'guest' : true)
        .map((doc) => doc.reference)
        .toList();

    // fetch existing flat's chore preferences
    final flatSnapshot = await flatRef.get();
    final flatData = flatSnapshot.data() as Map<String, dynamic>;

    // 3. For each chore, create a repeat task, alternating between the first two flatmates
    int i = 0;
    for (final entry in plan.entries) {
      String description = getChoreDescription(entry.key.trim());

      final int existingSum =
          flatData[entry.key.trim()] * flatData['numOfCompletedQuestionnaires'];
      flatData[entry.key.trim()] =
          ((existingSum + entry.value) /
                  (flatData['numOfCompletedQuestionnaires'] + 1))
              .round();

      if (flatData['numOfCompletedQuestionnaires'] == 0) {
        // Alternate assignment between the first two flatmates
        final assignedTo = flatmateRefs[i % 2];
        await FirebaseFirestore.instance.collection('Tasks').add({
          'description': description,
          'isOneOff': false,
          'assignedFlat': flatRef,
          'assignedTo': assignedTo,
          'done': null,
          'setDate': setDate,
          'priority': false,
          'frequency': entry.value, // e.g. every X days
          'lastDoneOn': null,
          'lastDoneBy': null,
          'isPersonal': false,
        });
        i++;
      }
    }

    flatData['numOfCompletedQuestionnaires'] += 1;
    await flatRef.update(flatData);
  }
}
