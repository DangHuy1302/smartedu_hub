import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/booking_screen.dart';
import 'screens/ocr_screen.dart';
import 'screens/pomodoro_screen.dart';
import 'screens/document_screen.dart';
import 'screens/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/booking': (context) => const BookingScreen(),
        '/ocr': (context) => const OcrScreen(),
        '/pomodoro': (context) => const PomodoroScreen(),
        '/document': (context) => const DocumentScreen(),
        '/profile': (context) => const UserProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
