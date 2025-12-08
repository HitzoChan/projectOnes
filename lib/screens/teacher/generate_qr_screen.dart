import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../widgets/custom_app_bar.dart';
import '../../components/teacher_bottom_nav.dart';
import '../../models/section.dart';
import '../../providers/auth_provider.dart';
import '../../providers/firestore_provider.dart';

class GenerateQrScreen extends StatefulWidget {
  const GenerateQrScreen({super.key});

  @override
  State<GenerateQrScreen> createState() => _GenerateQrScreenState();
}

class _GenerateQrScreenState extends State<GenerateQrScreen> {
  int _selectedIndex = 1;
  List<Section> _sections = [];
  Section? _selectedSection;
  DateTime _selectedDate = DateTime.now();
  bool _loadingSections = true;

  void _onNavTap(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/teacher_dashboard');
        break;

      case 1:
        break;

      case 2:
        if (!mounted) return;
        Navigator.pushNamed(context, '/teacher_sections');
        break;

      case 3:
        if (!mounted) return;
        Navigator.pushNamed(context, '/settings');
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTeacherSections();
  }

  Future<void> _loadTeacherSections() async {
    setState(() => _loadingSections = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);

    if (authProvider.currentUser != null) {
      try {
        final teacherId = authProvider.currentUser!.uid;
        final userDoc = await firestoreProvider.getUser(teacherId);
        final teacherName = userDoc?.name ?? authProvider.currentUser!.displayName ?? '';
        final sections = await firestoreProvider.getSectionsByTeacher(teacherId, teacherName: teacherName);

        if (!mounted) return;

        setState(() {
          _sections = sections;
          if (sections.isNotEmpty) {
            _selectedSection = sections.first;
          }
          _loadingSections = false;
        });
      } catch (e) {
        if (!mounted) return;

        setState(() => _loadingSections = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading sections: $e')),
        );
      }
    } else {
      if (!mounted) return;
      setState(() => _loadingSections = false);
    }
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (!mounted) return;

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _refreshQr() {
    setState(() {
      _selectedDate = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Class QR'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Show this QR to your students to record attendance',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              _loadingSections
                  ? const CircularProgressIndicator()
                  : _sections.isEmpty
                      ? Text(
                          'No sections assigned',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                      : Column(
                          children: [
                            DropdownButtonFormField<Section>(
                              initialValue: _selectedSection,
                              decoration: const InputDecoration(
                                labelText: 'Select Section',
                                border: OutlineInputBorder(),
                              ),
                              items: _sections.map((section) {
                                return DropdownMenuItem(
                                  value: section,
                                  child: Text(section.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedSection = value;
                                });
                              },
                            ),
                            const SizedBox(height: 16),

                            InkWell(
                              onTap: _pickDate,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Select Date',
                                  border: OutlineInputBorder(),
                                ),
                                child: Text(
                                  '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                                  style: GoogleFonts.poppins(),
                                ),
                              ),
                            ),
                          ],
                        ),

              const SizedBox(height: 40),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _selectedSection == null
                    ? Text(
                        'Select a section and date to generate QR code',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      )
                    : Column(
                        children: [
                          QrImageView(
                            data:
                                'SECTION:${_selectedSection!.id}|DATE:${_selectedDate.toIso8601String()}|CLASS:${_selectedSection!.name}',
                            size: 200.0,
                          ),
                          const SizedBox(height: 24),

                          Text(
                            _selectedSection!.name,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Valid for the selected date',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _refreshQr,
                      icon: const Icon(Icons.refresh),
                      label: Text(
                        'Refresh QR',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),

              const SizedBox(height: 40),

              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How it works',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInstructionStep('1',
                          'Display this QR code on your screen or projector'),
                      const SizedBox(height: 12),
                      _buildInstructionStep('2',
                          'Students scan the QR code with their phones'),
                      const SizedBox(height: 12),
                      _buildInstructionStep(
                          '3', 'Attendance is automatically recorded'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: TeacherBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTap,
      ),
    );
  }

  Widget _buildInstructionStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
