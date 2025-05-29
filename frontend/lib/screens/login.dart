import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../models/user.dart';

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

  Future<Map<String, dynamic>> loadJson() async {
    final jsonString = await rootBundle.loadString('assets/data.json');
    return json.decode(jsonString);
  }
  

  void login() async {
    setState(() {
      _isLoading = true;
      error = '';
    });

    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        error = 'Please enter a username';
      });
      return;
    }

    final data = await loadJson();

    Map<String, dynamic>? userMap;
    try {
      final users = data['users'] as List<dynamic>;
      userMap = users.firstWhere(
        (user) => user['username'] == username,
      );
      final user = User.fromJson(userMap!);
      widget.onLogin(user);
      return;
      
    } catch (e) {
      userMap = null;
      setState(() {
        error = 'Username not found';
        });
      }

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( 
      appBar: AppBar(
        title: Text('Login'),
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
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isLoading ? null : login,
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 15),
            ),
            child: _isLoading 
              ? CircularProgressIndicator(color: Colors.white)
              : Text("Log in", style: TextStyle(fontSize: 16)),
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
