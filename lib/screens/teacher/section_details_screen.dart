import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../widgets/custom_app_bar.dart';
import '../../widgets/profile_avatar.dart';

import '../../models/section.dart';
import '../../models/attendance.dart';
import '../../models/user.dart' as app_user;
import '../../providers/firestore_provider.dart';
import '../../providers/auth_provider.dart';

class SectionDetailsScreen extends StatefulWidget {
  final Section section;

  const SectionDetailsScreen({super.key, required this.section});

  @override
  State<SectionDetailsScreen> createState() => _SectionDetailsScreenState();
}

class _EditSubjectsSheet extends StatefulWidget {
  final List<String> subjects;

  const _EditSubjectsSheet({required this.subjects}); // fixed unused key

  @override
  State<_EditSubjectsSheet> createState() => _EditSubjectsSheetState();
}

class _EditSubjectsSheetState extends State<_EditSubjectsSheet> {
  late List<String> _subjects;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _subjects = List<String>.from(widget.subjects);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addSubject() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    if (_subjects.contains(text)) return;
    setState(() {
      _subjects.add(text);
      _controller.clear();
    });
  }

  void _removeSubject(String subject) {
    setState(() => _subjects.remove(subject));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Edit Subjects',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _subjects
                .map(
                  (s) => Chip(
                    label: Text(s, style: GoogleFonts.poppins()),
                    onDeleted: () => _removeSubject(s),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'New Subject',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(onPressed: _addSubject, child: const Text('Add')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_subjects),
                child: Text('Save', style: GoogleFonts.poppins()),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionDetailsScreenState extends State<SectionDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  Section? _section;

  List<app_user.User> _students = [];
  final Map<String, String> _studentNames = {};
  bool _isLoadingStudents = true;

  List<Attendance> _attendanceRecords = [];
  bool _isLoadingAttendance = true;

  List<Map<String, dynamic>> _announcements = [];
  bool _isLoadingAnnouncements = true;
  String? _announcementsError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSection();
    _fetchStudents();
    _fetchAttendanceRecords();
    _fetchAnnouncements();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSection() async {
    final firestoreProvider = context.read<FirestoreProvider>();
    final section = await firestoreProvider.getSectionById(widget.section.id);

    if (!mounted) return;

    if (section != null) {
      setState(() {
        _section = section;
      });
      debugPrint(
        'Loaded section ${section.id} with subjects: ${section.subjects}',
      );
    }
  }

  Future<void> _fetchStudents() async {
    setState(() {
      _isLoadingStudents = true;
    });

    final firestoreProvider = context.read<FirestoreProvider>();
    final sectionId = _section?.id ?? widget.section.id;
    final students = await firestoreProvider.getStudentsForSection(sectionId);

    if (!mounted) return;

    setState(() {
      _students = students;
      _studentNames
        ..clear()
        ..addEntries(students.map((s) => MapEntry(s.id, s.name)));
      _isLoadingStudents = false;
    });
  }

  Future<void> _fetchAttendanceRecords() async {
    setState(() {
      _isLoadingAttendance = true;
    });

    final firestoreProvider = context.read<FirestoreProvider>();
    final sectionId = _section?.id ?? widget.section.id;
    final records = await firestoreProvider.getAttendanceForSection(sectionId);

    if (!mounted) return;

    setState(() {
      _attendanceRecords = records;
      _isLoadingAttendance = false;
    });
  }

  Future<void> _markAbsenteesToday() async {
    final sectionId = _section?.id ?? widget.section.id;
    final firestoreProvider = context.read<FirestoreProvider>();

    setState(() {
      _isLoadingAttendance = true;
    });

    try {
      final created = await firestoreProvider.markAbsenteesForSection(
        sectionId,
      );
      await _fetchAttendanceRecords();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Marked $created students as absent for today.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to mark absentees: $e')));
      setState(() {
        _isLoadingAttendance = false;
      });
    }
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _isLoadingAnnouncements = true;
      _announcementsError = null;
    });

    final firestoreProvider = context.read<FirestoreProvider>();

    try {
      final sectionId = _section?.id ?? widget.section.id;
      final announcements = await firestoreProvider.getAnnouncements(
        sectionId: sectionId,
      );

      if (!mounted) return;

      setState(() {
        _announcements = announcements;
        _isLoadingAnnouncements = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoadingAnnouncements = false;
        _announcementsError = e.toString();
      });
    }
  }

  Future<void> _confirmDeleteStudent(app_user.User student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Student', style: GoogleFonts.poppins()),
        content: Text(
          'Are you sure you want to remove ${student.name} from this section?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: GoogleFonts.poppins()),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Remove', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (!mounted) return;

    try {
      final firestoreProvider = context.read<FirestoreProvider>();
      final sectionId = _section?.id ?? widget.section.id;

      await firestoreProvider.unenrollStudentFromSection(student.id, sectionId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${student.name} removed from section')),
      );

      // Refresh the students list and section data
      await _fetchStudents();
      await _loadSection();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to remove student: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSection = _section ?? widget.section;
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimaryContainer = colorScheme.onPrimaryContainer;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: CustomAppBar(title: 'Section Details'),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 14 : 18,
              isSmallScreen ? 14 : 16,
              isSmallScreen ? 14 : 18,
              isSmallScreen ? 10 : 12,
            ),
            color: colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with name and schedule
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSection.name,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 20 : 22,
                              fontWeight: FontWeight.w700,
                              color: onPrimaryContainer,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentSection.teacherName,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 12 : 13,
                              color: onPrimaryContainer.withValues(alpha: 0.75),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 10 : 12,
                        vertical: isSmallScreen ? 5 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: onPrimaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            size: isSmallScreen ? 14 : 16,
                            color: onPrimaryContainer.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentSection.schedule,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 11 : 12,
                              color: onPrimaryContainer.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Subjects
                if (currentSection.subjects.isNotEmpty)
                  Wrap(
                    spacing: isSmallScreen ? 5 : 6,
                    runSpacing: isSmallScreen ? 3 : 4,
                    children: currentSection.subjects.map((subject) {
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 10,
                          vertical: isSmallScreen ? 3 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: onPrimaryContainer.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          subject,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 10 : 11,
                            fontWeight: FontWeight.w500,
                            color: onPrimaryContainer,
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    'No subjects assigned yet',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 10 : 11,
                      color: onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                const SizedBox(height: 6),

                // Student count
                Row(
                  children: [
                    Icon(
                      Icons.group,
                      size: isSmallScreen ? 16 : 18,
                      color: onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${currentSection.studentCount} Students',
                      style: GoogleFonts.poppins(
                        fontSize: isSmallScreen ? 11 : 12,
                        color: onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Join Code Card
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                  decoration: BoxDecoration(
                    color: onPrimaryContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Join Code',
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 9 : 10,
                              fontWeight: FontWeight.w500,
                              color: onPrimaryContainer.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            currentSection.joinCode,
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        iconSize: isSmallScreen ? 16 : 18,
                        color: onPrimaryContainer,
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(text: currentSection.joinCode),
                          );
                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Join code copied to clipboard'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            color: colorScheme.surface,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Students'),
                Tab(text: 'Attendance'),
                Tab(text: 'Announcements'),
              ],
              labelStyle: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStudentsTab(),
                _buildAttendanceTab(),
                _buildAnnouncementsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildRoleBasedFAB(
        context,
        currentSection,
        colorScheme,
      ),
    );
  }

  Widget _buildRoleBasedFAB(
    BuildContext context,
    Section currentSection,
    ColorScheme colorScheme,
  ) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firebaseUser = authProvider.currentUser;

    if (firebaseUser == null) return const SizedBox.shrink();

    // Use FutureBuilder to fetch app user data
    return FutureBuilder<app_user.User?>(
      future: Provider.of<FirestoreProvider>(
        context,
        listen: false,
      ).getUser(firebaseUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final appUser = snapshot.data;
        if (appUser == null) return const SizedBox.shrink();

        // Check if current user is a teacher (teachers see their own sections, students see enrolled sections)
        final isTeacher = appUser.role == 'teacher';

        if (isTeacher) {
          // Teacher: Show QR code button
          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/generate_qr',
                arguments: currentSection,
              );
            },
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            icon: const Icon(Icons.qr_code),
            label: Text(
              'Show QR',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          );
        } else {
          // Student: Show scanner button to mark attendance
          return FloatingActionButton.extended(
            onPressed: () async {
              // Navigate to scanner for marking attendance
              await Navigator.pushNamed(context, '/scan_class_qr');
              // Refresh attendance after scanning
              if (!mounted) return;
              _fetchAttendanceRecords();
            },
            backgroundColor: colorScheme.secondary,
            foregroundColor: colorScheme.onSecondary,
            icon: const Icon(Icons.qr_code_scanner),
            label: Text(
              'Scan QR',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
            ),
          );
        }
      },
    );
  }

  Widget _buildStudentsTab() {
    if (_isLoadingStudents) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_students.isEmpty) {
      return Center(
        child: Text(
          'No students enrolled yet.',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.uid;

    return FutureBuilder<app_user.User?>(
      future: currentUserId != null
          ? Provider.of<FirestoreProvider>(
              context,
              listen: false,
            ).getUser(currentUserId)
          : null,
      builder: (context, snapshot) {
        final isTeacher = snapshot.data?.role == 'teacher';

        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
            isSmallScreen ? 12 : 16,
            isSmallScreen ? 10 : 12,
            isSmallScreen ? 12 : 16,
            isSmallScreen ? 10 : 12,
          ),
          itemCount: _students.length,
          itemBuilder: (context, index) {
            final student = _students[index];

            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  ProfileAvatar(
                    name: student.name,
                    radius: isSmallScreen ? 18 : 20,
                  ),
                  SizedBox(width: isSmallScreen ? 10 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'ID: ${student.studentId ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 10 : 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isTeacher)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: Colors.red,
                      iconSize: isSmallScreen ? 20 : 22,
                      tooltip: 'Remove student',
                      onPressed: () => _confirmDeleteStudent(student),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    if (_isLoadingAttendance) {
      return const Center(child: CircularProgressIndicator());
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final isTeacher = auth.currentUser != null;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        if (isTeacher)
          Padding(
            padding: EdgeInsets.fromLTRB(
              isSmallScreen ? 14 : 20,
              isSmallScreen ? 14 : 20,
              isSmallScreen ? 14 : 20,
              0,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_off_outlined),
                label: Text(
                  'Mark remaining as Absent today',
                  style: GoogleFonts.poppins(fontSize: isSmallScreen ? 12 : 14),
                ),
                onPressed: _markAbsenteesToday,
              ),
            ),
          ),
        if (_attendanceRecords.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                'No attendance records found.',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.fromLTRB(
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 10 : 12,
                isSmallScreen ? 12 : 16,
                isSmallScreen ? 10 : 12,
              ),
              itemCount: _attendanceRecords.length,
              itemBuilder: (context, index) {
                final record = _attendanceRecords[index];
                final statusText =
                    record.status ?? (record.isPresent ? 'Present' : 'Absent');
                final statusColor = record.isPresent
                    ? Colors.green
                    : Colors.red;
                final dateStr = record.date
                    .toLocal()
                    .toIso8601String()
                    .substring(0, 10);

                return Container(
                  margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
                  padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 8 : 10),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          statusText == 'Present'
                              ? Icons.check_circle
                              : Icons.cancel,
                          size: isSmallScreen ? 18 : 20,
                          color: statusColor,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _studentNames[record.studentId] ??
                                  'Unknown student',
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 13 : 14,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateStr,
                              style: GoogleFonts.poppins(
                                fontSize: isSmallScreen ? 10 : 11,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 8 : 10,
                          vertical: isSmallScreen ? 5 : 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 10 : 11,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAnnouncementsTab() {
    if (_isLoadingAnnouncements) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_announcementsError != null) {
      return Center(
        child: Text(
          'Error loading announcements: $_announcementsError',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.red,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Text(
          'No announcements yet.',
          style: GoogleFonts.poppins(
            fontSize: MediaQuery.of(context).size.width < 600 ? 14 : 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 10 : 12,
        isSmallScreen ? 12 : 16,
        isSmallScreen ? 10 : 12,
      ),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final announcement = _announcements[index];
        final createdAt = announcement['createdAt'] as DateTime;
        final now = DateTime.now();
        final difference = now.difference(createdAt);

        String timeAgo;
        if (difference.inDays > 0) {
          timeAgo = '${difference.inDays}d ago';
        } else if (difference.inHours > 0) {
          timeAgo = '${difference.inHours}h ago';
        } else if (difference.inMinutes > 0) {
          timeAgo = '${difference.inMinutes}m ago';
        } else {
          timeAgo = 'Just now';
        }

        return Container(
          margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 7 : 8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.announcement_rounded,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          size: isSmallScreen ? 16 : 18,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 10),
                      Expanded(
                        child: Text(
                          announcement['title'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 24 : 28),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    announcement['content'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    timeAgo,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 9 : 10,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  iconSize: isSmallScreen ? 18 : 20,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final firestoreProvider = context.read<FirestoreProvider>();

                    final confirmDelete =
                        await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Announcement'),
                            content: const Text(
                              'Are you sure you want to delete this announcement?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (!context.mounted) return;

                    if (!confirmDelete) return;

                    try {
                      await firestoreProvider.deleteAnnouncement(
                        announcement['id'],
                      );

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Announcement deleted')),
                      );

                      _fetchAnnouncements();
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to delete announcement: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
