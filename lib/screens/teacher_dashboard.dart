import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_avatar.dart';
import '../providers/auth_provider.dart';
import '../providers/firestore_provider.dart';
import '../components/teacher_bottom_nav.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void didUpdateWidget(TeacherDashboard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadUserData();
  }
  
  // Add this to refresh when screen becomes visible again
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this screen
    if (ModalRoute.of(context)?.isCurrent == true) {
      _loadUserData();
    }
  }

  void _refreshData() {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      final user = await firestoreProvider.getUser(authProvider.currentUser!.uid);
      if (user != null) {
        setState(() {
          _userData = {
            'name': user.name,
            'email': user.email,
            'role': user.role,
            'subject': user.subject,
            'department': user.department,
          };
          _isLoading = false;
        });
      } else {
        // Fallback to Firebase Auth data
        setState(() {
          _userData = {
            'name': authProvider.currentUser!.displayName ?? 'Teacher',
            'email': authProvider.currentUser!.email ?? '',
            'role': 'teacher',
          };
          _isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getTodayAttendanceData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);
    
    final currentUser = authProvider.currentUser;
    if (currentUser == null) return [];
    
    // Get the user from Firestore to get the current name
    final teacherId = currentUser.uid;
    final displayName = currentUser.displayName ?? _userData?['name'] ?? '';
    final sections = await firestoreProvider.getSectionsByTeacher(teacherId, teacherName: displayName);
    
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    
    List<Map<String, dynamic>> attendanceData = [];
    
    for (var section in sections) {
      final attendanceRecords = await firestoreProvider.getAttendanceForSection(section.id);
      
      // Filter for today's records only
      final todayRecords = attendanceRecords.where((record) {
        return record.date.isAfter(todayStart.subtract(const Duration(seconds: 1))) && record.date.isBefore(todayEnd);
      }).toList();
      
      // Remove duplicates: keep only the most recent record per student per day
      final Map<String, dynamic> latestByStudent = {};
      for (final record in todayRecords) {
        if (!latestByStudent.containsKey(record.studentId)) {
          latestByStudent[record.studentId] = record;
        } else {
          final existing = latestByStudent[record.studentId];
          // Keep the most recent timestamp
          if (record.timestamp != null && existing.timestamp != null) {
            if (record.timestamp!.isAfter(existing.timestamp!)) {
              latestByStudent[record.studentId] = record;
            }
          }
        }
      }
      
      final cleanedRecords = latestByStudent.values.toList();
      
      if (cleanedRecords.isNotEmpty) {
        int present = cleanedRecords.where((r) => r.attendanceStatus == 'Present').length;
        int absent = cleanedRecords.where((r) => r.attendanceStatus == 'Absent').length;
        
        attendanceData.add({
          'sectionName': section.name,
          'schedule': section.schedule,
          'totalStudents': section.studentCount,
          'present': present,
          'absent': absent,
        });
      }
    }
    
    return attendanceData;
  }

  void _onNavTap(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        Navigator.pushNamed(context, '/generate_qr');
        break;
      case 2:
        Navigator.pushNamed(context, '/teacher_sections');
        break;
      case 3:
        await Navigator.pushNamed(context, '/settings');
        if (!mounted) break;
        // Refresh data when returning from settings
        _refreshData();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final userName = _userData?['name'] ?? 'Teacher';

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Teacher Dashboard',
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section
            Container(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.85),
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ProfileAvatar(
                    name: userName,
                    radius: MediaQuery.of(context).size.width < 600 ? 40 : 50,
                  ),
                  SizedBox(width: MediaQuery.of(context).size.width < 600 ? 16 : 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.95),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: GoogleFonts.poppins(
                            fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Quick Actions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context,
                          'Generate Class QR',
                          'Create QR for attendance',
                          Icons.qr_code_scanner,
                          Colors.blue,
                          () => Navigator.pushNamed(context, '/generate_qr'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          'Scan Attendance',
                          'Scan student QR codes',
                          Icons.camera_alt,
                          Colors.green,
                          () => Navigator.pushNamed(context, '/scan_attendance'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionCard(
                          context,
                          'My Sections',
                          'Manage your classes',
                          Icons.class_,
                          Colors.orange,
                          () => Navigator.pushNamed(context, '/teacher_sections'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionCard(
                          context,
                          'Announcements',
                          'Send updates to students',
                          Icons.announcement,
                          Colors.teal,
                          () => Navigator.pushNamed(context, '/announcements'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        child: _buildActionCard(
                          context,
                          'Reports',
                          'View analytics',
                          Icons.bar_chart,
                          Colors.purple,
                          () => Navigator.pushNamed(context, '/attendance_report'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Today's Attendance Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Attendance",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _getTodayAttendanceData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                        return Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_outlined,
                                  size: 48,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No attendance recorded today',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      final attendanceData = snapshot.data!;
                      return Column(
                        children: attendanceData.map((data) {
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Section: ${data['sectionName']}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.grey.shade900,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'Schedule: ${data['schedule']}',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${data['totalStudents']} Students',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blue.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildAttendanceStat('Present', '${data['present']}', Colors.green),
                                      _buildAttendanceStat('Absent', '${data['absent']}', Colors.red),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: TeacherBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceStat(String label, String count, Color color) {
    return Column(
      children: [
        Text(
          count,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
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
