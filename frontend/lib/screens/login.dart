// // screens/login_page.dart
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';

// class LoginPage extends StatefulWidget {
//   final Function onLogin;
//   LoginPage({required this.onLogin});
  
//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {

//   final _controller = TextEditingController();
//   String error = '';

//   void login() async {
//     final username = _controller.text;
//     final url = Uri.parse('http://127.0.0.1:8000/api/users/$username/');

//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = jsonDecode(response.body);
//         widget.onLogin(data);
//       } else {
//         setState(() => error = 'User not found');
//       }
//     } catch (e) {
//       setState(() => error = 'Connection error');
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         TextField(controller: _controller, decoration: InputDecoration(labelText: 'Username')),
//         ElevatedButton(onPressed: login, child: Text("Log in")),
//         if (error.isNotEmpty) Text(error, style: TextStyle(color: Colors.red)),
//       ],
//     );
//   }
// }

// // import 'package:flutter/material.dart';

// // class LoginPage extends StatefulWidget {
// //     const LoginPage({super.key, required this.title});

// //     final String title;

// //     @override
// //     State<LoginPage> createState() => _LoginPageState();
// // }

// // class _LoginPageState extends State<LoginPage> {

// //     @override
// //     Widget build(BuildContext context) {
// //         return Scaffold (
// //             appBar: AppBar(title: const Text('Task List')),
// //             body: Container(
// //                 child: ListView(
// //                     children: 
// //                 )
// //             )
// //         )
// //     }
    
// // }


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
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
  }
  
  void _devQuickLogin() {
    widget.onLogin({
      'username': 'testuser',
      'name': 'Test User',
    });
  }

  void login() async {
    setState(() {
      _isLoading = true;
      error = '';
    });
    
    final username = _controller.text;
    final baseUrl = _getBaseUrl();
    final url = Uri.parse('$baseUrl/api/users/$username/');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        widget.onLogin(data);
      } else {
        setState(() => error = 'User not found');
      }
    } catch (e) {
      setState(() => error = 'Connection error: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  String _getBaseUrl() {
    // Choose the appropriate URL
    return 'http://127.0.0.1:8001';
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
            child: _isLoading 
              ? CircularProgressIndicator(color: Colors.white)
              : Text("Log in", style: TextStyle(fontSize: 16)),
          ),
          if (error.isNotEmpty) 
            Padding(
              padding: EdgeInsets.only(top: 20),
              child: Text(error, style: TextStyle(color: Colors.red)),
            ),
          SizedBox(height: 20),
          OutlinedButton(
            onPressed: _devQuickLogin,
            child: Text("DEV: Login as testuser"),
          ),
        ],
      ),
    );
  }
}