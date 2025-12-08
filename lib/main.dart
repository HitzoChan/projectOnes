import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart' as auth_provider;
import 'providers/firestore_provider.dart';
import 'models/user.dart' as app_user;
import 'screens/unified_login_screen.dart';
import 'screens/role_selection_screen.dart';
import 'screens/teacher_dashboard.dart';
import 'screens/student/student_dashboard.dart' as student_dash;
import 'screens/student/my_qr_screen.dart' as student_qr;
import 'screens/student/scan_teacher_qr_screen.dart';
import 'screens/student/scan_class_qr_screen.dart';
import 'screens/student/my_sections_screen.dart' as student_sections;
import 'screens/student/join_section_screen.dart' as student_join;
import 'screens/attendance_report_screen.dart';
import 'screens/announcement_screen.dart';
import 'screens/student/student_announcements_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/teacher_identity_screen.dart';
import 'screens/teacher/teacher_sections_screen.dart';
import 'screens/teacher/create_section_screen.dart';
import 'models/section.dart';
import 'screens/teacher/section_details_screen.dart' as teacher_details;
import 'screens/teacher/generate_qr_screen.dart';
import 'screens/teacher/scan_attendance_screen.dart' as teacher_scan;
import 'screens/create_account_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/student/student_profile_edit_screen.dart';
import 'screens/privacy_security_screen.dart';
import 'screens/help_support_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasData) {
          // User is signed in, check if they have a role
          return FutureBuilder<app_user.User?>(
            future: Provider.of<FirestoreProvider>(context, listen: false)
                .getUser(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data != null) {
                // User exists in Firestore, navigate to appropriate dashboard
                final rawRole = userSnapshot.data!.role;
                final role = rawRole.toString().toLowerCase();
                debugPrint('Firestore user role for ${snapshot.data!.uid}: $rawRole (normalized: $role)');
                if (role == 'student') {
                  return const student_dash.StudentDashboard();
                } else if (role == 'teacher' || role.contains('teach')) {
                  return const TeacherDashboard();
                }
              }

              // User doesn't exist in Firestore or no role, go to role selection
              return const RoleSelectionScreen();
            },
          );
        }

        // User is not signed in, show login screen
        return const UnifiedLoginScreen();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth_provider.AuthProvider()),
        ChangeNotifierProvider(create: (_) => FirestoreProvider()),
      ],
      child: MaterialApp(
        title: 'EduScan',
        home: const AuthWrapper(),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          fontFamily: GoogleFonts.poppins().fontFamily,
          appBarTheme: AppBarTheme(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        initialRoute: '/login',
        routes: {
          '/login': (context) => const UnifiedLoginScreen(),
          '/role_selection': (context) => const RoleSelectionScreen(),
          '/student_dashboard': (context) => const student_dash.StudentDashboard(),
          '/teacher_dashboard': (context) => const TeacherDashboard(),
          '/my_qr': (context) => const student_qr.MyQrScreen(),
          '/scan_teacher_qr': (context) => const ScanTeacherQrScreen(),
          '/scan_class_qr': (context) => const ScanClassQrScreen(),
          '/my_sections': (context) => const student_sections.MySectionsScreen(),
          '/join_section': (context) => const student_join.JoinSectionScreen(),
          '/attendance_report': (context) => const AttendanceReportScreen(),
          '/announcements': (context) => const AnnouncementScreen(),
          '/student_announcements': (context) => const StudentAnnouncementsScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/privacy_security': (context) => const PrivacySecurityScreen(),
          '/help_support': (context) => const HelpSupportScreen(),
          '/profile_edit': (context) => const ProfileEditScreen(),
          '/student_profile_edit': (context) => StudentProfileEditScreen(),
          '/teacher_identity': (context) => const TeacherIdentityScreen(),
          // Teacher routes
          '/teacher_sections': (context) => const TeacherSectionsScreen(),
          '/create_section': (context) => const CreateSectionScreen(),
          '/generate_qr': (context) => const GenerateQrScreen(),
          '/scan_attendance': (context) => const teacher_scan.ScanAttendanceScreen(),
          '/create_account': (context) => const CreateAccountScreen(),
          '/forgot_password': (context) => const ForgotPasswordScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/section_details') {
            final section = settings.arguments as Section;
            return MaterialPageRoute(
              builder: (context) => teacher_details.SectionDetailsScreen(section: section),
            );
          }
          // Default routing if no match
          return null;
        },
      ),
    );
  }
}
