// // // // // login page

// // // // import 'dart:convert';
// // // // import 'package:flutter/material.dart';
// // // // import 'package:flutter/services.dart' show rootBundle;

// // // // Future<Map<String, dynamic>> loadJson() async {
// // // //   final String response = await rootBundle.loadString('assets/data.json');
// // // //   return json.decode(response);
// // // // }

// // // // class LoginPage extends StatefulWidget {
// // // //   final Function(String) onLogin;
// // // //   LoginPage({required this.onLogin});

// // // //   @override
// // // //   _LoginPageState createState() => _LoginPageState();
// // // // }

// // // // class _LoginPageState extends State<LoginPage> {
// // // //   final _usernameController = TextEditingController();
// // // //   final _passwordController = TextEditingController();
// // // //   String error = '';

// // // //   void login() async {
// // // //     final data = await loadJson();
// // // //     final username = _usernameController.text.trim();
// // // //     final password = _passwordController.text.trim();

// // // //     if (data.containsKey(username) && data[username] == password) {
// // // //       widget.onLogin(username); // Callback to parent on success
// // // //     } else {
// // // //       setState(() {
// // // //         error = 'Invalid username or password!';
// // // //       });
// // // //     }
// // // //   }

// // // //   @override
// // // //   Widget build(BuildContext context) {
// // // //     return Scaffold(
// // // //       appBar: AppBar(title: Text('Login')),
// // // //       body: Padding(
// // // //         padding: const EdgeInsets.all(20.0),
// // // //         child: Column(
// // // //           children: [
// // // //             TextField(
// // // //               controller: _usernameController,
// // // //               decoration: InputDecoration(labelText: 'Username'),
// // // //             ),
// // // //             TextField(
// // // //               controller: _passwordController,
// // // //               decoration: InputDecoration(labelText: 'Password'),
// // // //               obscureText: true,
// // // //             ),
// // // //             SizedBox(height: 20),
// // // //             ElevatedButton(
// // // //               onPressed: login,
// // // //               child: Text('Login'),
// // // //             ),
// // // //             if (error.isNotEmpty) ...[
// // // //               SizedBox(height: 10),
// // // //               Text(error, style: TextStyle(color: Colors.red)),
// // // //             ]
// // // //           ],
// // // //         ),
// // // //       ),
// // // //     );
// // // //   }
// // // // }


// // // // // // screens/login_page.dart
// // // // // import 'package:flutter/material.dart';
// // // // // import 'package:http/http.dart' as http;
// // // // // import 'dart:convert';

// // // // // class LoginPage extends StatefulWidget {
// // // // //   final Function onLogin;
// // // // //   LoginPage({required this.onLogin});
  
// // // // //   @override
// // // // //   _LoginPageState createState() => _LoginPageState();
// // // // // }

// // // // // class _LoginPageState extends State<LoginPage> {
// // // // //   final _controller = TextEditingController();
// // // // //   String error = '';

// // // // // //   void login() async {
// // // // // //     final username = _controller.text;
// // // // // //     final url = Uri.parse('https://app-51-web.onrender.com/api/users/$username/');



// // // // // //     try {
// // // // // //       final response = await http.get(url);
// // // // // //       if (response.statusCode == 200) {
// // // // // //         final data = jsonDecode(response.body);
// // // // // //         widget.onLogin(data);
// // // // // //       } else {
// // // // // //         setState(() => error = 'User not found');
// // // // // //       }
// // // // // //     } catch (e) {
// // // // // //       setState(() => error = 'Connection error');
// // // // // //     }
// // // // // //   }
// // // // // void login() async {
// // // // // final username = _controller.text.trim();
// // // // // final url = Uri.parse('https://app-51-web.onrender.com/api/login/');

// // // // // try {
// // // // //     final response = await http.post(
// // // // //     url,
// // // // //     headers: {'Content-Type': 'application/json'},
// // // // //     body: jsonEncode({'username': username}),
// // // // //     );

// // // // //     if (response.statusCode == 200) {
// // // // //     final data = jsonDecode(response.body);
// // // // //     widget.onLogin(data); // Pass user data to the parent
// // // // //     } else if (response.statusCode == 404) {
// // // // //     setState(() => error = 'User not found');
// // // // //     } else {
// // // // //     setState(() => error = 'Login failed');
// // // // //     }
// // // // // } catch (e) {
// // // // //     setState(() => error = 'Connection error');
// // // // // }
// // // // // }

