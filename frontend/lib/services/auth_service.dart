import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8000/api';
  final _storage = const FlutterSecureStorage();

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Store the Bearer token
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(
          key: 'user_data',
          value: json.encode(data['user']),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        // Store the Bearer token
        await _storage.write(key: 'auth_token', value: data['token']);
        await _storage.write(
          key: 'user_data',
          value: json.encode(data['user']),
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
      }
    } catch (e) {
      print('Logout error: $e');
    } finally {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'user_data');
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'auth_token');
    return token != null;
  }

  Future<User?> getCurrentUser() async {
    try {
      final userDataString = await _storage.read(key: 'user_data');
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Get user error: $e');
      return null;
    }
  }

  Future<void> updateCurrentUser(User user) async {
    try {
      await _storage.write(key: 'user_data', value: json.encode(user.toJson()));
    } catch (e) {
      print('Update user error: $e');
      throw Exception('Failed to update user data');
    }
  }
}
