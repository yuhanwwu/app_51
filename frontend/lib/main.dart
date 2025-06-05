import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/screens/home_page.dart';
import 'package:frontend/screens/questionnaire.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/login.dart';
import 'models/user.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

enum AppPage { login, questionnaire, home }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  User? user;
  AppPage currentPage = AppPage.login;
  String? questionnaireUsername;

  Timer? _nudgeTimer;
  Timestamp? _lastCheckedNudge;

  @override
  void initState() {
    super.initState();
  }

  void _startNudgePolling() {
    _nudgeTimer?.cancel();
    _lastCheckedNudge = Timestamp.now();
    _nudgeTimer = Timer.periodic(const Duration(seconds: 30), (_) => _checkForNudges());
  }

  void _stopNudgePolling() {
    _nudgeTimer?.cancel();
  }

  Future<void> _checkForNudges() async {
    if (user == null) return;
    final query = await FirebaseFirestore.instance
        .collection('Nudges')
        .where('userId', isEqualTo: user!.username)
        .where('timestamp', isGreaterThan: _lastCheckedNudge ?? Timestamp(0, 0))
        .get();

    if (query.docs.isNotEmpty) {
      // Show a notification for each new nudge
      for (var doc in query.docs) {
        final taskId = doc['taskId'];
        // Fetch the task description from Firestore
        final taskSnap = await FirebaseFirestore.instance
            .collection('Tasks')
            .doc(taskId)
            .get();
        String description = 'a task';
        if (taskSnap.exists) {
          final taskData = taskSnap.data() as Map<String, dynamic>;
          description = taskData['description'] ?? 'a task';
        }
      
      }
      // Update last checked time
      _lastCheckedNudge = Timestamp.now();
    }
  }

  @override
  void dispose() {
    _stopNudgePolling();
    super.dispose();
  }

  Future<void> onLogin(User loggedInUser) async {
    setState(() {
      user = loggedInUser;
    });

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.username)
        .get();

    final data = doc.data() as Map<String, dynamic>;
    final questionnaireDone = data['questionnaireDone'] == true;

    if (!questionnaireDone) {
      setState(() {
        currentPage = AppPage.questionnaire;
        questionnaireUsername = user!.username;
      });
    } else {
      setState(() {
        currentPage = AppPage.home;
      });
    }

     _startNudgePolling();
  }

  void onQuestionnaireComplete(User updatedUser) {
    setState(() {
      user = updatedUser;
      currentPage = AppPage.home;
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (currentPage) {
      case AppPage.login:
        page = LoginPage(onLogin: onLogin);
        break;
      case AppPage.questionnaire:
        page = QuestionnairePage(
          username: questionnaireUsername!,
          onComplete: onQuestionnaireComplete,
        );
        break;
      case AppPage.home:
        page = HomePage(user: user!);
        break;
    }
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: page,
    );
  }
}
