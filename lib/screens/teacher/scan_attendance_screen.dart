import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_app_bar.dart';
import '../../providers/firestore_provider.dart';
import '../../models/attendance.dart';

class ScanAttendanceScreen extends StatefulWidget {
  const ScanAttendanceScreen({super.key});

  @override
  State<ScanAttendanceScreen> createState() => _ScanAttendanceScreenState();
}

class _ScanAttendanceScreenState extends State<ScanAttendanceScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isFlashOn = false;
  bool _isFrontCamera = false;
  String? _selectedSectionId;
  int _recentScans = 0;
  final Set<String> _scannedToday = {};
  final Set<String> _processingStudents = {};

  @override
  void initState() {
    super.initState();
    // Show section selector when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showSectionSelector();
    });
  }

  Future<void> _showSectionSelector() async {
    final firestoreProvider = context.read<FirestoreProvider>();
    final sections = await firestoreProvider.getSections();
    
    if (!mounted) return;
    
    final selected = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Select Section', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: sections.map((section) {
            return ListTile(
              title: Text(section.name, style: GoogleFonts.poppins()),
              subtitle: Text(section.schedule, style: GoogleFonts.poppins(fontSize: 12)),
              onTap: () => Navigator.of(context).pop(section.id),
            );
          }).toList(),
        ),
      ),
    );
    
    if (selected != null) {
      setState(() {
        _selectedSectionId = selected;
      });
    } else {
      // If no section selected, go back
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Scan Attendance',
        actions: [
          IconButton(
            icon: const Icon(Icons.change_circle_outlined),
            onPressed: _showSectionSelector,
            tooltip: 'Change Section',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Real Camera Scanner
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final studentId = barcode.rawValue;
                if (studentId != null && studentId.isNotEmpty) {
                  _processScannedStudentId(studentId);
                }
              }
            },
          ),

          // Scanning Frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  // Corner decorations
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          left: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Colors.white, width: 4),
                          right: BorderSide(color: Colors.white, width: 4),
                        ),
                      ),
                    ),
                  ),

                  // Animated scanning line
                  Positioned(
                    top: 50,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.blue.shade400,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Instruction Text
                  Text(
                    'Scan student QR code',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Control Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Flash Button
                      _buildControlButton(
                        icon: _isFlashOn ? Icons.flash_on : Icons.flash_off,
                        label: 'Flash',
                        onPressed: () {
                          cameraController.toggleTorch();
                          setState(() {
                            _isFlashOn = !_isFlashOn;
                          });
                        },
                      ),

                      // Capture Button (Removed - automatic scanning)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner,
                          size: 32,
                          color: Colors.white,
                        ),
                      ),

                      // Switch Camera Button
                      _buildControlButton(
                        icon: Icons.flip_camera_ios,
                        label: 'Switch',
                        onPressed: () {
                          cameraController.switchCamera();
                          setState(() {
                            _isFrontCamera = !_isFrontCamera;
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Recent Scans (Optional overlay)
          Positioned(
            top: 100,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Recent',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_recentScans',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processScannedStudentId(String studentId) async {
    // Reject structured QR codes (e.g., class enrollment QRs meant for students)
    if (studentId.contains('SECTION:') || 
        studentId.contains('DATE:') || 
        studentId.contains('CLASS:') ||
        studentId.contains('JOINCODE:')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wrong QR code type. Please scan a student ID QR code.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent duplicate scans in this session
    if (_scannedToday.contains(studentId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student $studentId already scanned today'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent concurrent processing for the same student
    if (_processingStudents.contains(studentId)) return;
    _processingStudents.add(studentId);

    final firestoreProvider = context.read<FirestoreProvider>();
    
    try {
      // Get user by student ID
      final user = await firestoreProvider.getUserByStudentId(studentId);
      
      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student ID $studentId not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (_selectedSectionId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a section first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Calculate attendance status based on time
      final now = DateTime.now();
      String status = 'Present';
      // You can add logic here to determine if student is late
      // For example: if (now.hour > 8 && now.minute > 15) status = 'Late';

      // Create attendance record
      final attendance = Attendance(
        id: '',
        studentId: user.id,
        sectionId: _selectedSectionId!,
        date: now,
        isPresent: status != 'Absent',
        status: status,
        timestamp: now,
      );

      await firestoreProvider.markAttendance(attendance);
      
      _scannedToday.add(studentId);
      setState(() {
        _recentScans++;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${user.name} marked as $status'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _processingStudents.remove(studentId);
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
