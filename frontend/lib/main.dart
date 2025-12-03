import 'package:flutter/material.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/projects/project_detail_screen.dart';
import 'screens/projects/create_project_screen.dart';
import 'screens/tasks/task_detail_screen.dart';
import 'screens/tasks/create_task_screen.dart';
import 'screens/admin/users_screen.dart';
import 'screens/admin/health_screen.dart';
import 'screens/admin/logs_screen.dart';
import 'services/auth_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ACP Project',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: false,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());

          // Project Routes
          case '/projects':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/project-detail':
            final projectId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(projectId: projectId),
            );
          case '/create-project':
            return MaterialPageRoute(
              builder: (_) => const CreateProjectScreen(),
            );

          // Task Routes
          case '/tasks':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/task-detail':
            final args = settings.arguments as Map<String, String>;
            return MaterialPageRoute(
              builder: (_) => TaskDetailScreen(
                projectId: args['projectId']!,
                taskId: args['taskId']!,
              ),
            );
          case '/create-task':
            final projectId = settings.arguments as String;
            return MaterialPageRoute(
              builder: (_) => CreateTaskScreen(projectId: projectId),
            );

          // Admin Routes
          case '/admin/users':
            return MaterialPageRoute(builder: (_) => const UsersScreen());
          case '/admin/health':
            return MaterialPageRoute(builder: (_) => const HealthScreen());
          case '/admin/logs':
            return MaterialPageRoute(builder: (_) => const LogsScreen());

          default:
            return MaterialPageRoute(builder: (_) => const LoginScreen());
        }
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = AuthService();
    final isLoggedIn = await authService.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

// Placeholder for task detail screen
class TaskDetailPlaceholder extends StatelessWidget {
  final String projectId;
  final String taskId;

  const TaskDetailPlaceholder({
    super.key,
    required this.projectId,
    required this.taskId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Detail')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.task, size: 60),
            const SizedBox(height: 16),
            Text('Task ID: $taskId'),
            Text('Project ID: $projectId'),
            const SizedBox(height: 16),
            const Text('Task detail screen coming soon...'),
          ],
        ),
      ),
    );
  }
}
