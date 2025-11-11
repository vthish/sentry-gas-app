// --- lib/hub_settings_page.dart (UPDATED with "Liquid Crystal" UI) ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'custom_toast.dart'; 
import 'auth_gate.dart';
import 'page_transitions.dart';
import 'dart:ui'; // For ImageFilter.blur
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_animations/simple_animations.dart'; // For Background

class HubSettingsPage extends StatefulWidget {
  final String currentHubId;

  const HubSettingsPage({super.key, required this.currentHubId});

  @override
  State<HubSettingsPage> createState() => _HubSettingsPageState();
}

class _HubSettingsPageState extends State<HubSettingsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _hubNameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadHubName();
  }

  @override
  void dispose() {
    _hubNameController.dispose();
    super.dispose();
  }

  // --- (Load/Save functions remain the same) ---
  Future<void> _loadHubName() async {
    if (widget.currentHubId == "DEMO_HUB") {
      _hubNameController.text = "Demo Hub";
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }
    try {
      DocumentSnapshot hubDoc =
          await _firestore.collection('hubs').doc(widget.currentHubId).get();
      if (hubDoc.exists) {
        String currentName =
            (hubDoc.data() as Map<String, dynamic>)['hubName'] ?? 'My Hub';
        _hubNameController.text = currentName;
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, "Error loading hub name: $e", isError: true);
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveHubName() async {
    if (_hubNameController.text.isEmpty) {
      showCustomToast(context, "Hub name cannot be empty", isError: true);
      return;
    }
    if (widget.currentHubId == "DEMO_HUB") {
      showCustomToast(context, "Cannot change Demo Hub name", isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _firestore
          .collection('hubs')
          .doc(widget.currentHubId)
          .update({'hubName': _hubNameController.text.trim()});
      if (mounted) {
        showCustomToast(context, "Hub name updated successfully!");
        Navigator.pop(context); 
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, "Error saving name: $e", isError: true);
      }
    }
    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  void _showDeleteConfirmationDialog() {
    final bool isDemo = (widget.currentHubId == "DEMO_HUB");
    if (isDemo) {
      showCustomToast(context, "You cannot remove the Demo Hub", isError: true);
      return;
    }
    // --- UPDATED: Dialog with Glassmorphism ---
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.2)),
          ),
          title: Text("Remove Hub?",
              style: GoogleFonts.inter(color: Colors.red.shade300)),
          content: Text(
              "Are you sure you want to remove this hub? This action cannot be undone.",
              style: GoogleFonts.inter(color: Colors.white70)),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); 
                _removeHub(); 
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: const Text("Yes, Remove Hub"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeHub() async {
    setState(() => _isDeleting = true);
    final String? uid = _auth.currentUser?.uid;

    if (uid == null) {
      showCustomToast(context, "Error: Not authenticated", isError: true);
      setState(() => _isDeleting = false);
      return;
    }

    DocumentReference userDocRef = _firestore.collection('users').doc(uid);
    DocumentReference hubDocRef =
        _firestore.collection('hubs').doc(widget.currentHubId);

    try {
      DocumentSnapshot hubDoc = await hubDocRef.get();
      DocumentSnapshot userDoc = await userDocRef.get();

      String ownerId = '';
      if (hubDoc.exists) {
        Map<String, dynamic>? hubData = hubDoc.data() as Map<String, dynamic>?;
        ownerId = hubData?['ownerId'] ?? '';
      }

      // Step 1: Update User Document (Remove Hub ID)
      if (userDoc.exists) {
        await userDocRef.update({
          'hubIds': FieldValue.arrayRemove([widget.currentHubId])
        });
      }

      // Step 2: Delete Hub Document (If Owner)
      if (hubDoc.exists && ownerId == uid) {
        await hubDocRef.delete();
      }

      if (mounted) {
        showCustomToast(context, "Hub removal processed!");
        Navigator.of(context).pushAndRemoveUntil(
          FadePageRoute(builder: (context) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        showCustomToast(context, "Error removing hub: ${e.toString()}",
            isError: true);
      }
      setState(() => _isDeleting = false);
    }
  }
  // --- End of Functions ---

  // --- NEW: Blue-Only Animated Background ---
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

  // --- NEW: Glassmorphism Decoration Helper ---
  BoxDecoration _glassmorphismCardDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          Colors.white.withOpacity(0.1),
          Colors.white.withOpacity(0.05),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
    );
  }
  // --- End of Helper ---

  @override
  Widget build(BuildContext context) {
    final bool isDemo = (widget.currentHubId == "DEMO_HUB");

    return Scaffold(
      // --- UPDATED: Transparent background ---
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
            onPressed: () => Navigator.of(context).pop()),
        title: Text("Hub Settings",
            style: GoogleFonts.inter(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      // --- UPDATED: Use Stack for background ---
      body: Stack(
        children: [
          _buildAnimatedBackground(),
          
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white))
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Hub Name",
                                  style: GoogleFonts.inter(
                                      color: Colors.white70, fontSize: 16))
                              .animate()
                              .fadeIn(delay: 100.ms)
                              .slideX(begin: -0.1),
                          
                          const SizedBox(height: 12),

                          // --- UPDATED: Glassmorphism TextField ---
                          TextField(
                            controller: _hubNameController,
                            enabled: !isDemo,
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.1),
                              hintText: "e.g., Home Gas, Kitchen Hub",
                              hintStyle: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.3)),
                              // Crystal border
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.blue.shade400),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 200.ms)
                              .slideX(begin: 0.1),

                          if (isDemo)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: Text(
                                "The Demo Hub name cannot be changed.",
                                style: GoogleFonts.inter(
                                    color: Colors.orange.shade300, fontSize: 14),
                              ),
                            ),
                          
                          const Spacer(),

                          // --- UPDATED: Save Button (Glass Style) ---
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue.withOpacity(0.2), // Glass Fill
                                side: BorderSide(color: Colors.blue.shade400), // Crystal Border
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: (_isSaving || isDemo || _isDeleting)
                                  ? null
                                  : _saveHubName,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 3),
                                    )
                                  : Text(
                                      "SAVE CHANGES",
                                      style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white),
                                    ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 400.ms)
                              .slideY(begin: 0.2),

                          const SizedBox(height: 20),
                          
                          // --- UPDATED: Remove Hub Button (Destructive Glass Style) ---
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.red.withOpacity(0.1), // Destructive Glass Fill
                                side: BorderSide(color: Colors.red.shade400), // Destructive Crystal Border
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              onPressed: (_isSaving || isDemo || _isDeleting)
                                  ? null
                                  : _showDeleteConfirmationDialog,
                              icon: _isDeleting
                                  ? const SizedBox.shrink()
                                  : Icon(Icons.delete_outline,
                                      color: Colors.red.shade300),
                              label: _isDeleting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          color: Colors.red, strokeWidth: 3),
                                    )
                                  : Text(
                                      "Remove Hub",
                                      style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red.shade300),
                                    ),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 500.ms)
                              .slideY(begin: 0.2),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}