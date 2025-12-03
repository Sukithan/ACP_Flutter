import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/project.dart';
import '../models/task.dart';

class ApiService {
  // Change this to your Laravel backend URL
  // For Android emulator use: http://10.0.2.2:8000
  // For iOS simulator use: http://localhost:8000
  // For physical device use: http://YOUR_COMPUTER_IP:8000
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Projects
  Future<List<Project>> getProjects() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/projects'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final projects = (data['projects'] as List)
            .map((json) => Project.fromJson(json))
            .toList();
        return projects;
      } else {
        throw Exception('Failed to load projects: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching projects: $e');
    }
  }

  Future<Map<String, dynamic>> getProject(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/projects/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['project'];
      } else {
        throw Exception('Failed to load project');
      }
    } catch (e) {
      throw Exception('Error fetching project: $e');
    }
  }

  Future<Project> createProject({
    required String name,
    required String description,
    required String status,
    int? assignedManager,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/projects'),
        headers: headers,
        body: json.encode({
          'name': name,
          'description': description,
          'status': status,
          if (assignedManager != null) 'assigned_manager': assignedManager,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Project.fromJson(data['project']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create project');
      }
    } catch (e) {
      throw Exception('Error creating project: $e');
    }
  }

  Future<void> updateProject(
    String id, {
    String? name,
    String? description,
    String? status,
    int? assignedManager,
  }) async {
    try {
      final headers = await getHeaders();
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (status != null) body['status'] = status;
      if (assignedManager != null) body['assigned_manager'] = assignedManager;

      final response = await http.put(
        Uri.parse('$baseUrl/projects/$id'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update project');
      }
    } catch (e) {
      throw Exception('Error updating project: $e');
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/projects/$id'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete project');
      }
    } catch (e) {
      throw Exception('Error deleting project: $e');
    }
  }

  // Tasks
  Future<List<Task>> getTasks() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/tasks'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tasks = (data['tasks'] as List)
            .map((json) => Task.fromJson(json))
            .toList();
        return tasks;
      } else {
        throw Exception('Failed to load tasks');
      }
    } catch (e) {
      throw Exception('Error fetching tasks: $e');
    }
  }

  Future<Task> createTask({
    required String projectId,
    required String title,
    required String description,
    required int assignedTo,
    String? dueDate,
    required String priority,
    required String status,
  }) async {
    try {
      final headers = await getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/tasks'),
        headers: headers,
        body: json.encode({
          'title': title,
          'description': description,
          'assigned_to': assignedTo,
          'due_date': dueDate,
          'priority': priority,
          'status': status,
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Task.fromJson(data['task']);
      } else {
        final errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to create task');
      }
    } catch (e) {
      throw Exception('Error creating task: $e');
    }
  }

  Future<void> updateTask(
    String projectId,
    String taskId, {
    String? title,
    String? description,
    int? assignedTo,
    String? dueDate,
    String? priority,
    String? status,
  }) async {
    try {
      final headers = await getHeaders();
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (assignedTo != null) body['assigned_to'] = assignedTo;
      if (dueDate != null) body['due_date'] = dueDate;
      if (priority != null) body['priority'] = priority;
      if (status != null) body['status'] = status;

      final response = await http.put(
        Uri.parse('$baseUrl/projects/$projectId/tasks/$taskId'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update task');
      }
    } catch (e) {
      throw Exception('Error updating task: $e');
    }
  }

  Future<void> deleteTask(String projectId, String taskId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/projects/$projectId/tasks/$taskId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete task');
      }
    } catch (e) {
      throw Exception('Error deleting task: $e');
    }
  }
}
