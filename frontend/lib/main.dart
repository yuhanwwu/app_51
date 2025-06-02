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