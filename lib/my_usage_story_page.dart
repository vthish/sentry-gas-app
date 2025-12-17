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
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.white54,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          tabs: const [Tab(text: "This Week"), Tab(text: "Monthly"), Tab(text: "History")],
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

  // --- TAB 1: Weekly Usage ---
  Widget _buildThisWeekTab() {
    return StreamBuilder<QuerySnapshot>(
      // Changed sorting to 'date' instead of timestamp
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
          Colors.blue.shade400, Colors.purple.shade300, Colors.teal.shade300,
          Colors.pink.shade300, Colors.green.shade300, Colors.cyan.shade400, Colors.orange.shade300,
        ];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              SizedBox(
                height: 200,
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
                      final double radius = isTouched ? 70.0 : 60.0;
                      double val = weeklyUsage[index] <= 0 ? 0.001 : weeklyUsage[index]; 

                      return PieChartSectionData(
                        value: val,
                        radius: radius,
                        showTitle: false,
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.7), color.withOpacity(1.0)],
                          begin: Alignment.topLeft, end: Alignment.bottomRight,
                        ),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.2), width: 1.5),
                      );
                    }),
                    sectionsSpace: 3,
                    centerSpaceRadius: 40,
                  ),
                ),
              ).animate().scale(),
              
              const SizedBox(height: 30),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: _glassmorphismDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text("Total used (7 days): ${totalUsageKg.toStringAsFixed(2)}kg",
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Text("Daily average: ${dailyAverageGrams.toStringAsFixed(0)}g",
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 16),
                        textAlign: TextAlign.center),
                  ],
                ),
              ).animate().fade().slideY(begin: 0.2),
              
              const SizedBox(height: 30),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 7,
                itemBuilder: (context, index) {
                  final color = liquidPalette[index % liquidPalette.length];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withOpacity(0.2),
                      child: Text(days[index].isNotEmpty ? days[index][0] : "-", style: GoogleFonts.inter(color: color)),
                    ),
                    title: Text(days[index].isNotEmpty ? "${days[index]} (Last 7 days)" : "Data N/A", style: GoogleFonts.inter(color: Colors.white)),
                    trailing: Text("${weeklyUsage[index].toStringAsFixed(0)}g",
                        style: GoogleFonts.inter(color: Colors.white70, fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --- TAB 2: Monthly Usage ---
  Widget _buildMonthlyListTab() {
    return FutureBuilder<QuerySnapshot>(
      // Changed sorting to 'date'
      future: _db.collection('hubs').doc(widget.currentHubId).collection('cylinder_events')
          .orderBy('date', descending: true).limit(100).get(),
      builder: (context, snapshot) {
        
        Map<String, double> monthlyData = {};
        
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            var data = doc.data() as Map<String, dynamic>;
            
            // Check for Usage
            if (!data.containsKey('usage')) continue;
            if (!data.containsKey('date')) continue;

            String dateStr = data['date']; 
            try {
              DateTime date = DateTime.parse(dateStr);
              String monthKey = DateFormat('MMMM yyyy').format(date);
              
              var val = data['usage'];
              double usage = 0.0;
              if (val is int) usage = val.toDouble();
              else if (val is double) usage = val;

              if (monthlyData.containsKey(monthKey)) {
                monthlyData[monthKey] = monthlyData[monthKey]! + usage;
              } else {
                monthlyData[monthKey] = usage;
              }
            } catch (e) {
              // Ignore
            }
          }
        }

        List<MapEntry<String, double>> sortedList = monthlyData.entries.toList();
        
        double totalKg = sortedList.fold(0.0, (sum, item) => sum + item.value) / 1000;
        double avgKg = sortedList.isNotEmpty ? totalKg / sortedList.length : 0;

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
                    Text("Monthly Average: ${avgKg.toStringAsFixed(1)}kg",
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Text("Based on available data", style: GoogleFonts.inter(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ).animate().fade().slideY(begin: 0.2),
            ),
            Expanded(
              child: sortedList.isEmpty 
              ? Center(child: Text("Waiting for usage data...", style: GoogleFonts.inter(color: Colors.white38)))
              : ListView.separated(
                padding: const EdgeInsets.all(24.0),
                itemCount: sortedList.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  String month = sortedList[index].key;
                  double kg = sortedList[index].value / 1000;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: const Icon(Icons.calendar_today, color: Colors.white54),
                    title: Text(month, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
                    trailing: Text("${kg.toStringAsFixed(1)} kg",
                        style: GoogleFonts.inter(color: Colors.blue.shade300, fontSize: 16)),
                  ).animate().fade(delay: (index * 100).ms).slideX(begin: 0.2);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // --- TAB 3: Full History (THE FIX IS HERE) ---
  Widget _buildHistoryListTab() {
    return StreamBuilder<QuerySnapshot>(
      // FIX: Changed sorting to 'date' instead of 'timestamp'
      // This is crucial because usage records from Arduino don't have timestamp
      stream: _db.collection('hubs').doc(widget.currentHubId).collection('cylinder_events')
          .orderBy('date', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        
        var allDocs = snapshot.data?.docs ?? [];
        
        if (allDocs.isEmpty) {
          return Center(child: Text("No history found.", style: GoogleFonts.inter(color: Colors.white38)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(24.0),
          itemCount: allDocs.length,
          separatorBuilder: (context, index) => const Divider(color: Colors.white10),
          itemBuilder: (context, index) {
            var data = allDocs[index].data() as Map<String, dynamic>;
            String date = data['date'] ?? 'Unknown';
            
            // --- SCENARIO 1: Usage Record ---
            // We check for 'usage' key OR if event name is 'Daily Usage'
            if (data.containsKey('usage') || (data['event'] == 'Daily Usage')) {
               double usage = 0.0;
               if (data.containsKey('usage')) {
                 var uVal = data['usage'];
                 if (uVal is int) usage = uVal.toDouble();
                 else if (uVal is double) usage = uVal;
               }

               return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.orange.withOpacity(0.2),
                  child: const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 20),
                ),
                title: Text("Daily Usage",
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
                subtitle: Text(date, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                trailing: Text("-${(usage).toStringAsFixed(0)} g",
                    style: GoogleFonts.inter(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 15)),
              ).animate().fade().slideX();
            } 
            
            // --- SCENARIO 2: New Cylinder Record ---
            else {
              double weight = 0.0;
              if (data.containsKey('weight')) {
                  var wVal = data['weight'];
                  if (wVal is int) weight = wVal.toDouble();
                  else if (wVal is double) weight = wVal;
              }
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.2),
                  child: const Icon(Icons.propane_tank, color: Colors.blueAccent, size: 20),
                ),
                title: Text("New Cylinder",
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500)),
                subtitle: Text(date, style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
                trailing: Text("+${(weight/1000).toStringAsFixed(1)} kg",
                    style: GoogleFonts.inter(color: Colors.greenAccent, fontWeight: FontWeight.w600, fontSize: 15)),
              ).animate().fade().slideX();
            }
          },
        );
      },
    );
  }
}