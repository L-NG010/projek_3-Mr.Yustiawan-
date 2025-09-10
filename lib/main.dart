// main.dart
import 'package:flutter/material.dart';
import 'components/header.dart';
import 'sections/body.dart';
import 'screen/auth_screen.dart';
import 'connect.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isLoggedIn = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    // Check initial auth status
    await _checkAuthStatus();
    
    // Listen for auth state changes
    _authSubscription = DatabaseConfig.client.auth.onAuthStateChange.listen((data) {
      print('Auth state changed: ${data.event}'); // Debug log
      
      final session = data.session;
      final isLoggedIn = session != null;
        
      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _isLoading = false;
        });
      }
      
      // Debug logs
      print('Session exists: ${session != null}');
      print('User email: ${session?.user.email}');
      print('Is logged in: $isLoggedIn');
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    try {
      final session = DatabaseConfig.client.auth.currentSession;
      print('Initial session check - User: ${session?.user.email}'); // Debug log
      
      if (mounted) {
        setState(() {
          _isLoggedIn = session != null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking auth status: $e');
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('AuthWrapper build - Loading: $_isLoading, LoggedIn: $_isLoggedIn'); // Debug log
    
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return _isLoggedIn ? const MainApp() : const LoginScreen();
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Header(),
      body: const Body(),
    );
  }
}