import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/firestore_provider.dart';

class StudentAnnouncementsScreen extends StatefulWidget {
  const StudentAnnouncementsScreen({super.key});

  @override
  State<StudentAnnouncementsScreen> createState() => _StudentAnnouncementsScreenState();
}

class _StudentAnnouncementsScreenState extends State<StudentAnnouncementsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Announcements'),
      body: Padding(
        padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latest Announcements',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: Provider.of<FirestoreProvider>(context, listen: false).getAnnouncements(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading announcements',
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }

                  final announcements = snapshot.data ?? [];

                  if (announcements.isEmpty) {
                    return Center(
                      child: Text(
                        'No announcements yet',
                        style: GoogleFonts.poppins(),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      final createdAt = announcement['createdAt'] as DateTime;
                      final formattedDate = '${createdAt.day}/${createdAt.month}/${createdAt.year}';
                      final formattedTime = '${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}';

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                announcement['title'],
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                announcement['content'],
                                style: GoogleFonts.poppins(),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  FutureBuilder<String?>(
                                    future: _getTeacherName(announcement['teacherId']),
                                    builder: (context, teacherSnapshot) {
                                      final teacherName = teacherSnapshot.data ?? 'Unknown Teacher';
                                      return Text(
                                        'By: $teacherName',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                  Text(
                                    '$formattedDate $formattedTime',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
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
          ],
        ),
      ),
    );
  }

  Future<String?> _getTeacherName(String teacherId) async {
    final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);
    final teacher = await firestoreProvider.getUser(teacherId);
    return teacher?.name;
  }
}
