import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/project.dart';
import '../models/task.dart';
import '../models/user.dart';

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

        // Check for error in response even if status is 200
        if (data.containsKey('error')) {
          throw Exception('Server error: ${data['error']}');
        }

        if (!data.containsKey('projects')) {
          throw Exception('Invalid response format: missing projects field');
        }

        final projectsList = data['projects'] as List;
        final projects = projectsList.map((projectJson) {
          try {
            return Project.fromJson(projectJson as Map<String, dynamic>);
          } catch (e) {
            print('Error parsing project: $projectJson');
            print('Parse error: $e');
            rethrow;
          }
        }).toList();

        return projects;
      } else {
        final errorMessage = 'Failed to load projects: ${response.statusCode}';
        print('HTTP Error: $errorMessage');
        print('Response body: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Error fetching projects: $e');
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

  Future<Map<String, dynamic>> getTask(String projectId, String taskId) async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId/tasks/$taskId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['task'];
      } else {
        throw Exception('Failed to load task');
      }
    } catch (e) {
      throw Exception('Error fetching task: $e');
    }
  }

  // Dashboard and Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Check if there's an error in the response
        if (data.containsKey('error')) {
          return {
            'has_error': true,
            'error_message': data['error'],
            ...data, // Include the existing stats even if there's an error
          };
        }
        return data;
      } else {
        throw Exception(
          'Failed to load dashboard stats: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching dashboard stats: $e');
    }
  }

  // User Management (Admin only)
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        return List<Map<String, dynamic>>.from(data['users'] ?? []);
      } else if (response.statusCode == 500) {
        final errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Server error occurred');
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  Future<void> updateUserRole(int userId, String role) async {
    try {
      final headers = await getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/users/$userId/role'),
        headers: headers,
        body: json.encode({'role': role}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update user role');
      }
    } catch (e) {
      throw Exception('Error updating user role: $e');
    }
  }

  Future<void> deleteUser(int userId) async {
    try {
      final headers = await getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete user');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  // Profile Management
  Future<User> updateProfile(
    String name,
    String email,
    String? currentPassword,
    String? newPassword,
  ) async {
    try {
      final headers = await getHeaders();
      final Map<String, dynamic> body = {'name': name, 'email': email};

      if (currentPassword != null && newPassword != null) {
        body['current_password'] = currentPassword;
        body['new_password'] = newPassword;
      }

      final response = await http.put(
        Uri.parse('$baseUrl/profile'),
        headers: headers,
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return User.fromJson(data['user']);
      } else {
        final error = json.decode(response.body);
        throw Exception(error['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // System Health (Admin only)
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/health'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to load system health');
      }
    } catch (e) {
      throw Exception('Error fetching system health: $e');
    }
  }

  // System Logs (Admin only)
  Future<List<Map<String, dynamic>>> getSystemLogs() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/logs'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['logs']);
      } else {
        throw Exception('Failed to load logs');
      }
    } catch (e) {
      throw Exception('Error fetching logs: $e');
    }
  }

  // Get managers list (for project assignment)
  Future<List<Map<String, dynamic>>> getManagers() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/managers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['managers']);
      } else {
        throw Exception('Failed to load managers');
      }
    } catch (e) {
      throw Exception('Error fetching managers: $e');
    }
  }

  // Get employees list (for task assignment)
  Future<List<Map<String, dynamic>>> getEmployees() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/users/employees'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        return List<Map<String, dynamic>>.from(data['employees'] ?? []);
      } else {
        throw Exception('Failed to load employees: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching employees: $e');
    }
  }

  // Get team members based on user role
  Future<Map<String, dynamic>> getTeamMembers() async {
    try {
      final headers = await getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/team/members'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('error')) {
          throw Exception(data['error']);
        }
        return data;
      } else {
        throw Exception('Failed to load team members: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching team members: $e');
    }
  }

  // Test database connections
  Future<Map<String, dynamic>> testDatabaseConnections() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/test-connections'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to test connections: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error testing database connections: $e');
    }
  }
}
