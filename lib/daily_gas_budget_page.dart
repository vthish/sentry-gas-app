// --- lib/daily_gas_budget_page.dart (UPDATED with "Liquid Crystal" UI) ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // For number input formatting
import 'custom_toast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui'; // For ImageFilter.blur
import 'package:simple_animations/simple_animations.dart'; // For Background

class DailyGasBudgetPage extends StatefulWidget {
  final String currentHubId;
  const DailyGasBudgetPage({super.key, required this.currentHubId});

  @override
  State<DailyGasBudgetPage> createState() => _DailyGasBudgetPageState();
}

class _DailyGasBudgetPageState extends State<DailyGasBudgetPage> {
  final TextEditingController _budgetController = TextEditingController();
  bool _autoTurnOff = false;
  bool _isLoading = true;

  late String _budgetKey;
  late String _autoTurnOffKey;

  @override
  void initState() {
    super.initState();
    _budgetKey = 'budget_${widget.currentHubId}';
    _autoTurnOffKey = 'autoTurnOff_${widget.currentHubId}';
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _budgetController.text = prefs.getString(_budgetKey) ?? '150'; // Default 150g
      _autoTurnOff = prefs.getBool(_autoTurnOffKey) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_budgetController.text.isEmpty) {
      showCustomToast(context, "Please enter a budget amount", isError: true);
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_budgetKey, _budgetController.text);
    await prefs.setBool(_autoTurnOffKey, _autoTurnOff);

    // In a real app, you would also send this to Firestore/Hub
    // ...

    if (mounted) {
      showCustomToast(context, "Budget settings saved!");
      Navigator.pop(context); // Go back to Settings page
    }
  }

  // --- NEW: "Dark Blue" Animated Background ---
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
  // --- End of Animated Background ---

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
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: Colors.white.withOpacity(0.2),
        width: 1,
      ),
    );
  }
  // --- End of Helper ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- UPDATED: Use transparent background ---
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Daily Gas Budget",
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      // --- UPDATED: Use Stack for background ---
      body: Stack(
        children: [
          _buildAnimatedBackground(), // <-- The animation

          // --- UPDATED: Add BackdropFilter for frosted glass effect ---
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          // --- UPDATED: Budget Amount Glass Card ---
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: _glassmorphismCardDecoration(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Daily gas budget (grams)",
                                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _budgetController,
                                  style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    suffixText: "g",
                                    suffixStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 32),
                                    border: InputBorder.none,
                                    filled: false,
                                    // Change textfield color to be more glassy
                                    fillColor: Colors.white.withOpacity(0.1), 
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2))
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Colors.blue.shade400)
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic),

                          const SizedBox(height: 24),

                          // --- UPDATED: Auto-turn off Glass Card ---
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: _glassmorphismCardDecoration(),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.power_settings_new, color: Colors.blue.shade300),
                              title: Text(
                                "Auto-turn off when over budget",
                                style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              trailing: Switch(
                                value: _autoTurnOff,
                                onChanged: (newValue) {
                                  setState(() => _autoTurnOff = newValue);
                                },
                                activeColor: Colors.green,
                                inactiveTrackColor: Colors.white.withOpacity(0.1),
                                inactiveThumbColor: Colors.white54,
                                trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                              ),
                            ),
                          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic),
                          
                          const Spacer(),

                          // --- UPDATED: Glass Save Button ---
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                               style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.blue.withOpacity(0.2),
                                side: BorderSide(color: Colors.blue.shade400),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _saveSettings,
                              child: Text(
                                "SAVE",
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, curve: Curves.easeOutCubic),
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