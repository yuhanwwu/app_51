import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'models/user.dart';
import 'screens/user_tasks.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? user;

  void onLogin(User loggedInUser) {
    setState(() {
      user = loggedInUser;
    });

    // if (user != null) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomePage(user: user!)),
    );
    //}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: user == null ? LoginPage(onLogin: onLogin) : HomePage(user: user!),
    );
  }
}

class HomePage extends StatelessWidget {
  final User user;

  const HomePage({Key? key, required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Welcome ${user.name}')),
      body: Center(child: Text('You are logged in as ${user.username}')),
    );
  }
}
