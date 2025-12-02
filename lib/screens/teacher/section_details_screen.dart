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
          Text('Edit Subjects',
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _subjects
                .map((s) => Chip(
                      label: Text(s, style: GoogleFonts.poppins()),
                      onDeleted: () => _removeSubject(s),
                    ))
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
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _addSubject,
                child: const Text('Add'),
              ),
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
      debugPrint('Loaded section ${section.id} with subjects: ${section.subjects}');
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

  Future<void> _fetchAnnouncements() async {
    setState(() {
      _isLoadingAnnouncements = true;
      _announcementsError = null;
    });

    final firestoreProvider = context.read<FirestoreProvider>();

    try {
      final sectionId = _section?.id ?? widget.section.id;
      final announcements =
          await firestoreProvider.getAnnouncements(sectionId: sectionId);

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

  @override
  Widget build(BuildContext context) {
    final currentSection = _section ?? widget.section;
    final colorScheme = Theme.of(context).colorScheme;
    final onPrimaryContainer = colorScheme.onPrimaryContainer;

    return Scaffold(
      appBar: CustomAppBar(title: 'Section Details'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: colorScheme.primaryContainer,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSection.name,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  currentSection.teacherName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: onPrimaryContainer.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.schedule,
                        size: 20, color: onPrimaryContainer.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text(
                      currentSection.schedule,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (currentSection.subjects.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(Icons.book,
                          size: 20, color: onPrimaryContainer.withValues(alpha: 0.7)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: currentSection.subjects.map((subject) {
                            return Chip(
                              label: Text(subject,
                                  style: GoogleFonts.poppins(fontSize: 12)),
                              backgroundColor:
                                  colorScheme.primaryContainer.withValues(alpha: 0.2),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit),
                      label: Text('Edit Subjects', style: GoogleFonts.poppins()),
                      onPressed: () async {
                        final firestoreProvider =
                            context.read<FirestoreProvider>();

                        final updated =
                            await showModalBottomSheet<List<String>>(
                          context: context,
                          isScrollControlled: true,
                          builder: (context) {
                            return _EditSubjectsSheet(
                              subjects:
                                  List<String>.from(currentSection.subjects),
                            );
                          },
                        );
                        if (!context.mounted) return; // Guard same BuildContext after await

                        if (updated != null) {
                          try {
                            await firestoreProvider.updateSectionSubjects(
                                currentSection.id, updated);
                            if (!context.mounted) return;

                            setState(() {
                              _section = Section(
                                id: currentSection.id,
                                name: currentSection.name,
                                teacherName: currentSection.teacherName,
                                studentCount: currentSection.studentCount,
                                schedule: currentSection.schedule,
                                joinCode: currentSection.joinCode,
                                subjects: List<String>.from(updated),
                              );
                            });
                          } catch (e) {
                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content:
                                      Text('Failed to update subjects: $e')),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                if (currentSection.subjects.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'No subjects assigned yet. Use Edit to add subjects.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: onPrimaryContainer.withValues(alpha: 0.7),
                    ),
                  ),
                ],
                Row(
                  children: [
                    Icon(Icons.group,
                        size: 20, color: onPrimaryContainer.withValues(alpha: 0.7)),
                    const SizedBox(width: 8),
                    Text(
                      '${currentSection.studentCount} Students',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: onPrimaryContainer.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Placeholder card for join code (TODO note removed)
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Join Code',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              currentSection.joinCode,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          color: colorScheme.primary,
                          onPressed: () async {
                            await Clipboard.setData(
                                ClipboardData(text: currentSection.joinCode));
                            if (!context.mounted) return; // Guard same BuildContext

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Join code copied to clipboard')),
                            );
                          },
                        ),
                      ],
                    ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/generate_qr', arguments: currentSection);
        },
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        child: const Icon(Icons.qr_code_scanner),
      ),
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
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _students.length,
      itemBuilder: (context, index) {
        final student = _students[index];

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: ProfileAvatar(
              name: student.name,
              radius: 24,
            ),
            title: Text(
              student.name,
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              'ID: ${student.studentId ?? 'N/A'}',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceTab() {
    if (_isLoadingAttendance) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_attendanceRecords.isEmpty) {
      return Center(
        child: Text(
          'No attendance records found.',
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _attendanceRecords.length,
      itemBuilder: (context, index) {
        final record = _attendanceRecords[index];

        final statusText = record.isPresent ? 'Present' : 'Absent';
        final statusColor = record.isPresent ? Colors.green : Colors.red;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(
              'Date: ${record.date.toLocal().toIso8601String().substring(0, 10)}',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              'Student ID: ${record.studentId}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color:
                    Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusText,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ),
          ),
        );
      },
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
              color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (_announcements.isEmpty) {
      return Center(
        child: Text(
          'No announcements yet.',
          style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        final announcement = _announcements[index];

        // Use Icons.announcement directly to avoid non-constant IconData
        const iconData = Icons.announcement;

        return Card(
          elevation: 1,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(iconData,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement['title'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        announcement['content'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        announcement['createdAt'] != null
                            ? (announcement['createdAt'] as DateTime)
                                .toLocal()
                                .toString()
                            : '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    final firestoreProvider =
                        context.read<FirestoreProvider>();

                      final confirmDelete = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Announcement'),
                            content: const Text(
                                'Are you sure you want to delete this announcement?'),
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
                      if (!context.mounted) return; // Guard same BuildContext after await

                    if (!confirmDelete) return;

                    try {
                      await firestoreProvider.deleteAnnouncement(
                          announcement['id']);

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Announcement deleted')),
                      );

                      _fetchAnnouncements();
                    } catch (e) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Failed to delete announcement: $e'),
                        backgroundColor: Colors.red,
                      ));
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
