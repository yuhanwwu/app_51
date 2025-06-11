import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:frontend/screens/noticeboard.dart';
// import 'package:universal_html/html.dart';
import '../models/user.dart';
import 'add_flat.dart';
import '../constants/colors.dart';
import 'task_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  final Function(FlatUser) onLogin;
  final VoidCallback onLogout;
  final void Function(String) onAddFlat;

  const LoginPage({
    super.key,
    required this.onLogin,
    required this.onAddFlat,
    required this.onLogout,
  });

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  String error = '';
  bool _isLoading = false;
  String username = '';

  Future<FlatUser?> fetchUser(String inputUsername) async {
    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(inputUsername);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      try {
        return FlatUser.fromFirestore(docSnap);
      } catch (e) {
        print('Error in User.fromFirestore: $e');
        return null;
      }
    } else {
      return null;
    }
  }

  // Future<FlatUser?> login() async {
  //   setState(() {
  //     _isLoading = true;
  //     error = '';
  //   });

  //   final inputUsername = _usernameController.text.trim();

  //   if (inputUsername.isEmpty) {
  //     setState(() {
  //       _isLoading = false;
  //       error = 'Please enter a username';
  //     });
  //     return null;
  //   }

  //   final user = await fetchUser(inputUsername);
  //   if (user != null) {
  //     setState(() => _isLoading = false);
  //     return user;
  //   } else {
  //     setState(() {
  //       _isLoading = false;
  //       error = 'Username not found';
  //     });
  //     return null;
  //   }
  // }

  Future<FlatUser?> login() async {
    setState(() {
      _isLoading = true;
      error = '';
    });

    final inputUsername = _usernameController.text.trim();

    if (inputUsername.isEmpty) {
      setState(() {
        _isLoading = false;
        error = 'Please enter a username';
      });
      return null;
    }

    final docRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(inputUsername);
    final docSnap = await docRef.get();

    if (docSnap.exists) {
      try {
        setState(() => _isLoading = false);
        return FlatUser.fromFirestore(docSnap);
      } catch (e) {
        print('Error in User.fromFirestore: $e');
        setState(() {
          _isLoading = false;
          error = 'Failed to load user.';
        });
        return null;
      }
    }

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      final uid = userCredential.user!.uid;

      await docRef.set({'uid': uid, 'createdAt': FieldValue.serverTimestamp()});

      final newUserSnap = await docRef.get();
      setState(() => _isLoading = false);
      return FlatUser.fromFirestore(newUserSnap);
    } catch (e) {
      setState(() {
        _isLoading = false;
        error = 'Could not create user.';
      });
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: SizedBox(
            width: 400,
            height: 500,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.accent.withAlpha(0),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
      BoxShadow(
        color: AppColors.secondary,
        offset: Offset(0, 0),
        blurRadius: 7.0,
        spreadRadius: 10.0,
      ),
    ],
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome to Homely',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.text),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 40),
                  Container(
                    width: 0.5,
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      child: Column(
                        children: [
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              floatingLabelBehavior: FloatingLabelBehavior.never,
                              labelText: 'Username',
                              filled: true,
                              fillColor: AppColors.white,
                              border: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                              prefixIcon: Icon(Icons.person),
                              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: AppColors.primary)
                              ),

                            ),
                            
                          ),
                          SizedBox(height: 20),
                          FractionallySizedBox(
                            widthFactor: 1,
                            child: ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      final user = await login();
                                      if (user != null) {
                                        widget.onLogin(
                                          user,
                                        ); // Let main.dart handle navigation!
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: AppColors.black,
                                padding: EdgeInsets.symmetric(vertical: 15),
                              ),
                              child: _isLoading
                                  ? CircularProgressIndicator(
                                      color: AppColors.green,
                                    )
                                  : Text(
                                      "Log in",
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                          if (error.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                error,
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: () {
                              final inputUsername = _usernameController.text
                                  .trim();
                              widget.onAddFlat(
                                inputUsername,
                              ); // Call to main.dart
                            },
                            icon: Icon(Icons.add_home),
                            label: Text("Create a new flat to sign up", style: TextStyle(color: AppColors.text)),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.text,
                              padding: EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    ),);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
