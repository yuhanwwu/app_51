import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<Map<String, int>> fetchChorePlan(String username) async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('QuestionnairePreferences')
        .doc(username)
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

//DUMMY PAGE
class QuestionnairePage extends StatelessWidget {
  final String flatId;

  const QuestionnairePage({required this.flatId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Questionnaire')),
      body: Center(
        child: Text('Questionnaire for Flat ID: $flatId'),
      ),
    );
  }
}

class VibeSelectionPage extends StatefulWidget {

    final String username;

    VibeSelectionPage({required this.username});
    
    @override
    _VibeSelectionPageState createState() => _VibeSelectionPageState();
    }

    class _VibeSelectionPageState extends State<VibeSelectionPage> {
    int? _expandedIndex; // Tracks which card is open

    final List<String> vibeOptions = [
        'I like it tidy',
        'I don’t mind a bit of mess',
        'I want it super-relaxed',
    ];

    @override
    Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(title: Text('Setting Up Your Routine')),
        body: Padding(
            padding: EdgeInsets.all(16.0),
            child: ListView.builder(
            itemCount: vibeOptions.length,
            itemBuilder: (context, index) {
                return _buildExpandableCard(index);
            },
            ),
        ),
        );
    }

    Widget _buildExpandableCard(int index) {
        bool isExpanded = _expandedIndex == index;

        return Card(
        margin: EdgeInsets.symmetric(vertical: 8),
        child: InkWell(
            onTap: () {
            setState(() {
                // Expand if not already; collapse if tapped again
                _expandedIndex = isExpanded ? null : index;
            });
            },
            child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                    vibeOptions[index],
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isExpanded) ...[
                    SizedBox(height: 12),
                    _buildPlanDetails(vibeOptions[index]),
                    SizedBox(height: 12),
                    ElevatedButton(
                    onPressed: () {
                        // TODO: implement choose option which will update the database with a new entry. 
                        print('Chosen: ${vibeOptions[index]}');
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        ),
                    ),
                    child: Text('Choose this'),
                    ),
                ],
                ],
            ),
            ),
        ),
        );
    }

    Widget _buildPlanDetails(String username) {
    return FutureBuilder<Map<String, int>>(
        future: fetchChorePlan(username),
        builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Text('No chores found.');
        }

        final chores = snapshot.data!;
        return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: chores.entries.map((entry) {
            String chore = entry.key;
            int days = entry.value;

            String frequency;
            if (days == 1) {
                frequency = 'daily';
            } else if (days == 7) {
                frequency = 'weekly';
            } else {
                frequency = 'every $days days';
            }

            return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                Text(chore),
                Text(frequency),
                ],
            );
            }).toList(),
        );
        },
    );
}

}


