import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/profile_avatar.dart';
import '../providers/auth_provider.dart';
import '../providers/firestore_provider.dart';
import '../models/user.dart' as app_user;

class TeacherIdentityScreen extends StatefulWidget {
  const TeacherIdentityScreen({super.key});

  @override
  State<TeacherIdentityScreen> createState() => _TeacherIdentityScreenState();
}

class _TeacherIdentityScreenState extends State<TeacherIdentityScreen> {
  final _subjectController = TextEditingController();
  final _departmentController = TextEditingController();
  final _experienceController = TextEditingController();
  final _bioController = TextEditingController();
  final _certificationsController = TextEditingController();
  final _specializationsController = TextEditingController();
  
  bool _availableForConsultation = true;
  bool _isLoading = true;
  app_user.User? _currentUser;

  final List<String> _subjects = [
    'Mathematics',
    'Science',
    'English',
    'Filipino',
    'History',
    'Geography',
    'Physics',
    'Chemistry',
    'Biology',
    'Computer Science',
    'Arts',
    'Physical Education',
    'Values Education',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadTeacherData();
  }

  Future<void> _loadTeacherData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);
    
    final currentUser = authProvider.currentUser;
    if (currentUser != null) {
      final user = await firestoreProvider.getUser(currentUser.uid);
      if (!mounted) return;
      
      if (user != null) {
        setState(() {
          _currentUser = user;
          _subjectController.text = user.subject ?? '';
          _departmentController.text = user.department ?? '';
          _experienceController.text = user.yearsOfExperience?.toString() ?? '';
          _bioController.text = user.bio ?? '';
          _certificationsController.text = user.certifications ?? '';
          _specializationsController.text = user.specializations ?? '';
          _availableForConsultation = user.availableForConsultation ?? true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveTeacherIdentity() async {
    if (_currentUser == null) return;
    
    final firestoreProvider = Provider.of<FirestoreProvider>(context, listen: false);
    
    try {
      final updatedUser = _currentUser!.copyWith(
        subject: _subjectController.text,
        department: _departmentController.text,
        yearsOfExperience: _experienceController.text.isNotEmpty ? int.tryParse(_experienceController.text) : 0,
        bio: _bioController.text,
        certifications: _certificationsController.text,
        specializations: _specializationsController.text,
        availableForConsultation: _availableForConsultation,
      );
      
      await firestoreProvider.updateUser(updatedUser);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teacher identity saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Pop with result to trigger refresh in calling screen
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Teacher Identity'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Teacher Identity',
        actions: [
          TextButton(
            onPressed: _saveTeacherIdentity,
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 16 : 24),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Avatar Section
              Center(
                child: Column(
                  children: [
                    const ProfileAvatar(
                      name: 'Teacher',
                      radius: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Customize Your Teaching Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help students understand your expertise and teaching style',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Subject Section
              Text(
                'Subject & Specialization',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _subjectController.text.isEmpty ? null : _subjectController.text,
                decoration: const InputDecoration(
                  labelText: 'Primary Subject',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.subject),
                ),
                items: _subjects.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _subjectController.text = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _departmentController,
                decoration: const InputDecoration(
                  labelText: 'Department',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),

              const SizedBox(height: 32),

              // Experience Section
              Text(
                'Teaching Experience',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _experienceController,
                decoration: const InputDecoration(
                  labelText: 'Years of Experience',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.work_history),
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 32),

              // Bio Section
              Text(
                'Professional Bio',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Share your teaching philosophy and approach',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 500,
              ),

              const SizedBox(height: 32),

              // Additional Information Section
              Text(
                'Additional Information',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Certifications
              TextField(
                controller: _certificationsController,
                decoration: const InputDecoration(
                  labelText: 'Certifications (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.verified),
                  hintText: 'e.g., LET Passer, Master Teacher',
                ),
              ),

              const SizedBox(height: 16),

              // Specializations
              TextField(
                controller: _specializationsController,
                decoration: const InputDecoration(
                  labelText: 'Specializations (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.star),
                  hintText: 'e.g., Calculus, Algebra, Statistics',
                ),
              ),

              const SizedBox(height: 16),

              // Contact Preferences
              Text(
                'Contact Preferences',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              SwitchListTile(
                title: Text(
                  'Available for Student Consultation',
                  style: GoogleFonts.poppins(),
                ),
                subtitle: Text(
                  'Allow students to schedule one-on-one sessions',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                value: _availableForConsultation,
                onChanged: (value) {
                  setState(() {
                    _availableForConsultation = value;
                  });
                },
              ),

              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _saveTeacherIdentity,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                ),
                child: Text(
                  'Save Identity',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Preview Button
              OutlinedButton(
                onPressed: () {
                  // Show preview of how identity will appear to students
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Identity Preview',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subject: ${_subjectController.text}',
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            'Department: ${_departmentController.text}',
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            'Experience: ${_experienceController.text} years',
                            style: GoogleFonts.poppins(),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bio: ${_bioController.text}',
                            style: GoogleFonts.poppins(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: GoogleFonts.poppins(),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  'Preview Identity',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _departmentController.dispose();
    _experienceController.dispose();
    _bioController.dispose();
    _certificationsController.dispose();
    _specializationsController.dispose();
    super.dispose();
  }
}
