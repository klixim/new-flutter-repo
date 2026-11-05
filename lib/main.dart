import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация сервиса авторизации и базы данных
  final authService = AuthService();
  await authService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter RuStore App with Auth',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005FF9), // RuStore blue accent
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005FF9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      // Динамический переключатель экранов на основе состояния авторизации
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return ListenableBuilder(
      listenable: authService,
      builder: (context, _) {
        if (authService.isAuthenticated) {
          // Экран после успешной авторизации: Имя, список из БД, кнопка Выйти
          return const HomeScreen();
        } else {
          // Экран входа: Кнопки GitHub, Gmail, Apple, Yandex, VK
          return const LoginScreen();
        }
      },
    );
  }
}
