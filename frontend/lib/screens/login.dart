import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/user.dart';
import 'user_tasks.dart';
import '../constants/colors.dart';

class LoginPage extends StatefulWidget {
  final Function(User) onLogin;

  const LoginPage({Key? key, required this.onLogin}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  String error = '';
  bool _isLoading = false;
  String username = '';

  Future<Map<String, dynamic>> loadJson() async {
    final jsonString = await rootBundle.loadString('assets/data.json');
    return json.decode(jsonString);
  }

  Future<User?> login() async {
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

    final data = await loadJson();

    try {
      final users = data['users'] as List<dynamic>;
      final userMap = users.firstWhere(
        (user) => user['username'] == inputUsername,
      );
      final user = User.fromJson(userMap);
      setState(() => _isLoading = false);
      return user;
    } catch (e) {
      setState(() {
        _isLoading = false;
        error = 'Username not found';
      });
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.beige,
      appBar: AppBar(title: Text('Login')),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          TaskPage(username: user.username),
                                    ),
                                  );
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
            Text(
              'Available users: alice, bob, charlie',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                _usernameController.text = 'alice';
                login();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.black,
                backgroundColor: AppColors.lightGreen,
                side: BorderSide(color: AppColors.green),
                padding: EdgeInsets.symmetric(vertical: 15),
              ),
              child: Text("DEV: Quick Login as Alice"),
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
