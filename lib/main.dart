import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/ryze_app.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ryze App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0B132B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const RyzeApp(),
    );
  }
}
