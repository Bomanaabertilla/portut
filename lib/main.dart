import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:portut/screens/create_post_screen.dart';
import 'package:portut/screens/login_screen.dart';
import 'package:portut/screens/home_screen.dart';
import 'package:portut/screens/password_reset_screen.dart';
import 'package:portut/screens/post_list_screen.dart';
import 'package:portut/screens/blog_post_screen.dart';
import 'package:portut/services/auth_service.dart';
import 'package:portut/utils/notifiers.dart';

void main() {
  runApp(
    ChangeNotifierProvider(create: (_) => statsNotifier, child: const MyApp()),
  );
}

// Global theme notifier (switches between light and dark)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'Portut App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            primaryColor: Colors.deepPurple,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              titleTextStyle: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardColor: Colors.grey[100],
            textTheme: TextTheme(
              bodyLarge: const TextStyle(color: Colors.black, fontSize: 18),
              bodyMedium: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
            iconTheme: const IconThemeData(color: Colors.black),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.light,
            ).copyWith(secondary: Colors.deepPurple, error: Colors.red),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primaryColor: Colors.deepPurple,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              titleTextStyle: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardColor: Colors.grey[900],
            textTheme: TextTheme(
              bodyLarge: TextStyle(color: Colors.white, fontSize: 18),
              bodyMedium: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ).copyWith(secondary: Colors.deepPurple, error: Colors.red),
            useMaterial3: true,
          ),
          themeMode: mode,
          home: const AuthWrapper(),
          routes: {
            '/reset': (context) => const PasswordResetScreen(),
            '/create': (context) => const CreatePostScreen(),
            '/posts': (context) => const PostListScreen(),
            '/blog': (context) => const BlogPostScreen(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final user = await _authService.getCurrentUser();
    if (mounted) {
      setState(() {
        _isLoggedIn = user != null;
        _isLoading = false;
      });
      if (user == null) {
        Provider.of<StatsNotifier>(context, listen: false).clearStats();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }
}
