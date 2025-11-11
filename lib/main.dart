// --- lib/main.dart (FINAL FULL UPDATED CODE) ---

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:overlay_support/overlay_support.dart';
import 'firebase_options.dart';
import 'auth_gate.dart';
import 'notification_service.dart'; // <-- Import the new service

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize the Notification Service
  await NotificationService.initialize();

  runApp(const SentryGasApp());
}

class SentryGasApp extends StatelessWidget {
  const SentryGasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'Sentry Gas',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF1A202C),
          scaffoldBackgroundColor: const Color(0xFF1A202C),
          textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        home: const AuthGate(),
      ),
    );
  }
}