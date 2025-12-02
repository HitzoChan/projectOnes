import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
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
        final attendance = await firestoreProvider
            .getAttendanceForStudent(authProvider.currentUser!.uid);

        final sections = await firestoreProvider
            .getSectionsForStudent(authProvider.currentUser!.uid);

        if (!mounted) return; // <-- FIXED

        // Create section name map
        _sectionNames = {
          for (var section in sections) section.id: section.name
        };

        setState(() {
          _attendanceHistory = attendance;
          _isLoading = false;
        });
      } catch (e) {
        if (!mounted) return; // <-- FIXED

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Attendance Record',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _attendanceHistory.isEmpty
                  ? Center(
                      child: Text(
                        'No attendance records found',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _attendanceHistory.length,
                      itemBuilder: (context, index) {
                        final record = _attendanceHistory[index];
                        final sectionName =
                            _sectionNames[record.sectionId] ??
                                'Unknown Section';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: Icon(
                              record.attendanceStatus == 'Present'
                                  ? Icons.check_circle
                                  : record.attendanceStatus == 'Absent'
                                      ? Icons.cancel
                                      : Icons.access_time,
                              color: record.attendanceStatus == 'Present'
                                  ? Colors.green
                                  : record.attendanceStatus == 'Absent'
                                      ? Colors.red
                                      : Colors.orange,
                            ),
                            title: Text(
                              sectionName,
                              style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${record.date.day}/${record.date.month}/${record.date.year} - '
                              '${record.attendanceStatus} at ${record.displayTime}',
                              style: GoogleFonts.poppins(),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 16),
            // Simple attendance summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(
                      'Present', _countStatus('Present'), Colors.green),
                  _buildSummaryItem(
                      'Absent', _countStatus('Absent'), Colors.red),
                  _buildSummaryItem(
                      'Late', _countStatus('Late'), Colors.orange),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
