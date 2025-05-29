import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  final Function onLogin;
  LoginPage({required this.onLogin});
  
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _controller = TextEditingController();
  String error = '';
  bool _isLoading = false;

String _getBaseUrl() {
  // Force local development for now
  return 'http://127.0.0.1:5000';  // Always use local Flask server
  
  // Original code (commented out for now):
  // if (kDebugMode) {
  //   return 'http://127.0.0.1:5000';
  // } else {
  //   return 'https://app-51-web.onrender.com';
  // }
}

  void login() async {
    setState(() {
      _isLoading = true;
      error = '';
    });

    final username = _controller.text.trim();
    final baseUrl = _getBaseUrl();
    final url = Uri.parse('$baseUrl/api/users/$username/');
    
    print('Environment: ${kDebugMode ? "Development" : "Production"}');
    print('Attempting login with URL: $url');
    
    try {
      final response = await http.get(url);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        widget.onLogin(data);
      } else if (response.statusCode == 404) {
        setState(() => error = 'User not found');
      } else {
        setState(() => error = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Login error: $e');
      setState(() => error = 'Connection error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void fetchAllUsers() async {
    final baseUrl = _getBaseUrl();
    final url = Uri.parse('$baseUrl/api/users/');
    print('Fetching users from: $url');
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List users = jsonDecode(response.body);
        print('All users:');
        for (var user in users) {
          print('Username: ${user['username']}, Name: ${user['name']}');
        }
      } else {
        print('Failed to load users. Status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  void _devQuickLogin() {
    widget.onLogin({
      'username': 'alice',
      'name': 'Alice Anderson',
    });
  }

  @override
  void initState() {
    super.initState();
    fetchAllUsers();  // This prints users in your debug console when page loads
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            controller: _controller,
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
            onPressed: _devQuickLogin,
            child: Text("DEV: Quick Login as Alice"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}