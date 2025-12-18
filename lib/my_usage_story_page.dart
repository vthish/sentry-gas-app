import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:simple_animations/simple_animations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
        colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
    );
  }

  Widget _buildAnimatedBackground() {
    final tween1 = TweenSequence([
      TweenSequenceItem(tween: ColorTween(begin: Colors.blue.shade900, end: Colors.purple.shade900), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: Colors.purple.shade900, end: Colors.teal.shade900), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: Colors.teal.shade900, end: Colors.blue.shade900), weight: 1),
    ]);
    final tween2 = TweenSequence([
      TweenSequenceItem(tween: ColorTween(begin: Colors.pink.shade900, end: Colors.cyan.shade900), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: Colors.cyan.shade900, end: Colors.indigo.shade900), weight: 1),
      TweenSequenceItem(tween: ColorTween(begin: Colors.indigo.shade900, end: Colors.pink.shade900), weight: 1),
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
                  colors: [color1 ?? Colors.blue.shade900, const Color(0xFF1A202C), color2 ?? Colors.pink.shade900],
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

  // Helper to determine color based on usage amount
  Color _getUsageColor(double usage) {
    if (usage <= 0) return Colors.white54;
    if (usage < 100) return Colors.greenAccent; // Low usage
    if (usage < 300) return Colors.orangeAccent; // Medium usage
    return Colors.redAccent; // High usage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A202C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("My Usage Story", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          indicatorWeight: 3,
          labelColor: Colors.cyanAccent,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          tabs: const [Tab(text: "Week"), Tab(text: "Month"), Tab(text: "Full History")],
        ),
      ),
      body: Stack(
        children: [
          _buildAnimatedBackground(),
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

  // --- TAB 1: WEEKLY ---
  Widget _buildThisWeekTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('hubs').doc(widget.currentHubId).collection('cylinder_events')
          .orderBy('date', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snapshot) {
        List<double> weeklyUsage = List.filled(7, 0.0);
        List<String> days = List.filled(7, "");
        double totalUsageGrams = 0;

        DateTime now = DateTime.now();

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
           for (int i = 0; i < 7; i++) {
            DateTime d = now.subtract(Duration(days: i));
            String dateKey = DateFormat('yyyy-MM-dd').format(d);
            String dayName = DateFormat('E').format(d);
            days[i] = dayName;

            try {
              var docList = snapshot.data!.docs.where((element) {
                var data = element.data() as Map<String, dynamic>;
                return data['date'] == dateKey && (data.containsKey('usage') || data['event'] == 'Daily Usage');
              });

              if (docList.isNotEmpty) {
                var doc = docList.first;
                var data = doc.data() as Map<String, dynamic>;
                var val = data['usage'];
                double usage = 0.0;
                if (val is int) usage = val.toDouble();
                else if (val is double) usage = val;
                
                weeklyUsage[i] = usage;
                totalUsageGrams += usage;
              }
            } catch (e) {
              weeklyUsage[i] = 0.0;
            }
          }
        } else {
           for (int i = 0; i < 7; i++) {
             DateTime d = now.subtract(Duration(days: i));
             days[i] = DateFormat('E').format(d);
           }
        }

        final double totalUsageKg = totalUsageGrams / 1000;
        final double dailyAverageGrams = weeklyUsage.any((e) => e > 0) 
            ? totalUsageGrams / weeklyUsage.where((e) => e > 0).length 
            : 0;

        final List<Color> liquidPalette = [
          Colors.cyanAccent, Colors.purpleAccent, Colors.tealAccent,
          Colors.pinkAccent, Colors.greenAccent, Colors.lightBlueAccent, Colors.orangeAccent,
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(
                height: 200, // Reduced height
                child: PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sections: List.generate(7, (index) {
                      final color = liquidPalette[index % liquidPalette.length];
                      final bool isTouched = (index == _touchedIndex);
                      // Reduced Radius size (Was 80/65 -> Now 60/50)
                      final double radius = isTouched ? 60.0 : 50.0;
                      double val = weeklyUsage[index] <= 0 ? 0.001 : weeklyUsage[index]; 

                      return PieChartSectionData(
                        value: val,
                        radius: radius,
                        showTitle: false,
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.6), color.withOpacity(1.0)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 2),
                      );
                    }),
                    sectionsSpace: 4,
                    centerSpaceRadius: 40, 
                  ),
                ),
              ).animate().scale(duration: 600.ms),
              
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(24),
                decoration: _glassmorphismDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Total Used (7 Days)", style: GoogleFonts.inter(color: Colors.white54, fontSize: 14), textAlign: TextAlign.center),
                    const SizedBox(height: 4),
                    Text("${totalUsageKg.toStringAsFixed(2)} kg",
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 12),
                    Text("Daily Average: ${dailyAverageGrams.toStringAsFixed(0)} g",
                        style: GoogleFonts.inter(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                  ],
                ),
              ).animate().fade().slideY(begin: 0.3),
              
              const SizedBox(height: 20),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final color = liquidPalette[index % liquidPalette.length];
                  double usageVal = weeklyUsage[index];
                  
                  // Color coding logic
                  Color usageColor = _getUsageColor(usageVal);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 40, height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          shape: BoxShape.circle
                        ),
                        child: Text(days[index].isNotEmpty ? days[index][0] : "-", style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(days[index], style: GoogleFonts.inter(color: Colors.white)),
                      trailing: Text(
                        "${usageVal.toStringAsFixed(0)} g",
                        style: GoogleFonts.inter(
                          color: usageColor, 
                          fontWeight: FontWeight.bold, 
                          fontSize: 16
                        )
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 2: MONTHLY ---
  Widget _buildMonthlyListTab() {
    return FutureBuilder<QuerySnapshot>(
      future: _db.collection('hubs').doc(widget.currentHubId).collection('cylinder_events')
          .orderBy('date', descending: true).limit(100).get(),
      builder: (context, snapshot) {
        Map<String, double> monthlyData = {};
        
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            if (!data.containsKey('usage') || !data.containsKey('date')) continue;

            String dateStr = data['date']; 
            try {
              DateTime date = DateTime.parse(dateStr);
              String monthKey = DateFormat('MMMM yyyy').format(date);
              var val = data['usage'];
              double usage = (val is int) ? val.toDouble() : (val is double ? val : 0.0);

              monthlyData[monthKey] = (monthlyData[monthKey] ?? 0.0) + usage;
            } catch (e) {}
          }
        }

        List<MapEntry<String, double>> sortedList = monthlyData.entries.toList();
        
        // Empty State
        if (sortedList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.calendar_month_rounded, color: Colors.white24, size: 50),
                ),
                const SizedBox(height: 16),
                Text("No monthly data available", style: GoogleFonts.inter(color: Colors.white38)),
              ],
            ).animate().fade().scale(),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: sortedList.length,
          itemBuilder: (context, index) {
            String month = sortedList[index].key;
            double kg = sortedList[index].value / 1000;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: _glassmorphismDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.date_range_rounded, color: Colors.cyanAccent.withOpacity(0.8), size: 28),
                      const SizedBox(width: 16),
                      Text(month, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                    ],
                  ),
                  Text("${kg.toStringAsFixed(1)} kg",
                      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
            ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.2);
          },
        );
      },
    );
  }

  // --- TAB 3: HISTORY WITH TIME ---
  Widget _buildHistoryListTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('hubs').doc(widget.currentHubId).collection('cylinder_events')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        
        var allDocs = snapshot.data?.docs ?? [];
        
        if (allDocs.isEmpty) {
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, color: Colors.white24, size: 60),
              const SizedBox(height: 16),
              Text("No history data yet.", style: GoogleFonts.inter(color: Colors.white38)),
            ],
          ));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24.0),
          itemCount: allDocs.length,
          itemBuilder: (context, index) {
            var data = allDocs[index].data() as Map<String, dynamic>;
            
            // --- TIME LOGIC ---
            Timestamp? timestamp = data['timestamp'] as Timestamp?;
            String dateString = data['date'] ?? 'Unknown';
            
            DateTime dateTime;
            String timeDisplay;

            if (timestamp != null) {
              dateTime = timestamp.toDate();
              timeDisplay = DateFormat('hh:mm a').format(dateTime); 
            } else {
              try { dateTime = DateTime.parse(dateString); } catch(e) { dateTime = DateTime.now(); }
              timeDisplay = "All Day"; 
            }

            String dayNum = DateFormat('dd').format(dateTime);
            String monthStr = DateFormat('MMM').format(dateTime).toUpperCase();

            // --- VALUE LOGIC ---
            bool isUsage = (data.containsKey('usage') || (data['event'] == 'Daily Usage'));
            double value = 0.0;
            if (isUsage) {
               if (data.containsKey('usage')) {
                 var u = data['usage'];
                 value = (u is int) ? u.toDouble() : u;
               }
            } else {
               if (data.containsKey('weight')) {
                 var w = data['weight'];
                 value = (w is int) ? w.toDouble() : w;
               }
            }

            Color cardColor = isUsage ? const Color(0xFF1E293B) : const Color(0xFF064E3B);
            Color accentColor = isUsage ? Colors.orangeAccent : Colors.greenAccent;
            IconData icon = isUsage ? Icons.local_fire_department_rounded : Icons.propane_tank_rounded;
            String title = isUsage ? "Gas Consumed" : "Refill Added";
            String valueStr = isUsage ? "- ${value.toStringAsFixed(0)} g" : "+ ${(value/1000).toStringAsFixed(2)} kg";

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 65,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.1))
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(dayNum, style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        Text(monthStr, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: accentColor, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 12, color: Colors.white54),
                                    const SizedBox(width: 4),
                                    Text(timeDisplay, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text(valueStr, style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fade().slideX();
          },
        );
      },
    );
  }
}