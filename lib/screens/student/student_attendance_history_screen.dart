import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/firestore_provider.dart';
import '../../models/attendance.dart';

class StudentAttendanceHistoryScreen extends StatefulWidget {
  const StudentAttendanceHistoryScreen({super.key});

  @override
  State<StudentAttendanceHistoryScreen> createState() =>
      _StudentAttendanceHistoryScreenState();
}

class _StudentAttendanceHistoryScreenState
    extends State<StudentAttendanceHistoryScreen> {
  List<Attendance> _attendanceHistory = [];
  bool _isLoading = true;
  Map<String, String> _sectionNames = {};
  List<Map<String, dynamic>> _dailyCounts = [];
  final int _daysWindow = 7;

  @override
  void initState() {
    super.initState();
    _loadAttendanceHistory();
  }

  Future<void> _loadAttendanceHistory() async {
    final authProvider =
        Provider.of<AuthProvider>(context, listen: false);
    final firestoreProvider =
        Provider.of<FirestoreProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      try {
        final studentId = authProvider.currentUser!.uid;
        final attendance = await firestoreProvider
            .getAttendanceForStudent(studentId);

        final sections = await firestoreProvider
            .getSectionsForStudent(studentId);

        // Load daily aggregated counts for past _daysWindow days
        final daily = await firestoreProvider.getDailyAttendanceCountsForStudent(
          studentId,
          days: _daysWindow,
        );

        if (!mounted) return;

        // Create section name map
        _sectionNames = {
          for (var section in sections) section.id: section.name
        };

        setState(() {
          _attendanceHistory = attendance;
          _dailyCounts = daily;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Attendance History'),
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Attendance History'),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Attendance Statistics',
                style: GoogleFonts.poppins(
                  fontSize: MediaQuery.of(context).size.width < 600 ? 18 : 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // Show bar chart for past 7 days
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
                    child: _buildBarChart(large: true),
                  ),
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
              // Recent attendance records
              _attendanceHistory.isEmpty
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
                      itemCount: _attendanceHistory.length,
                      itemBuilder: (context, index) {
                        final record = _attendanceHistory[index];
                        final sectionName = _sectionNames[record.sectionId] ?? 'Unknown Section';

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
                                          'Gerald Cargo',
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
                    ),
              const SizedBox(height: 16),
              // Summary stats
              Container(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Present', _countStatus('Present'), Colors.green),
                    _buildSummaryItem('Absent', _countStatus('Absent'), Colors.red),
                    _buildSummaryItem('Late', _countStatus('Late'), Colors.orange),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  int _countStatus(String status) {
    return _attendanceHistory
        .where((record) => record.attendanceStatus == status)
        .length;
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: GoogleFonts.poppins(
            fontSize: MediaQuery.of(context).size.width < 600 ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: MediaQuery.of(context).size.width < 600 ? 11 : 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  /// Bar chart showing daily attendance (Present vs Absent)
  Widget _buildBarChart({bool large = false}) {
    if (_dailyCounts.isEmpty) {
      return const Center(child: Text('No daily history available', style: TextStyle(color: Colors.grey)));
    }

    return StudentAttendanceBarChart(
      presentData: _dailyCounts.map((d) => (d['present'] as int?) ?? 0).toList(),
      absentData: _dailyCounts.map((d) => (d['absent'] as int?) ?? 0).toList(),
      dates: _dailyCounts.map((d) => d['date'] as String? ?? '').toList(),
      large: large,
    );
  }
}

/// Bar chart widget for student attendance
class StudentAttendanceBarChart extends StatelessWidget {
  final List<int> presentData;
  final List<int> absentData;
  final List<String> dates;
  final bool large;

  const StudentAttendanceBarChart({
    super.key,
    required this.presentData,
    required this.absentData,
    required this.dates,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    const presentColor = Color(0xFF22C55E); // green
    const absentColor = Color(0xFFEF4444);  // red

    // Compute y max based on total attendance per day
    double maxY = 0;
    for (int i = 0; i < presentData.length; i++) {
      final total = presentData[i] + absentData[i];
      maxY = maxY > total.toDouble() ? maxY : total.toDouble();
    }
    maxY = (maxY * 1.2).clamp(5.0, double.infinity);

    // Build single bar per day
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
        // Legend
        Container(
          color: Colors.grey.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 12, height: 12, color: presentColor),
              const SizedBox(width: 8),
              Text('More Present', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
              const SizedBox(width: 40),
              Container(width: 12, height: 12, color: absentColor),
              const SizedBox(width: 8),
              Text('More Absent', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Chart
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    CustomPaint(
                      painter: _VerticalDateSeparatorPainter(
                        dateCount: dates.length,
                        separatorColor: const Color(0x0D000000),
                      ),
                      size: Size.infinite,
                    ),
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
                              interval: (maxY / 5).floorToDouble().clamp(1.0, double.infinity),
                              getTitlesWidget: (value, meta) {
                                if (value % 1 != 0) return const SizedBox.shrink();
                                return Text(value.toInt().toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.grey.shade600), textAlign: TextAlign.center);
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) {
                                final idx = value.toInt();
                                if (idx < 0 || idx >= dates.length) return const SizedBox.shrink();
                                try {
                                  final dt = DateTime.parse(dates[idx]);
                                  final short = DateFormat('MMM d').format(dt);
                                  return Padding(padding: const EdgeInsets.only(top: 8), child: Text(short, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey.shade700), textAlign: TextAlign.center));
                                } catch (_) {
                                  return Text(dates[idx], style: TextStyle(fontSize: 11, color: Colors.grey.shade600));
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
                              if (idx < 0 || idx >= dates.length) return null;
                              final date = dates[idx];
                              final present = presentData[idx];
                              final absent = absentData[idx];
                              final total = present + absent;
                              String labelText;
                              try {
                                labelText = DateFormat.yMMMd().format(DateTime.parse(date));
                              } catch (_) {
                                labelText = date;
                              }
                              return BarTooltipItem(
                                '',
                                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                children: [
                                  TextSpan(text: '$labelText\n\n', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
                                  TextSpan(text: '● Present: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                  TextSpan(text: '$present\n', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: presentColor)),
                                  TextSpan(text: '● Absent: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                  TextSpan(text: '$absent\n\n', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: absentColor)),
                                  TextSpan(text: 'Total: $total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade300)),
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

  _VerticalDateSeparatorPainter({required this.dateCount, required this.separatorColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (dateCount <= 1) return;
    final paint = Paint()..color = separatorColor..strokeWidth = 1.0;
    final groupWidth = size.width / dateCount;
    for (int i = 1; i < dateCount; i++) {
      final x = i * groupWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_VerticalDateSeparatorPainter oldDelegate) {
    return oldDelegate.dateCount != dateCount || oldDelegate.separatorColor != separatorColor;
  }
}
