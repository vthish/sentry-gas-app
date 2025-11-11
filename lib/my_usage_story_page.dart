// --- lib/my_usage_story_page.dart (FIXED LoopAnimationBuilder and TabBar) ---
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
// NEW IMPORT for background animation
import 'package:simple_animations/simple_animations.dart';

class MyUsageStoryPage extends StatefulWidget {
  final String currentHubId;
  const MyUsageStoryPage({super.key, required this.currentHubId});

  @override
  State<MyUsageStoryPage> createState() => _MyUsageStoryPageState();
}

class _MyUsageStoryPageState extends State<MyUsageStoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  BoxDecoration _glassmorphismDecoration() {
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
        width: 1.5,
      ),
    );
  }

  // --- UPDATED: Animated Background Widget (uses LoopAnimationBuilder) ---
  Widget _buildAnimatedBackground() {
    // Define the color tweens
    final tween1 = TweenSequence([
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.blue.shade900,
          end: Colors.purple.shade900,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.purple.shade900,
          end: Colors.teal.shade900,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.teal.shade900,
          end: Colors.blue.shade900,
        ),
        weight: 1,
      ),
    ]);

    final tween2 = TweenSequence([
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.pink.shade900,
          end: Colors.cyan.shade900,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.cyan.shade900,
          end: Colors.indigo.shade900,
        ),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: ColorTween(
          begin: Colors.indigo.shade900,
          end: Colors.pink.shade900,
        ),
        weight: 1,
      ),
    ]);

    // Use LoopAnimationBuilder
    return LoopAnimationBuilder<Color?>(
      tween: tween1, // First color tween
      duration: const Duration(seconds: 20),
      builder: (context, color1, child) {
        return LoopAnimationBuilder<Color?>(
          tween: tween2, // Second color tween
          duration: const Duration(seconds: 25),
          builder: (context, color2, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color1 ?? Colors.blue.shade900,
                    const Color(0xFF1A202C), // Center dark color
                    color2 ?? Colors.pink.shade900,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "My Usage Story",
          style: GoogleFonts.inter(
              color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        // --- UPDATED: TabBar ---
        bottom: TabBar(
          controller: _tabController,
          // --- REMOVED: backgroundColor: Colors.transparent, ---
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: "This Week"),
            Tab(text: "Last 6 Months"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(), // The animation
          TabBarView(
            controller: _tabController,
            children: [
              _buildThisWeekTab(),
              _buildMonthlyListTab(),
              _buildHistoryListTab(),
            ],
          ),
        ],
      ),
    );
  }

  // --- Tab 1: This Week ---
  Widget _buildThisWeekTab() {
    final List<double> weeklyUsage = [150, 120, 180, 90, 200, 160, 140];
    final double totalUsageGrams = weeklyUsage.reduce((a, b) => a + b);
    final double totalUsageKg = totalUsageGrams / 1000;
    final double dailyAverageGrams = totalUsageGrams / weeklyUsage.length;
    final int daysUsed = 8;

    final List<Color> liquidPalette = [
      Colors.blue.shade400,
      Colors.purple.shade300,
      Colors.teal.shade300,
      Colors.pink.shade300,
      Colors.green.shade300,
      Colors.cyan.shade400,
      Colors.orange.shade300,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // 1. Pie Chart
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedIndex = -1;
                        return;
                      }
                      _touchedIndex =
                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sections: List.generate(7, (index) {
                  final color = liquidPalette[index % liquidPalette.length];
                  final bool isTouched = (index == _touchedIndex);
                  final double radius = isTouched ? 70.0 : 60.0;

                  return PieChartSectionData(
                    value: weeklyUsage[index],
                    radius: radius,
                    showTitle: false,
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.7),
                        color.withOpacity(1.0),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1.5,
                    ),
                  );
                }),
                sectionsSpace: 3,
                centerSpaceRadius: 40,
              ),
            ),
          ).animate().scale(),

          const SizedBox(height: 30),

          // 2. Summary Text
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _glassmorphismDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Total used: ${totalUsageKg.toStringAsFixed(1)}kg",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Daily average: ${dailyAverageGrams.toStringAsFixed(0)}g",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "You've been using this cylinder for $daysUsed days.",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fade().slideY(begin: 0.2),

          const SizedBox(height: 30),

          // 3. Daily List
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 7,
            itemBuilder: (context, index) {
              final days = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
              final color = liquidPalette[index % liquidPalette.length];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withOpacity(0.2),
                  child: Text(days[index][0],
                      style: GoogleFonts.inter(color: color)),
                ),
                title:
                    Text(days[index], style: GoogleFonts.inter(color: Colors.white)),
                trailing: Text("${weeklyUsage[index].toInt()}g",
                    style: GoogleFonts.inter(
                        color: Colors.white70, fontWeight: FontWeight.w600)),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- Tab 2: Last 6 Months ---
  Widget _buildMonthlyListTab() {
    final List<Map<String, String>> monthlyUsageData = [
      {'month': 'October', 'usage': '11.2 kg', 'value': '11.2'},
      {'month': 'September', 'usage': '10.5 kg', 'value': '10.5'},
      {'month': 'August', 'usage': '12.1 kg', 'value': '12.1'},
      {'month': 'July', 'usage': '9.8 kg', 'value': '9.8'},
      {'month': 'June', 'usage': '10.1 kg', 'value': '10.1'},
      {'month': 'May', 'usage': '11.5 kg', 'value': '11.5'},
    ];

    final List<double> usageValues = monthlyUsageData
        .map((data) => double.tryParse(data['value']!) ?? 0)
        .toList();
    final double monthlyAverageKg =
        usageValues.reduce((a, b) => a + b) / usageValues.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _glassmorphismDecoration(),
            child: Column(
              children: [
                Text(
                  "Monthly average: ${monthlyAverageKg.toStringAsFixed(1)}kg",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  "Based on the last 6 months of data.",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ).animate().fade().slideY(begin: 0.2),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(24.0),
            itemCount: monthlyUsageData.length,
            separatorBuilder: (context, index) =>
                const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: const Icon(Icons.calendar_today, color: Colors.white54),
                title: Text(
                  monthlyUsageData[index]['month']!,
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 18),
                ),
                trailing: Text(
                  monthlyUsageData[index]['usage']!,
                  style:
                      GoogleFonts.inter(color: Colors.blue.shade300, fontSize: 16),
                ),
              ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }

  // --- Tab 3: Cylinder History ---
  Widget _buildHistoryListTab() {
    final List<Map<String, String>> cylinderHistory = [
      {'date': 'Connected: Oct 15, 2025', 'duration': 'Used for 32 days', 'value': '32'},
      {'date': 'Connected: Sep 12, 2025', 'duration': 'Used for 33 days', 'value': '33'},
      {'date': 'Connected: Aug 09, 2025', 'duration': 'Used for 34 days', 'value': '34'},
      {'date': 'Connected: Jul 07, 2025', 'duration': 'Used for 32 days', 'value': '32'},
    ];

    final List<int> durationValues = cylinderHistory
        .map((data) => int.tryParse(data['value']!) ?? 0)
        .toList();
    final double avgDuration =
        durationValues.reduce((a, b) => a + b) / durationValues.length;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: _glassmorphismDecoration(),
            child: Column(
              children: [
                Text(
                  "Average cylinder lifespan: ${avgDuration.toStringAsFixed(0)} days",
                  style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  "Based on your last ${durationValues.length} cylinders.",
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ).animate().fade().slideY(begin: 0.2),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(24.0),
            itemCount: cylinderHistory.length,
            separatorBuilder: (context, index) =>
                const Divider(color: Colors.white10),
            itemBuilder: (context, index) {
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading:
                    const Icon(Icons.history_toggle_off, color: Colors.white54),
                title: Text(
                  cylinderHistory[index]['date']!,
                  style: GoogleFonts.inter(
                      color: Colors.white, fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  cylinderHistory[index]['duration']!,
                  style: GoogleFonts.inter(color: Colors.white70),
                ),
              ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.2);
            },
          ),
        ),
      ],
    );
  }
}