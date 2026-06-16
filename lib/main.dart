import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/ocr_screen.dart';
import 'screens/pomodoro_screen.dart';
import 'screens/document_screen.dart';

void main() {
  runApp(const SmartEduHubApp());
}

class SmartEduHubApp extends StatelessWidget {
  const SmartEduHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartEdu Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Initial route will be HomeScreen
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/booking': (context) => const BookingScreen(),
        '/ocr': (context) => const OcrScreen(),
        '/pomodoro': (context) => const PomodoroScreen(),
        '/document': (context) => const DocumentScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
