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

//   void login() async {
//     final username = _controller.text;
//     final url = Uri.parse('https://app-51-web.onrender.com/api/users/$username/');



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
void login() async {
final username = _controller.text.trim();
final url = Uri.parse('https://app-51-web.onrender.com/api/login/');

try {
    final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'username': username}),
    );

    if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    widget.onLogin(data); // Pass user data to the parent
    } else if (response.statusCode == 404) {
    setState(() => error = 'User not found');
    } else {
    setState(() => error = 'Login failed');
    }
} catch (e) {
    setState(() => error = 'Connection error');
}
}

void fetchAllUsers() async {
  final url = Uri.parse('https://app-51-web.onrender.com/api/users/');
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

@override
void initState() {
  super.initState();
  fetchAllUsers();  // This prints users in your debug console when page loads
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