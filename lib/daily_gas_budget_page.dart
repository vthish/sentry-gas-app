// --- lib/daily_gas_budget_page.dart (NEW FILE) ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart'; // For number input formatting
import 'custom_toast.dart';
import 'package:shared_preferences/shared_preferences.dart'; // To save settings
import 'package:flutter_animate/flutter_animate.dart';

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

  // Key for saving data, unique per Hub
  late String _budgetKey;
  late String _autoTurnOffKey;

  @override
  void initState() {
    super.initState();
    // Create unique keys for the specific hub
    _budgetKey = 'budget_${widget.currentHubId}';
    _autoTurnOffKey = 'autoTurnOff_${widget.currentHubId}';
    _loadSettings();
  }

  // Load saved settings from local storage
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _budgetController.text = prefs.getString(_budgetKey) ?? '150'; // Default 150g
      _autoTurnOff = prefs.getBool(_autoTurnOffKey) ?? false;
      _isLoading = false;
    });
  }

  // Save settings to local storage
  Future<void> _saveSettings() async {
    if (_budgetController.text.isEmpty) {
      showCustomToast(context, "Please enter a budget amount", isError: true);
      return;
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_budgetKey, _budgetController.text);
    await prefs.setBool(_autoTurnOffKey, _autoTurnOff);

    // In a real app, you would also send this to Firestore/Hub
    // await FirebaseFirestore.instance.collection('hubs').doc(widget.currentHubId).update({
    //   'dailyBudget': int.parse(_budgetController.text),
    //   'autoTurnOffBudget': _autoTurnOff,
    // });

    if (mounted) {
      showCustomToast(context, "Budget settings saved!");
      Navigator.pop(context); // Go back to Settings page
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // --- Budget Amount Input ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
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
                            ),
                          ),
                        ],
                      ),
                    ).animate().fade().slideY(begin: 0.2),

                    const SizedBox(height: 24),

                    // --- Auto-turn off Switch ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Auto-turn off when over budget",
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: _autoTurnOff,
                            onChanged: (newValue) {
                              setState(() => _autoTurnOff = newValue);
                            },
                            activeColor: Colors.green,
                            inactiveTrackColor: Colors.white.withOpacity(0.1),
                            inactiveThumbColor: Colors.white54,
                            trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                          ),
                        ],
                      ),
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
                    
                    const Spacer(),

                    // --- Save Button ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          "SAVE",
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ).animate().fade(delay: 400.ms),
                  ],
                ),
              ),
            ),
    );
  }
}