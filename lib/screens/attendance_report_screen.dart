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

          // Also load daily aggregated counts for the past `_daysWindow` days
          final daily = await firestoreProvider.getDailyAttendanceCountsForTeacher(teacherId, days: _daysWindow);

          setState(() {
            _attendanceRecords = combined;
            _dailyCounts = daily;
            _isLoading = false;
          });
        } else {
          // Student (default): load student's own attendance
          final attendance = await firestoreProvider.getAttendanceForStudent(authProvider.currentUser!.uid);
          final sections = await firestoreProvider.getSectionsForStudent(authProvider.currentUser!.uid);

          // Create section name map and student sections list
          _sectionNames = {for (var section in sections) section.id: section.name};
          _studentSections = sections;

          // Default to first section if available, otherwise show all
          if (_studentSections.isNotEmpty && _selectedSectionId == null) {
            _selectedSectionId = null; // keep null to represent "All Sections" by default
          }

          setState(() {
            _attendanceRecords = attendance;
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

    final bool isTeacher = _dailyCounts.isNotEmpty;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Attendance Report'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Overall Statistics',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Show only the chart (larger) to improve readability for users with poor eyesight
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                        height: 360,
                        padding: const EdgeInsets.all(12),
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
                            // Student section selector (ChoiceChips) - lightweight segmented control feel
                            if (!isTeacher && _studentSections.isNotEmpty)
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
                                            });
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
                                                });
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

                            // Chart area
                            Expanded(child: isTeacher ? _buildTrendChart(large: true) : _buildAttendanceChart(large: true)),
                          ],
                        ),
                      ),
                ),
              ),
              const SizedBox(height: 16),
              // Section selector for teachers
              if (_teacherSections.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Text('Section:', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
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
              Text(
                'Recent Attendance',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Filter recent attendance by selected section for students
              (_selectedSectionId == null ? _attendanceRecords : _attendanceRecords.where((r) => r.sectionId == _selectedSectionId).toList()).isEmpty
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
                      itemCount: (_selectedSectionId == null ? _attendanceRecords : _attendanceRecords.where((r) => r.sectionId == _selectedSectionId).toList()).length,
                      itemBuilder: (context, index) {
                        final displayRecords = _selectedSectionId == null ? _attendanceRecords : _attendanceRecords.where((r) => r.sectionId == _selectedSectionId).toList();
                        final record = displayRecords[index];
                        final sectionName = _sectionNames[record.sectionId] ?? 'Unknown Section';

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            onTap: () {},
                            title: Text(
                              '${DateFormat.yMMMd().format(record.date)} • $sectionName',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              record.displayTime,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(record.attendanceStatus).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: _getStatusColor(record.attendanceStatus).withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Text(
                                record.attendanceStatus,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: _getStatusColor(record.attendanceStatus),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
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

  Widget _buildAttendanceChart({bool large = false}) {
    final records = _selectedSectionId == null
        ? _attendanceRecords
        : _attendanceRecords.where((r) => r.sectionId == _selectedSectionId).toList();
    final total = records.length;
    if (total == 0) {
      return const Center(
        child: Text(
          'No data for chart',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final presentCount = records.where((r) => r.attendanceStatus == 'Present').length.toDouble();
    final absentCount = records.where((r) => r.attendanceStatus == 'Absent').length.toDouble();
    final lateCount = records.where((r) => r.attendanceStatus == 'Late').length.toDouble();

    final sections = <PieChartSectionData>[];
    // Modern color palette
    final presentColor = Colors.green.shade600;
    final lateColor = Colors.orange.shade600;
    final absentColor = Colors.red.shade600;

    if (presentCount > 0) {
      sections.add(PieChartSectionData(
        value: presentCount,
        title: '',
        color: presentColor,
        radius: large ? 80 : 60,
        badgeWidget: null,
      ));
    }
    if (lateCount > 0) {
      sections.add(PieChartSectionData(
        value: lateCount,
        title: '',
        color: lateColor,
        radius: large ? 70 : 50,
      ));
    }
    if (absentCount > 0) {
      sections.add(PieChartSectionData(
        value: absentCount,
        title: '',
        color: absentColor,
        radius: large ? 60 : 45,
      ));
    }

    // Build a donut chart with centered total and clearer legend showing counts + percentages
    final totalCount = (presentCount + absentCount + lateCount).toDouble();

    return Column(
      children: [
        SizedBox(
          height: large ? 220 : 170,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // subtle elevated circle behind chart to create depth
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: large ? 220 : 160,
                    height: large ? 220 : 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [Colors.white, Colors.grey.shade50]),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 8))],
                    ),
                  ),
                ),
              ),
              PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: large ? 56 : 44,
                  sectionsSpace: 6,
                  pieTouchData: PieTouchData(enabled: true),
                  centerSpaceColor: Colors.white,
                ),
              ),
              // Center bold total
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${totalCount.toInt()}', style: GoogleFonts.poppins(fontSize: large ? 26 : 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Total', style: GoogleFonts.poppins(fontSize: large ? 14 : 12, color: Colors.grey.shade600)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Legend row with counts and percentages
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (presentCount > 0) _legendTile('Present', presentColor, presentCount, totalCount),
            if (lateCount > 0) _legendTile('Late', lateColor, lateCount, totalCount),
            if (absentCount > 0) _legendTile('Absent', absentColor, absentCount, totalCount),
          ],
        ),
      ],
    );
  }

  Widget _legendTile(String label, Color color, double count, double total) {
    final percent = total > 0 ? (count / total * 100).round() : 0;
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$percent% · ${count.toInt()}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
      ],
    );
  }

  /// Smooth, accessible trend chart for teacher overall statistics.
  /// Shows present counts over the [_dailyCounts] window as a curved line
  /// with a soft gradient area fill. Tooltips show Present/Late/Absent per day.
  Widget _buildTrendChart({bool large = false}) {
    if (_dailyCounts.isEmpty) {
      return const Center(child: Text('No daily history available', style: TextStyle(color: Colors.grey)));
    }

    final colorPrimary = Colors.blue.shade600;
    final spots = <FlSpot>[];
    for (var i = 0; i < _dailyCounts.length; i++) {
      final present = ( _dailyCounts[i]['present'] as int? ) ?? 0;
      spots.add(FlSpot(i.toDouble(), present.toDouble()));
    }

    // Determine y max
    final maxYVal = spots.map((s) => s.y).fold<double>(0, (p, e) => e > p ? e : p);
    final maxY = (maxYVal * 1.3).clamp(5.0, double.infinity);

    return SizedBox(
      height: large ? 360 : 260,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.shade200, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 56,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= _dailyCounts.length) return const SizedBox.shrink();
                  final label = _dailyCounts[idx]['date'] as String? ?? '';
                  try {
                    final dt = DateTime.parse(label);
                    final short = DateFormat.MMMd().format(dt);
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Transform.rotate(
                        angle: -0.15,
                        child: Text(short, style: TextStyle(fontSize: large ? 14 : 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                      ),
                    );
                  } catch (_) {
                    return Padding(padding: const EdgeInsets.only(top: 6), child: Text(label, style: TextStyle(fontSize: large ? 14 : 12)));
                  }
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((t) {
                  final idx = t.x.toInt();
                  final item = _dailyCounts[idx];
                  final date = item['date'] as String? ?? '';
                  final present = item['present'] as int? ?? 0;
                  final late = item['late'] as int? ?? 0;
                  final absent = item['absent'] as int? ?? 0;
                  String labelText;
                  try {
                    labelText = DateFormat.yMMMd().format(DateTime.parse(date));
                  } catch (_) {
                    labelText = date;
                  }
                  return LineTooltipItem(
                    '$labelText\nPresent: $present\nLate: $late\nAbsent: $absent',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4,
              gradient: LinearGradient(colors: [colorPrimary.withValues(alpha: 0.95), colorPrimary.withValues(alpha: 0.7)]),
              barWidth: large ? 4 : 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: large ? 5 : 4,
                  color: colorPrimary,
                  strokeWidth: 1.5,
                  strokeColor: Colors.white,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [colorPrimary.withValues(alpha: 0.25), colorPrimary.withValues(alpha: 0.04)], begin: Alignment.topCenter, end: Alignment.bottomCenter),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
}
