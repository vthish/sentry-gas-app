// --- lib/auth_gate.dart (FINAL FIXED - Using Stream) ---

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'hub_service.dart';
import 'main_dashboard_page.dart';
import 'connect_hub_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. User කෙනෙක් ලොග් වී සිටීදැයි බැලීම (Auth State)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A202C),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (snapshot.hasData) {
          // 2. User ලොග් වී ඇත්නම්, ඔහුගේ Hubs මොනවාදැයි එසැණින් බැලීම (Stream)
          return StreamBuilder<List<String>>(
            stream: HubService().streamUserHubs(), // <-- Future වෙනුවට Stream භාවිතා කිරීම
            builder: (context, hubSnapshot) {
              if (hubSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF1A202C),
                  body: Center(child: CircularProgressIndicator(color: Colors.white)),
                );
              }

              // Hubs තිබේ නම් Dashboard එකට
              if (hubSnapshot.hasData && hubSnapshot.data!.isNotEmpty) {
                return MainDashboardPage(hubIds: hubSnapshot.data!);
              }

              // Hubs නැත්නම් Connect Page එකට
              return const ConnectHubPage();
            },
          );
        }

        // 3. User ලොග් වී නැත්නම් Login Page එකට
        return const LoginPage();
      },
    );
  }
}