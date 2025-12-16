
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
import 'my_usage_story_page.dart';
import 'daily_gas_budget_page.dart';
import 'hub_settings_page.dart';
import 'dart:ui'; // For ImageFilter.blur
import 'package:simple_animations/simple_animations.dart'; // For Background

class SettingsPage extends StatelessWidget {
  final String currentHubId;

  const SettingsPage({super.key, required this.currentHubId});


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


  void _showComingSoon(BuildContext context, String featureName) {
    showCustomToast(context, "$featureName is coming soon!");
  }


  Widget _buildAnimatedBackground() {
    final tween1 = TweenSequence([
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF0A1931), end: const Color(0xFF182848)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF182848), end: const Color(0xFF00334E)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF00334E), end: const Color(0xFF0A1931)),
          weight: 1),
    ]);
    final tween2 = TweenSequence([
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF0A2342), end: const Color(0xFF182848)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF182848), end: const Color(0xFF0A1931)),
          weight: 1),
      TweenSequenceItem(
          tween: ColorTween(
              begin: const Color(0xFF0A1931), end: const Color(0xFF0A2342)),
          weight: 1),
    ]);
    return LoopAnimationBuilder<Color?>(
      tween: tween1,
      duration: const Duration(seconds: 20),
      builder: (context, color1, child) {
        return LoopAnimationBuilder<Color?>(
          tween: tween2,
          duration: const Duration(seconds: 25),
          builder: (context, color2, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color1 ?? const Color(0xFF0A1931),
                    const Color(0xFF1A202C),
                    color2 ?? const Color(0xFF0A2342),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            );
          },
        );
      },
    );
  }



  BoxDecoration _glassmorphismButtonDecoration({bool isDestructive = false, bool isPrimary = false}) {
    
    if (isPrimary) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.blue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.shade300.withOpacity(0.5),
          width: 1.5,
        ),
      );
    }

    if (isDestructive) {
      return BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.2),
            Colors.red.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
      );
    }
    
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop()),
        title: Text("Settings & More",
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(), 

          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [

                  Container(
                    margin: const EdgeInsets.only(bottom: 30),
                    decoration: _glassmorphismButtonDecoration(isPrimary: true),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                      leading: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                      title: Text("Connect Another Hub",
                          style: GoogleFonts.inter(
                              color: Colors.white, fontWeight: FontWeight.w600)),
                      subtitle: Text("Add a new Sentry device",
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                      onTap: () => Navigator.push(
                          context, FadePageRoute(builder: (context) => const ConnectHubPage())),
                    ),
                  )

                  .animate()
                  .fadeIn(duration: 300.ms, delay: 0.ms, curve: Curves.easeOut)
                  .slideX(begin: 0.3, duration: 400.ms, curve: Curves.easeOut),



                  _buildSettingsButton(context,
                      icon: Icons.person_outline,
                      title: "My Profile",
                      onTap: () => Navigator.push(context,
                          FadePageRoute(builder: (context) => const MyProfilePage())),
                      delay: 50), // Faster delay

                  _buildSettingsButton(context,
                      icon: Icons.settings_input_component_outlined,
                      title: "Hub Settings",
                      onTap: () => Navigator.push(
                          context,
                          FadePageRoute(
                              builder: (context) =>
                                  HubSettingsPage(currentHubId: currentHubId))),
                      delay: 100), 

                  _buildSettingsButton(context,
                      icon: Icons.people_outline,
                      title: "Share with Family",
                      onTap: () => Navigator.push(
                          context,
                          FadePageRoute(
                              builder: (context) =>
                                  ShareWithFamilyPage(currentHubId: currentHubId))),
                      delay: 150), 

                  _buildSettingsButton(context,
                      icon: Icons.notifications_outlined,
                      title: "Notification Alerts",
                      onTap: () => Navigator.push(
                          context,
                          FadePageRoute(
                              builder: (context) => const NotificationAlertsPage())),
                      delay: 200), 

                  _buildSettingsButton(context,
                      icon: Icons.attach_money_outlined,
                      title: "Daily Gas Budget",
                      onTap: () => Navigator.push(
                          context,
                          FadePageRoute(
                              builder: (context) =>
                                  DailyGasBudgetPage(currentHubId: currentHubId))),
                      delay: 250), 

                  _buildSettingsButton(context,
                      icon: Icons.history_outlined,
                      title: "My Usage Story",
                      onTap: () => Navigator.push(
                          context,
                          FadePageRoute(
                              builder: (context) =>
                                  MyUsageStoryPage(currentHubId: currentHubId))),
                      delay: 300), 

                  _buildSettingsButton(context,
                      icon: Icons.help_outline,
                      title: "Help Center",
                      onTap: () => _showComingSoon(context, "Help Center"),
                      delay: 350), 
                  
                  const SizedBox(height: 40),
                  
                  _buildSettingsButton(context,
                      icon: Icons.logout,
                      title: "Logout",
                      isDestructive: true,
                      onTap: () => _logout(context),
                      delay: 450), 
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSettingsButton(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      bool isDestructive = false,
      required int delay}) {
    
    final Color iconColor = isDestructive ? Colors.red.shade300 : Colors.blue.shade300;
    final Color textColor = isDestructive ? Colors.red.shade300 : Colors.white;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: iconColor.withOpacity(0.1),
            highlightColor: iconColor.withOpacity(0.2),
            child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                decoration: _glassmorphismButtonDecoration(isDestructive: isDestructive),
                child: Row(children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 20),
                  Expanded(
                      child: Text(title,
                          style: GoogleFonts.inter(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w500))),
                  Icon(Icons.chevron_right,
                      color: isDestructive
                          ? Colors.red.shade300.withOpacity(0.5)
                          : Colors.white54)
                ])),
          ),
        ),
      ),
    )

    .animate()
    .fadeIn(duration: 300.ms, delay: delay.ms, curve: Curves.easeOut) // Faster fade
    .slideX(
      begin: 0.3, // Start a bit further
      duration: 400.ms, // Faster slide
      delay: delay.ms, // Apply same delay
      curve: Curves.easeOut, // Smooth curve
    );
  }
}
