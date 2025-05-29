import 'dart:convert';
import 'package:http/http.dart' as http;

class Task {
  final String description;
  final bool isOneOff;
  final bool? priority; //one off
  final String? lastdoneon; //repeat

  Task({
    required this.description, 
    this.priority, 
    this.lastdoneon, 
    this.isOneOff = false, //default is repeated
  });

  factory Task.fromJson(Map<String, dynamic> json, {bool isOneOff = false}) {
    return Task(
      description: json['description'],
      priority: isOneOff ? json['priority'] : null,
      lastdoneon: isOneOff ? null : json['lastdoneon'],
      isOneOff: isOneOff,
    );
  }
}


//TODO maybe tasks only come up when they are freq no. days after last done?