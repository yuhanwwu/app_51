import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user.dart';
import 'add_flat.dart';
import '../constants/colors.dart';
import 'home_page.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  final Function(FlatUser) onLogin;
  final VoidCallback onLogout;

  const LoginPage({super.key, required this.onLogin, required this.onLogout});

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
      backgroundColor: AppColors.beige,
      appBar: AppBar(
        title: Text('Login'),
        actions: [
          IconButton(
            icon: Icon(Icons.add_home),
            tooltip: 'Add Flat',
            onPressed: () {
              final inputUsername = _usernameController.text.trim();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddFlatPage(
                    username: inputUsername,
                    onLogin: widget.onLogin,
                    onLogout: widget.onLogout,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome to Flat Task Manager',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            Container(
              child: FractionallySizedBox(
                widthFactor: 0.7,
                child: Column(
                  children: [
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
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
                            ? CircularProgressIndicator(color: AppColors.green)
                            : Text("Log in", style: TextStyle(fontSize: 16)),
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
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // Text(
            //   'Available users: alice, bob, charlie',
            //   style: TextStyle(color: Colors.grey, fontSize: 12),
            //   textAlign: TextAlign.center,
            // ),
            SizedBox(height: 10),
            OutlinedButton(
              onPressed: () async {
                final user = (await fetchUser('xt'))!;
                _usernameController.text = 'xt';
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePage(user: user, onLogout: widget.onLogout,)),
                );
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.black,
                backgroundColor: AppColors.lightGreen,
                side: BorderSide(color: AppColors.green),
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text("DEV: Quick Login as xt"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }
}
