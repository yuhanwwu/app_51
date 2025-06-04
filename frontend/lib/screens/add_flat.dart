import 'dart:html' as html;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:frontend/models/user.dart';
import 'package:frontend/screens/login.dart';

class AddFlatPage extends StatefulWidget {
  final String username;
  final Function(User) onLogin;
  const AddFlatPage({super.key, required this.username, required this.onLogin});

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

  Future<void> _submitFlat() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSubmitting = true;
      error = '';
    });

    final flatName = _flatNameController.text.trim();
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
      if (!await _isUsernameUnique(user)) {
        setState(() {
          error = 'Username "$user" already exists in Firebase.';
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
      'rubbish': 0
      // 'createdAt': FieldValue.serverTimestamp(),
    });

    String? token = await FirebaseMessaging.instance.getToken();

    await Future.wait(flatmates.map((flatmate) async {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(flatmate['username'])
          .set({
            'flat': flatRef,
            'name': flatmate['name'],
            'questionnaireDone': false,
            'fcmToken': token
          });
    }));

    html.window.location.reload();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(onLogin: widget.onLogin)),
      );

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Flat")),
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
                return Column(
                  children: [
                    TextFormField(
                      controller: controllers['username'],
                      decoration: InputDecoration(
                        labelText: 'Flatmate ${index + 1} Username',
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Enter a username for flatmate ${index + 1}'
                          : null,
                    ),
                    TextFormField(
                      controller: controllers['name'],
                      decoration: InputDecoration(
                        labelText: 'Flatmate ${index + 1} Name',
                      ),
                      validator: (value) => value!.isEmpty
                          ? 'Enter a name for flatmate ${index + 1}'
                          : null,
                    ),
                    SizedBox(height: 10),
                  ],
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
