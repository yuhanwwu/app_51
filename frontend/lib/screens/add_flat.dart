import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/user.dart';
import 'package:universal_html/html.dart' as html;


class AddFlatPage extends StatefulWidget {
  final String username;
  final Function(FlatUser) onLogin;
  final VoidCallback onLogout;
  final VoidCallback onBacktoLogin;

  const AddFlatPage({
    super.key,
    required this.username,
    required this.onLogin,
    required this.onLogout,
    required this.onBacktoLogin,
  });

  @override
  _AddFlatPageState createState() => _AddFlatPageState();
}

class _AddFlatPageState extends State<AddFlatPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _flatNameController = TextEditingController();
  List<Map<String, TextEditingController>> flatmatesControllers = [
    {'username': TextEditingController(), 'name': TextEditingController()},
    {'username': TextEditingController(), 'name': TextEditingController()},
  ];
  String error = '';
  bool isSubmitting = false;

  void addFlatmateField() {
    setState(() {
      flatmatesControllers.add({
        'username': TextEditingController(),
        'name': TextEditingController(),
      });
    });
  }

  Future<bool> _isUsernameUnique(String username) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Users')
        .doc(username)
        .get();
    return !snapshot.exists;
  }

  Future<String> _getUniqueFlatName(String baseName) async {
    String candidate = baseName;
    int counter = 1;
    while (true) {
      final query = await FirebaseFirestore.instance
          .collection('Flat')
          .where('name', isEqualTo: candidate)
          .get();
      if (query.docs.isEmpty) {
        return candidate;
      }
      candidate = '$baseName$counter';
      counter++;
    }
  }


  bool isUsernameCharsValid(String username) {
    final usernameRegExp = RegExp(r'^[a-zA-Z0-9_.]+$');
    return usernameRegExp.hasMatch(username);
  }

  Future<void> _submitFlat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
      error = '';
    });

    final flatName = await _getUniqueFlatName(sanitizeFlatName(_flatNameController.text.trim()));
    final flatmates = flatmatesControllers.map((controllers) {
      return {
        'username': controllers['username']!.text.trim(),
        'name': controllers['name']!.text.trim(),
      };
    }).toList();

    final usernames = flatmates.map((f) => f['username']!).toList();
    // final numOfUsers = usernames.length;
    final localUnique = usernames.toSet().length == usernames.length;

    if (!localUnique) {
      setState(() {
        error = 'Usernames must be unique within the flat.';
        isSubmitting = false;
      });
      return;
    }

    for (var user in usernames) {
      if (!isUsernameCharsValid(user)){
        setState(() {
          error = 'Username "$user" contains invalid characters.';
          isSubmitting = false;
        });
        return;
      }
      if (!await _isUsernameUnique(user)) {
        setState(() {
          error = 'Username "$user" already exists.';
          isSubmitting = false;
        });
        return;
      }
    }

    // Add flat and users to Firestore
    final flatRef = await FirebaseFirestore.instance.collection('Flat').add({
      'name': flatName,
      'numOfCompletedQuestionnaires': 0,
      'bathroom': 0,
      'dishes': 0,
      'kitchen': 0,
      'laundry': 0,
      'recycling': 0,
      'rubbish': 0,
      // 'createdAt': FieldValue.serverTimestamp(),
    });


    await Future.wait(
      flatmates.map((flatmate) async {
        await FirebaseFirestore.instance
            .collection('Users')
            .doc(flatmate['username'])
            .set({
              'flat': flatRef,
              'name': flatmate['name'],
              'questionnaireDone': false,
            });
      }),
    );

    await FirebaseFirestore.instance.collection('Users').doc('${flatName}_guest').set({
      'flat': flatRef,
      'name': '${flatName}_guest',
      'role': 'guest',
      'questionnaireDone': true,
    });

    // html.window.location.reload();
    final yourUsername = flatmates.first['username']!;
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(yourUsername)
        .get();
    final user = FlatUser.fromFirestore(userDoc);
    await FirebaseFirestore.instance.collection('Noticeboard').add({
      'content': 'Welcome to your noticeboard!! \n Here you can post messages or to-do lists for all flatmates to see. \n Press the + button to add a new note, and drag it to the bin to delete it.',
      'position': [616.5, 227],
      'flatRef': flatRef,
      'createdBy': user.userRef,
      'type': 'text',
      'tasks': [],
    });
    html.window.location.reload();
    widget.onLogin(user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Flat"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: widget.onBacktoLogin, // This will return to the Login page
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _flatNameController,
                decoration: InputDecoration(labelText: 'Flat Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a flat name' : null,
              ),
              SizedBox(height: 20),
              Text("Flatmates (min 2):", style: TextStyle(fontSize: 16)),
              ...flatmatesControllers.asMap().entries.map((entry) {
                final index = entry.key;
                final controllers = entry.value;
                final isUser = index == 0;

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser ? 'You' : 'Flatmate $index',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: controllers['username'],
                          decoration: InputDecoration(
                            labelText: isUser
                                ? 'Your Username'
                                : 'Flatmate $index Username',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Enter a username' : null,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: controllers['name'],
                          decoration: InputDecoration(
                            labelText: isUser
                                ? 'Your Name'
                                : 'Flatmate $index Name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value!.isEmpty ? 'Enter a name' : null,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              TextButton(
                onPressed: addFlatmateField,
                child: Text('Add another flatmate'),
              ),
              if (error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(error, style: TextStyle(color: Colors.red)),
                ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSubmitting ? null : _submitFlat,
                child: isSubmitting
                    ? CircularProgressIndicator()
                    : Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String sanitizeFlatName(String input) {
    // Keep only letters, numbers, underscores, and hyphens
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
  }

  @override
  void dispose() {
    _flatNameController.dispose();
    for (var controllers in flatmatesControllers) {
      controllers['username']!.dispose();
      controllers['name']!.dispose();
    }
    super.dispose();
  }
}
