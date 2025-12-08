import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/firestore_provider.dart';
import '../providers/auth_provider.dart';
import '../models/section.dart';

class AnnouncementScreen extends StatefulWidget {
  const AnnouncementScreen({super.key});

  @override
  State<AnnouncementScreen> createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<AnnouncementScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _isLoading = false;

  List<Section> _sections = [];
  Map<String, bool> _selectedSections = {};

  @override
  void initState() {
    super.initState();
    _loadTeacherSections();
    _cleanupOldAnnouncements();
  }

  Future<void> _loadTeacherSections() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreProvider =
        Provider.of<FirestoreProvider>(context, listen: false);

    final teacherId = authProvider.currentUser?.uid;
    if (teacherId == null) return;

    final userDoc = await firestoreProvider.getUser(teacherId);
    final teacherName = userDoc?.name ?? authProvider.currentUser?.displayName ?? '';

    final sections = await firestoreProvider.getSectionsByTeacher(teacherId, teacherName: teacherName);

    if (!mounted) return;

    setState(() {
      _sections = sections;
      _selectedSections = {for (var s in sections) s.id: false};
    });
  }

  Future<void> _cleanupOldAnnouncements() async {
    try {
      final firestoreProvider =
          Provider.of<FirestoreProvider>(context, listen: false);

      // Get all announcements
      final announcements = await firestoreProvider.getAnnouncements();

      // Current time minus 48 hours
      final now = DateTime.now();
      final fortyEightHoursAgo = now.subtract(const Duration(hours: 48));

      // Delete announcements older than 48 hours
      for (final announcement in announcements) {
        final createdAt = announcement['createdAt'] as DateTime;

        if (createdAt.isBefore(fortyEightHoursAgo)) {
          await firestoreProvider.deleteAnnouncement(announcement['id']);
        }
      }
    } catch (e) {
      // Silently fail - don't disrupt app startup
      debugPrint('Error cleaning up old announcements: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Announcements"),
      body: Column(
        children: [
          // ------------------------------
          // Announcements List
          // ------------------------------
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: Provider.of<FirestoreProvider>(context, listen: false)
                  .getAnnouncements(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error loading announcements",
                        style: GoogleFonts.poppins()),
                  );
                }

                final announcements = snapshot.data ?? [];

                if (announcements.isEmpty) {
                  return Center(
                    child: Text("No announcements yet",
                        style: GoogleFonts.poppins()),
                  );
                }

                return ListView.builder(
                  itemCount: announcements.length,
                  itemBuilder: (context, index) {
                    final announcement = announcements[index];
                    final createdAt = announcement['createdAt'] as DateTime;

                    final date =
                        "${createdAt.day}/${createdAt.month}/${createdAt.year}";
                    final time =
                        "${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}";

                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    announcement['title'],
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text("$date $time",
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              announcement['content'],
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FutureBuilder<String?>(
                              future: _getTeacherName(
                                  announcement['teacherId']),
                              builder: (context, teacherSnapshot) {
                                return Text(
                                  "By: ${teacherSnapshot.data ?? 'Unknown Teacher'}",
                                  style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ------------------------------
          // Bottom Input Panel
          // ------------------------------
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Send New Announcement",
                  style: GoogleFonts.poppins(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),

                // ------------------------------
                // Section Multi-Select Dropdown
                // ------------------------------
                if (_sections.isNotEmpty)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ExpansionTile(
                      title: Text(
                        "Select Sections",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      children: _sections.map((section) {
                        final id = section.id;
                        return CheckboxListTile(
                          title: Text(section.name),
                          value: _selectedSections[id],
                          onChanged: (value) {
                            setState(() {
                              _selectedSections[id] = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),

                const SizedBox(height: 10),

                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                      labelText: "Title", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _messageController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                      labelText: "Message", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  onPressed: _isLoading ? null : _sendAnnouncement,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : Text("Send Announcement",
                          style: GoogleFonts.poppins()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------
  // Send Announcement
  // ------------------------------
  Future<void> _sendAnnouncement() async {
    if (!mounted) return;

    if (_titleController.text.isEmpty ||
        _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please fill in both title and message")));
      return;
    }

    final selectedSectionIds = _selectedSections.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();

    if (selectedSectionIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Please select at least one section")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider =
          Provider.of<AuthProvider>(context, listen: false);
      final firestoreProvider =
          Provider.of<FirestoreProvider>(context, listen: false);

      await firestoreProvider.createAnnouncement(
        _titleController.text,
        _messageController.text,
        authProvider.currentUser!.uid,
        sectionIds: selectedSectionIds,
      );

      if (!mounted) return;

      _titleController.clear();
      _messageController.clear();

      setState(() {
        _selectedSections = {
          for (var s in _sections) s.id: false,
        };
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Announcement sent successfully!")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ------------------------------
  // Get Teacher Name
  // ------------------------------
  Future<String?> _getTeacherName(String teacherId) async {
    final firestoreProvider =
        Provider.of<FirestoreProvider>(context, listen: false);
    final teacher = await firestoreProvider.getUser(teacherId);
    return teacher?.name;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
}
