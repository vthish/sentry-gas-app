// --- lib/settings_page.dart (FINAL FULL UPDATED CODE) ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'page_transitions.dart';
import 'auth_gate.dart';
import 'custom_toast.dart';
import 'notification_alerts_page.dart';
import 'connect_hub_page.dart';
import 'my_profile_page.dart';
import 'share_with_family_page.dart';
import 'my_usage_story_page.dart'; // <-- නව Import එක

class SettingsPage extends StatelessWidget {
  final String currentHubId;

  const SettingsPage({super.key, required this.currentHubId});

  // Logout Function
  Future<void> _logout(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
         Navigator.of(context).pushAndRemoveUntil(
          FadePageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
        showCustomToast(context, "Logged out successfully.");
      }
    } catch (e) {
       if (context.mounted) {
        showCustomToast(context, "Error logging out: $e", isError: true);
       }
    }
  }

  // Placeholder for future pages
  void _showComingSoon(BuildContext context, String featureName) {
    showCustomToast(context, "$featureName is coming soon!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70), onPressed: () => Navigator.of(context).pop()),
        title: Text("Settings & More", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // --- Connect New Hub Button ---
            Container(
              margin: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(color: Colors.blue.shade900.withOpacity(0.3), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.blue.shade400)),
              child: ListTile(
                leading: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                title: Text("Connect Another Hub", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                subtitle: Text("Add a new Sentry device", style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => Navigator.push(context, FadePageRoute(builder: (context) => const ConnectHubPage())),
              ),
            ).animate().fade().scale(),

            // --- Settings Links ---
            _buildSettingsButton(context, icon: Icons.person_outline, title: "My Profile",
              onTap: () => Navigator.push(context, FadePageRoute(builder: (context) => const MyProfilePage())), delay: 100),

            _buildSettingsButton(context, icon: Icons.people_outline, title: "Share with Family",
              onTap: () => Navigator.push(context, FadePageRoute(builder: (context) => ShareWithFamilyPage(currentHubId: currentHubId))), delay: 200),

            _buildSettingsButton(context, icon: Icons.notifications_outlined, title: "Notification Alerts",
              onTap: () => Navigator.push(context, FadePageRoute(builder: (context) => const NotificationAlertsPage())), delay: 300),

             _buildSettingsButton(context, icon: Icons.attach_money_outlined, title: "Daily Gas Budget", onTap: () => _showComingSoon(context, "Gas Budget"), delay: 400),

            // **** යාවත්කාලීන කළ බොත්තම ****
            _buildSettingsButton(context, icon: Icons.history_outlined, title: "My Usage Story",
              onTap: () => Navigator.push(context, FadePageRoute(builder: (context) => MyUsageStoryPage(currentHubId: currentHubId))), delay: 500),

             _buildSettingsButton(context, icon: Icons.help_outline, title: "Help Center", onTap: () => _showComingSoon(context, "Help Center"), delay: 600),
            const SizedBox(height: 40),
            _buildSettingsButton(context, icon: Icons.logout, title: "Logout", isDestructive: true, onTap: () => _logout(context), delay: 700),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap, bool isDestructive = false, required int delay}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20), decoration: BoxDecoration(color: isDestructive ? Colors.red.shade900.withOpacity(0.2) : const Color(0xFF2D3748), borderRadius: BorderRadius.circular(16), border: Border.all(color: isDestructive ? Colors.red.shade900.withOpacity(0.5) : Colors.white.withOpacity(0.05))), child: Row(children: [Icon(icon, color: isDestructive ? Colors.red.shade300 : Colors.blue.shade300, size: 28), const SizedBox(width: 20), Expanded(child: Text(title, style: GoogleFonts.inter(color: isDestructive ? Colors.red.shade300 : Colors.white, fontSize: 18, fontWeight: FontWeight.w500))), Icon(Icons.chevron_right, color: isDestructive ? Colors.red.shade300.withOpacity(0.5) : Colors.white54)]))),
    ).animate().fade(delay: delay.ms).slideX(begin: 0.2);
  }
}