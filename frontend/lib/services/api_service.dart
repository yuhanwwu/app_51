import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://app-51-web.onrender.com'; 

  // -------- USER METHODS --------

  Future<Map<String, dynamic>?> getUser(String username) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$username/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return null; // user not found
  }

  Future<bool> createUser(String username, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'username': username, 'name': name}),
    );
    return response.statusCode == 201;
  }

  // -------- REPEAT TASKS METHODS --------

  Future<List<dynamic>> getRepeatTasksForUser(String username) async {
    final response = await http.get(Uri.parse('$baseUrl/repeat-tasks/'));
    if (response.statusCode == 200) {
      List allTasks = json.decode(response.body);
      return allTasks.where((task) => task['assignedto'] == username).toList();
    }
    return [];
  }

  Future<bool> createRepeatTask(Map<String, dynamic> taskData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/repeat-tasks/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(taskData),
    );
    return response.statusCode == 201;
  }

  // Fetch all repeat tasks
  Future<List<dynamic>> getAllRepeatTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/repeat-tasks/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  }

  // -------- ONE OFF TASKS METHODS --------

  Future<List<dynamic>> getOneOffTasksForUser(String username) async {
    final response = await http.get(Uri.parse('$baseUrl/one-off-tasks/'));
    if (response.statusCode == 200) {
      List allTasks = json.decode(response.body);
      return allTasks.where((task) => task['assignedto'] == username).toList();
    }
    return [];
  }

  Future<bool> createOneOffTask(Map<String, dynamic> taskData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/one-off-tasks/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(taskData),
    );
    return response.statusCode == 201;
  }
  // Fetch all one-off tasks
  Future<List<dynamic>> getAllOneOffTasks() async {
    final response = await http.get(Uri.parse('$baseUrl/one-off-tasks/'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return [];
  } 

  // Add more methods like updateTask, deleteTask, markTaskDone, etc. as needed
}
