import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'login_page.dart';
import 'signup_page.dart';
import 'home_page.dart';
import 'add_task_page.dart';
import 'settings_page.dart';
import 'personal_goal_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('darkMode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool darkMode) async {
    setState(() {
      _isDarkMode = darkMode;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', darkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Scheduler',
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/add_task': (context) => AddTaskPage(onTaskAdded: () {}),
        '/settings': (context) => SettingsPage(onThemeChanged: _toggleTheme),
        '/personal_goals': (context) => const PersonalGoalsPage(),
      },
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final baseTheme = ThemeData(brightness: brightness);
    
    final primaryColor = brightness == Brightness.light
        ? const Color(0xFF0E6990)
        : const Color(0xFF64B5F6);
    const secondaryColor = Color(0xFF10A37F);
    
    final backgroundColor = brightness == Brightness.light
        ? const Color(0xFFF7F7F8)
        : const Color(0xFF121212);
    
    final textColor = brightness == Brightness.light
        ? Colors.black87
        : Colors.white70;
    
    return ThemeData(
      brightness: brightness,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: MaterialColor(primaryColor.value, {
          50: primaryColor.withOpacity(0.1),
          100: primaryColor.withOpacity(0.2),
          200: primaryColor.withOpacity(0.3),
          300: primaryColor.withOpacity(0.4),
          400: primaryColor.withOpacity(0.5),
          500: primaryColor,
          600: primaryColor.withOpacity(0.7),
          700: primaryColor.withOpacity(0.8),
          800: primaryColor.withOpacity(0.9),
          900: primaryColor.withOpacity(1),
        }),
        brightness: brightness,
      ).copyWith(
        secondary: secondaryColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF1E1E1E),
        iconTheme: IconThemeData(color: primaryColor),
        titleTextStyle: TextStyle(
          color: primaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'SFProM',
        ),
      ),
      cardTheme: CardTheme(
        color: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF2C2C2C),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.bold,
          fontFamily: 'SFProM',
        ),
        bodyLarge: TextStyle(
          color: textColor,
          fontFamily: 'SFProMed',
        ),
        bodyMedium: TextStyle(
          color: textColor.withOpacity(0.8),
          fontFamily: 'SFProMed',
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? Colors.grey[100]
            : const Color(0xFF2C2C2C),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: secondaryColor),
        ),
        labelStyle: TextStyle(color: textColor.withOpacity(0.8)),
        hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
      ),
      iconTheme: IconThemeData(color: primaryColor),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return secondaryColor;
          }
          return brightness == Brightness.light ? Colors.grey[300]! : Colors.grey[700]!;
        }),
        trackColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
          if (states.contains(WidgetState.selected)) {
            return secondaryColor.withOpacity(0.5);
          }
          return brightness == Brightness.light ? Colors.grey[200]! : Colors.grey[600]!;
        }),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: brightness == Brightness.light
            ? Colors.white
            : const Color(0xFF2C2C2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      fontFamily: 'SFProMed',
    );
  }
}