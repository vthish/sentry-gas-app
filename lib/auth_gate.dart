

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

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1A202C),
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        if (snapshot.hasData) {

          return StreamBuilder<List<String>>(
            stream: HubService().streamUserHubs(), // <-- This relies on HubService
            builder: (context, hubSnapshot) {
              if (hubSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  backgroundColor: Color(0xFF1A202C),
                  body: Center(child: CircularProgressIndicator(color: Colors.white)),
                );
              }


              if (hubSnapshot.hasData && hubSnapshot.data!.isNotEmpty) {
                return MainDashboardPage(hubIds: hubSnapshot.data!);
              }


              return const ConnectHubPage();
            },
          );
        }


        return const LoginPage();
      },
    );
  }
}
