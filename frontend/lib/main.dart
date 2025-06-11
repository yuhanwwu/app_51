import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:frontend/constants/colors.dart';
import 'package:frontend/screens/noticeboard.dart';
import 'package:frontend/screens/task_page.dart';
import 'package:frontend/screens/questionnaire.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'screens/add_flat.dart';
import 'screens/login.dart';
import 'models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
  if (FirebaseAuth.instance.currentUser == null) {
    await FirebaseAuth.instance.signInAnonymously();
  }
  runApp(const MyApp());
}

enum AppPage { login, questionnaire, home, addFlat }

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlatUser? user;
  AppPage currentPage = AppPage.login;
  String? questionnaireUsername;
  String? pendingUsernameForFlat;
  DocumentReference? flatRef;

  Timer? _nudgeTimer;
  Timestamp? _lastCheckedNudge;

  @override
  void initState() {
    super.initState();
    _restoreUserSession();
  }

  Future<void> saveLoggedInUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('loggedInUsername', username);
  }

  Future<void> _restoreUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('loggedInUsername');

    if (savedUsername != null) {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(savedUsername)
          .get();

      if (doc.exists) {
        final userData = FlatUser.fromFirestore(doc);
        final data = doc.data()!;
        flatRef = data['flat'] as DocumentReference;
        final questionnaireDone = data['questionnaireDone'] == true;

        setState(() {
          user = userData;
          currentPage = questionnaireDone
              ? AppPage.home
              : AppPage.questionnaire;
          questionnaireUsername = savedUsername;
        });

        _startNudgePolling();
        return;
      }
    }

    // fallback to login if not found
    setState(() {
      currentPage = AppPage.login;
      user = null;
    });
  }

  void onLogout() async {
    await FirebaseAuth.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('loggedInUsername');
    setState(() {
      user = null;
      currentPage = AppPage.login;
    });
  }

  void onAddFlatRequest(String username) {
    setState(() {
      pendingUsernameForFlat = username;
      currentPage = AppPage.addFlat;
    });
  }

  void _startNudgePolling() {
    _nudgeTimer?.cancel();
    _lastCheckedNudge = Timestamp.now();
    _nudgeTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkForNudges(),
    );
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

  Future<void> onLogin(FlatUser loggedInUser) async {
    await saveLoggedInUsername(loggedInUser.username);
    setState(() {
      user = loggedInUser;
    });

    final doc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(user!.username)
        .get();

    final data = doc.data() as Map<String, dynamic>;
    final questionnaireDone = data['questionnaireDone'] == true;
    flatRef = data['flat'] as DocumentReference;
    // userRef = data['userRef'] as DocumentReference;

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

  void onQuestionnaireComplete(FlatUser updatedUser) {
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
        page = LoginPage(
          onLogin: onLogin,
          onAddFlat: onAddFlatRequest,
          onLogout: onLogout,
        );
        break;
      case AppPage.addFlat:
        page = AddFlatPage(
          username: pendingUsernameForFlat!,
          onLogin: onLogin,
          onLogout: onLogout,
          onBacktoLogin: () {
            setState(() {
              currentPage = AppPage.login;
            });
          },
        );
        break;
      case AppPage.questionnaire:
        page = QuestionnairePage(
          username: questionnaireUsername!,
          onComplete: onQuestionnaireComplete,
        );
        break;
      case AppPage.home:
        page = NoticeboardPage(
          user: user!,
          flatRef: flatRef!,
          userRef: user!.userRef,
          onLogout: onLogout,
        );
        break;
    }
    return MaterialApp(
      title: 'Task Manager',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(foregroundColor: AppColors.text),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.text),
          bodyMedium: TextStyle(color: AppColors.text),
          labelLarge: TextStyle(color: AppColors.accent),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: AppColors.accent),
        ),
      ),
      home: page,
    );
  }
}
