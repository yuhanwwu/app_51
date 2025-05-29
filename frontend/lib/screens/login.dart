// screens/login_page.dart
import 'package:flutter/material.dart';
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

  void login() async {
    final username = _controller.text;
    final url = Uri.parse('http://127.0.0.1:8000/api/users/$username/');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        widget.onLogin(data);
      } else {
        setState(() => error = 'User not found');
      }
    } catch (e) {
      setState(() => error = 'Connection error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(controller: _controller, decoration: InputDecoration(labelText: 'Username')),
        ElevatedButton(onPressed: login, child: Text("Log in")),
        if (error.isNotEmpty) Text(error, style: TextStyle(color: Colors.red)),
      ],
    );
  }
}

// import 'package:flutter/material.dart';

// class LoginPage extends StatefulWidget {
//     const LoginPage({super.key, required this.title});

//     final String title;

//     @override
//     State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {

//     @override
//     Widget build(BuildContext context) {
//         return Scaffold (
//             appBar: AppBar(title: const Text('Task List')),
//             body: Container(
//                 child: ListView(
//                     children: 
//                 )
//             )
//         )
//     }
    
// }