// // // // // void fetchAllUsers() async {
// // // // //   final url = Uri.parse('https://app-51-web.onrender.com/api/users/');
// // // // //   try {
// // // // //     final response = await http.get(url);
// // // // //     if (response.statusCode == 200) {
// // // // //       final List users = jsonDecode(response.body);
// // // // //       print('All users:');
// // // // //       for (var user in users) {
// // // // //         print('Username: ${user['username']}, Name: ${user['name']}');
// // // // //       }
// // // // //     } else {
// // // // //       print('Failed to load users. Status: ${response.statusCode}');
// // // // //     }
// // // // //   } catch (e) {
// // // // //     print('Error fetching users: $e');
// // // // //   }
// // // // // }

// // // // // @override
// // // // // void initState() {
// // // // //   super.initState();
// // // // //   fetchAllUsers();  // This prints users in your debug console when page loads
// // // // // }

// // // // //   @override
// // // // //   Widget build(BuildContext context) {
// // // // //     return Column(
// // // // //       children: [
// // // // //         TextField(controller: _controller, decoration: InputDecoration(labelText: 'Username')),
// // // // //         ElevatedButton(onPressed: login, child: Text("Log in")),
// // // // //         if (error.isNotEmpty) Text(error, style: TextStyle(color: Colors.red)),
// // // // //       ],
// // // // //     );
// // // // //   }
// // // // // }

// // // // // // import 'package:flutter/material.dart';

// // // // // // class LoginPage extends StatefulWidget {
// // // // // //     const LoginPage({super.key, required this.title});

// // // // // //     final String title;

// // // // // //     @override
// // // // // //     State<LoginPage> createState() => _LoginPageState();
// // // // // // }

// // // // // // class _LoginPageState extends State<LoginPage> {

// // // // // //     @override
// // // // // //     Widget build(BuildContext context) {
// // // // // //         return Scaffold (
// // // // // //             appBar: AppBar(title: const Text('Task List')),
// // // // // //             body: Container(
// // // // // //                 child: ListView(
// // // // // //                     children: 
// // // // // //                 )
// // // // // //             )
// // // // // //         )
// // // // // //     }
    
// // // // // // }


// // // import 'dart:convert';
// // // import 'package:flutter/material.dart';
// // // import 'package:http/http.dart' as http;

// // // import '../models/user.dart';

// // // class LoginPage extends StatefulWidget {
// // //   final Function(User) onLogin;
// // //   LoginPage({required this.onLogin});

// // //   @override
// // //   _LoginPageState createState() => _LoginPageState();
// // // }

// // // class _LoginPageState extends State<LoginPage> {
// // //   final _usernameController = TextEditingController();
// // //   final _passwordController = TextEditingController();
// // //   String error = '';

// // //   void login() async {
// // //     final data = await loadJson();
// // //     final username = _usernameController.text.trim();

// // //     // If users is a list of strings
// // //     if (data['users'] != null && data['users'].contains(username)) {
// // //         widget.onLogin(username); // Pass username on success
// // //     }
// // //     // If users is a map with usernames as keys
// // //     else if (data.containsKey(username)) {
// // //         widget.onLogin(username); // Pass username on success
// // //     } 
// // //     else {
// // //         setState(() {
// // //         error = 'Username not found!';
// // //         });
// // //     }
// // //     }


// // //   @override
// // //   Widget build(BuildContext context) {
// // //     return Scaffold(
// // //       appBar: AppBar(title: Text('Login')),
// // //       body: Padding(
// // //         padding: const EdgeInsets.all(20),
// // //         child: Column(
// // //           children: [
// // //             TextField(
// // //               controller: _usernameController,
// // //               decoration: InputDecoration(labelText: 'Username'),
// // //             ),
// // //             // TextField(
// // //             //   controller: _passwordController,
// // //             //   decoration: InputDecoration(labelText: 'Password'),
// // //             //   obscureText: true,
// // //             // ),
// // //             SizedBox(height: 20),
// // //             ElevatedButton(onPressed: login, child: Text('Login')),
// // //             if (error.isNotEmpty)
// // //               Padding(
// // //                 padding: const EdgeInsets.only(top: 12),
// // //                 child: Text(error, style: TextStyle(color: Colors.red)),
// // //               ),
// // //           ],
// // //         ),
// // //       ),
// // //     );
// // //   }
// // // }

// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:flutter/services.dart' show rootBundle;

// // class LoginPage extends StatefulWidget {
// //   final Function(String) onLogin;
// //   LoginPage({required this.onLogin});

// //   @override
// //   _LoginPageState createState() => _LoginPageState();
// // }

// // class _LoginPageState extends State<LoginPage> {
// //   final _usernameController = TextEditingController();
// //   String error = '';

// //   Future<Map<String, dynamic>> loadJson() async {
// //     final String response = await rootBundle.loadString('assets/data.json');
// //     return json.decode(response);
// //   }

// //   void login() async {
// //     final data = await loadJson();
// //     final username = _usernameController.text.trim();

// //     // Check if username exists in the list of user objects
// //     if (data['users'] != null) {
// //       final users = data['users'] as List;
// //       final userExists = users.any((user) =>
// //           user is Map<String, dynamic> &&
// //           user['username'] == username);

// //       if (userExists) {
// //         widget.onLogin(username);
// //         return;
// //       }
// //     }

// //     setState(() {
// //       error = 'Username not found!';
// //     });
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       appBar: AppBar(title: Text('Login')),
// //       body: Padding(
// //         padding: const EdgeInsets.all(20.0),
// //         child: Column(
// //           children: [
// //             TextField(
// //               controller: _usernameController,
// //               decoration: InputDecoration(labelText: 'Username'),
// //             ),
// //             SizedBox(height: 20),
// //             ElevatedButton(
// //               onPressed: login,
// //               child: Text('Login'),
// //             ),
// //             if (error.isNotEmpty) ...[
// //               SizedBox(height: 10),
// //               Text(error, style: TextStyle(color: Colors.red)),
// //             ],
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// // }


// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart' show rootBundle;
// import '../models/user.dart';

// class LoginPage extends StatefulWidget {
//   final Function(User) onLogin;

//   const LoginPage({Key? key, required this.onLogin}) : super(key: key);

//   @override
//   _LoginPageState createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {
//   final TextEditingController _usernameController = TextEditingController();
//   String? error;

//   Future<Map<String, dynamic>> loadJson() async {
//     final jsonString = await rootBundle.loadString('assets/data.json');
//     return json.decode(jsonString);
//   }

//   void login() async {
//     setState(() {
//       error = null;
//     });

//     final username = _usernameController.text.trim();

//     if (username.isEmpty) {
//       setState(() {
//         error = 'Please enter a username';
//       });
//       return;
//     }

//     final data = await loadJson();

//     if (data['users'] != null) {
//       final users = data['users'] as List<dynamic>;

//       final userMap = users.firstWhere(
//         (user) => user['username'] == username,
//         orElse: () => null,
//       );

//       if (userMap != null) {
//         final user = User.fromJson(userMap);
//         widget.onLogin(user);
//         return;
//       }
//     }

//     setState(() {
//       error = 'Username not found';
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Login')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(
//               controller: _usernameController,
//               decoration: const InputDecoration(labelText: 'Username'),
//             ),
//             const SizedBox(height: 12),
//             ElevatedButton(
//               onPressed: login,
//               child: const Text('Log In'),
//             ),
//             if (error != null)
//               Padding(
//                 padding: const EdgeInsets.only(top: 12),
//                 child: Text(error!, style: const TextStyle(color: Colors.red)),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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
  String? error;

  Future<Map<String, dynamic>> loadJson() async {
    final jsonString = await rootBundle.loadString('assets/data.json');
    return json.decode(jsonString);
  }

  void login() async {
    setState(() {
      error = null;
    });

    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      setState(() {
        error = 'Please enter a username';
      });
      return;
    }

    final data = await loadJson();

    // if (data['users'] != null) {
    //   final users = data['users'] as List<dynamic>;

    //   final userMap = users.firstWhere(
    //     (user) => user['username'] == username,
    //     orElse: () => null, // 
    //   );

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

      // if (userMap != null) {
      //   final user = User.fromJson(userMap);
      //   widget.onLogin(user);
      //   return;
      // }

    // setState(() {
    //   error = 'Username not found';
    // });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: login,
              child: const Text('Log In'),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
    );
  }
}
