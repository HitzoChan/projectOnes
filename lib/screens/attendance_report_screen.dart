import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/section.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/auth_provider.dart';
import '../providers/firestore_provider.dart';
import '../models/attendance.dart';

class AttendanceReportScreen extends StatefulWidget {
  const AttendanceReportScreen({super.key});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  List<Attendance> _attendanceRecords = [];
  bool _isLoading = true;
  Map<String, String> _sectionNames = {};
  List<Section> _teacherSections = [];
  List<Section> _studentSections = [];
  String? _selectedSectionId;
  List<Map<String, dynamic>> _dailyCounts = [];
  final int _daysWindow = 7;

  @override
  void initState() {
    super.initState();
    _loadAttendanceReport();
  }

  Future<void> _loadAttendanceReport() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      try {
        // Detect whether current user is a teacher or student
        final user = await firestoreProvider.getUser(authProvider.currentUser!.uid);
        if (user != null && user.role == 'teacher') {
          // Teacher: aggregate attendance across teacher's sections
          final teacherId = authProvider.currentUser!.uid;
          final displayName = user.name.isNotEmpty ? user.name : (authProvider.currentUser!.displayName ?? '');
          final sections = await firestoreProvider.getSectionsByTeacher(teacherId, teacherName: displayName);
          // Build section map and save teacher sections
          _teacherSections = sections;
          _sectionNames = {for (var section in sections) section.id: section.name};

          List<Attendance> combined = [];
          // If a specific section is selected, only query that one
          if (_selectedSectionId != null && _selectedSectionId!.isNotEmpty) {
            final recs = await firestoreProvider.getAttendanceForSection(_selectedSectionId!);
            combined.addAll(recs);
          } else {
            for (var section in sections) {
              final recs = await firestoreProvider.getAttendanceForSection(section.id);
              combined.addAll(recs);
            }
          }

          // Sort most recent first
          combined.sort((a, b) => b.date.compareTo(a.date));

          // Also load daily aggregated counts for the past `_daysWindow` days (respect selected section filter)
          final daily = await firestoreProvider.getDailyAttendanceCountsForTeacher(
            teacherId,
            days: _daysWindow,
            sectionId: _selectedSectionId,
          );

          // Debug: Check if we got data
          debugPrint('Teacher daily counts: ${daily.length} days');
          for (var day in daily) {
            debugPrint('  ${day['date']}: Present=${day['present']}, Late=${day['late']}, Absent=${day['absent']}');
          }

          setState(() {
            _attendanceRecords = combined;
            _dailyCounts = daily;
            _isLoading = false;
          });
        } else {
          // Student (default): load student's own attendance
          final studentId = authProvider.currentUser!.uid;
          final attendance = await firestoreProvider.getAttendanceForStudent(studentId);
          final sections = await firestoreProvider.getSectionsForStudent(studentId);

          // Create section name map and student sections list
          _sectionNames = {for (var section in sections) section.id: section.name};
          _studentSections = sections;

          // Default to first section if available, otherwise show all
          if (_studentSections.isNotEmpty && _selectedSectionId == null) {
            _selectedSectionId = null; // keep null to represent "All Sections" by default
          }

          // Load daily aggregated counts for student (past _daysWindow days, respect selected section filter)
          final daily = await firestoreProvider.getDailyAttendanceCountsForStudent(
            studentId,
            days: _daysWindow,
            sectionId: _selectedSectionId,
          );

          setState(() {
            _attendanceRecords = attendance;
            _dailyCounts = daily;
            _isLoading = false;
          });
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Attendance Report'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Attendance Report'),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Statistics',
                style: GoogleFonts.poppins(
                  fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Show only the chart (larger) to improve readability for users with poor eyesight
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                        height: MediaQuery.of(context).size.width < 600 ? 300 : 360,
                        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Section selector (ChoiceChips) for students
                            if (_studentSections.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 6.0),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8.0),
                                        child: ChoiceChip(
                                          label: Text('All', style: TextStyle(color: _selectedSectionId == null ? Colors.white : Colors.grey.shade800)),
                                          selected: _selectedSectionId == null,
                                          onSelected: (sel) {
                                            setState(() {
                                              _selectedSectionId = null;
                                              _isLoading = true;
                                            });
                                            _loadAttendanceReport();
                                          },
                                          selectedColor: Colors.blue.shade600,
                                          backgroundColor: Colors.grey.shade200,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                        ),
                                      ),
                                      ..._studentSections.map((s) => Padding(
                                            padding: const EdgeInsets.only(right: 8.0),
                                            child: ChoiceChip(
                                              label: Text(s.name, style: TextStyle(color: _selectedSectionId == s.id ? Colors.white : Colors.grey.shade800)),
                                              selected: _selectedSectionId == s.id,
                                              onSelected: (sel) {
                                                setState(() {
                                                  _selectedSectionId = sel ? s.id : null;
                                                  _isLoading = true;
                                                });
                                                _loadAttendanceReport();
                                              },
                                              selectedColor: Colors.blue.shade600,
                                              backgroundColor: Colors.grey.shade200,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            ),
                                          ))
                                    ],
                                  ),
                                ),
                              ),

                            // Chart area - always use bar chart
                            Expanded(child: _buildBarChart(large: true)),
                          ],
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 16),
              // Section selector for teachers
              if (_teacherSections.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width < 600 ? 0 : 4.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Section:',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<String?>(
                          isExpanded: true,
                          value: _selectedSectionId,
                          hint: Text('All Sections', style: GoogleFonts.poppins()),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('All Sections')),
                            ..._teacherSections.map((s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.name)))
                          ],
                          onChanged: (val) {
                            setState(() {
                              _selectedSectionId = val;
                              _isLoading = true;
                            });
                            _loadAttendanceReport();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Text(
                  'Recent Attendance',
                  style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 16 : 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Filter recent attendance by selected section and clean duplicates
              Builder(
                builder: (context) {
                  final filtered = _selectedSectionId == null 
                      ? _attendanceRecords 
                      : _attendanceRecords.where((r) => r.sectionId == _selectedSectionId).toList();
                  final cleaned = _getCleanedAttendanceRecords(filtered);
                  
                  return cleaned.isEmpty
                      ? Center(
                          child: Text(
                            'No attendance records found',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: cleaned.length,
                          itemBuilder: (context, index) {
                            final record = cleaned[index];
                            final sectionName = _sectionNames[record.sectionId] ?? 'Unknown Section';

                            return FutureBuilder<String?>(
                              future: _fetchStudentName(record.studentId),
                              builder: (context, snapshot) {
                                final studentName = snapshot.data ?? 'Unknown Student';

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                                    vertical: MediaQuery.of(context).size.width < 600 ? 12 : 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey.shade200, width: 1),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top row: Name label and value with Time on right
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Name:',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: MediaQuery.of(context).size.width < 600 ? 11 : 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                                Text(
                                                  studentName,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 15,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.grey.shade900,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Time:',
                                                style: GoogleFonts.poppins(
                                                  fontSize: MediaQuery.of(context).size.width < 600 ? 11 : 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                              Text(
                                                record.displayTime,
                                                style: GoogleFonts.poppins(
                                                  fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.grey.shade900,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      // Bottom row: Section label and value with Status on right
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Flexible(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Section:',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: MediaQuery.of(context).size.width < 600 ? 11 : 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                                Text(
                                                  sectionName,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: MediaQuery.of(context).size.width < 600 ? 13 : 14,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade700,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Status badge
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(record.attendanceStatus).withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              record.attendanceStatus,
                                              style: GoogleFonts.poppins(
                                                fontSize: MediaQuery.of(context).size.width < 600 ? 11 : 12,
                                                fontWeight: FontWeight.w600,
                                                color: _getStatusColor(record.attendanceStatus),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // _buildStatItem removed — overall stats are not shown; the report focuses on a large chart for accessibility.

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Present':
        return Colors.green;
      case 'Late':
        return Colors.orange;
      case 'Absent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Filter attendance records to show only the most recent per student per date
  List<Attendance> _getCleanedAttendanceRecords(List<Attendance> records) {
    final Map<String, Attendance> latestByStudentDate = {};
    
    for (final record in records) {
      final key = '${record.studentId}_${DateFormat('yyyy-MM-dd').format(record.date)}';
      
      // Keep only the most recent record for each student on each date
      if (!latestByStudentDate.containsKey(key)) {
        latestByStudentDate[key] = record;
      } else {
        final existing = latestByStudentDate[key]!;
        // Compare timestamps; prefer the one marked later (most recent)
        if (record.timestamp != null && existing.timestamp != null) {
          if (record.timestamp!.isAfter(existing.timestamp!)) {
            latestByStudentDate[key] = record;
          }
        } else if (record.timestamp != null) {
          latestByStudentDate[key] = record;
        }
      }
    }
    
    // Convert back to list and sort by date descending
    final result = latestByStudentDate.values.toList();
    result.sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  /// Fetch student name by studentId
  Future<String?> _fetchStudentName(String studentId) async {
    final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);
    try {
      final user = await firestoreProvider.getUser(studentId);
      return user?.name ?? 'Unknown Student';
    } catch (_) {
      return 'Unknown Student';
    }
  }

  /// Bar chart showing daily attendance (Present vs Absent)
  Widget _buildBarChart({bool large = false}) {
    if (_dailyCounts.isEmpty) {
      return const Center(child: Text('No daily history available', style: TextStyle(color: Colors.grey)));
    }

    return AttendanceBarChart(
      presentData: _dailyCounts.map((d) => (d['present'] as int?) ?? 0).toList(),
      absentData: _dailyCounts.map((d) => (d['absent'] as int?) ?? 0).toList(),
      dates: _dailyCounts.map((d) => d['date'] as String? ?? '').toList(),
      large: large,
    );
  }
}

/// Reusable attendance bar chart widget with clean box-style layout
class AttendanceBarChart extends StatelessWidget {
  final List<int> presentData;
  final List<int> absentData;
  final List<String> dates;
  final bool large;

  const AttendanceBarChart({
    super.key,
    required this.presentData,
    required this.absentData,
    required this.dates,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    const presentColor = Color(0xFF22C55E); // green when more present
    const absentColor = Color(0xFFEF4444);  // red when more absent

    // Compute y max based on total attendance per day
    double maxY = 0;
    for (int i = 0; i < presentData.length; i++) {
      final total = presentData[i] + absentData[i];
      maxY = maxY > total.toDouble() ? maxY : total.toDouble();
    }
    maxY = (maxY * 1.2).clamp(5.0, double.infinity);

    // Build single bar per day; color reflects which count is higher
    final groups = <BarChartGroupData>[];
    for (var i = 0; i < presentData.length; i++) {
      final present = presentData[i];
      final absent = absentData[i];
      final total = present + absent;
      final barColor = present >= absent ? presentColor : absentColor;

      groups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: total.toDouble(),
              width: large ? 24 : 20,
              borderRadius: BorderRadius.zero,
              color: barColor,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Legend box with improved spacing
        Container(
          color: Colors.grey.shade50,
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 16,
            vertical: MediaQuery.of(context).size.width < 600 ? 10 : 14,
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Present (Green) legend
                Container(
                  width: 12,
                  height: 12,
                  color: presentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'More Present',
                  style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 11 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width < 600 ? 16 : 40),
                // Absent (Red) legend
                Container(
                  width: 12,
                  height: 12,
                  color: absentColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'More Absent',
                  style: GoogleFonts.poppins(
                    fontSize: MediaQuery.of(context).size.width < 600 ? 11 : 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Chart box
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // Vertical separator lines for each date (behind the chart)
                    CustomPaint(
                      painter: _VerticalDateSeparatorPainter(
                        dateCount: dates.length,
                        separatorColor: const Color(0x0D000000), // 5% opacity
                      ),
                      size: Size.infinite,
                    ),
                    // Bar chart (on top for touch interaction)
                    BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: maxY,
                        minY: 0,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: Colors.grey.shade200,
                            strokeWidth: 0.8,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: groups,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: (maxY / 5)
                                  .floorToDouble()
                                  .clamp(1.0, double.infinity),
                              getTitlesWidget: (value, meta) {
                                if (value % 1 != 0) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                  ),
                                  textAlign: TextAlign.center,
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= dates.length) {
                                  return const SizedBox.shrink();
                                }
                                final label = dates[idx];
                                try {
                                  final dt = DateTime.parse(label);
                                  final isSmallScreen = MediaQuery.of(context).size.width < 600;
                                  final short = isSmallScreen 
                                      ? DateFormat('d').format(dt)  // Just day number for small screens
                                      : DateFormat('MMM d').format(dt);  // Month and day for large screens
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      short,
                                      style: TextStyle(
                                        fontSize: isSmallScreen ? 10 : 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                } catch (_) {
                                  return Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipColor: (_) => Colors.grey.shade900,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final idx = group.x.toInt();
                              if (idx < 0 || idx >= dates.length) {
                                return null;
                              }
                              final date = dates[idx];
                              final present = presentData[idx];
                              final absent = absentData[idx];
                              final total = present + absent;
                              String labelText;
                              try {
                                labelText = DateFormat.yMMMd()
                                    .format(DateTime.parse(date));
                              } catch (_) {
                                labelText = date;
                              }
                              
                              final presentColor = Color(0xFF22C55E);
                              final absentColor = Color(0xFFEF4444);
                              
                              return BarTooltipItem(
                                '',
                                const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                                children: [
                                  TextSpan(
                                    text: '$labelText\n\n',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '● Present: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '$present\n',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: presentColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '● Absent: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '$absent\n\n',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: absentColor,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Total: $total',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade300,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for vertical date separators
class _VerticalDateSeparatorPainter extends CustomPainter {
  final int dateCount;
  final Color separatorColor;

  _VerticalDateSeparatorPainter({
    required this.dateCount,
    required this.separatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dateCount <= 1) return;

    final paint = Paint()
      ..color = separatorColor
      ..strokeWidth = 1.0;

    final groupWidth = size.width / dateCount;

    // Draw vertical lines between each date group
    for (int i = 1; i < dateCount; i++) {
      final x = i * groupWidth;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VerticalDateSeparatorPainter oldDelegate) {
    return oldDelegate.dateCount != dateCount ||
        oldDelegate.separatorColor != separatorColor;
  }
}

