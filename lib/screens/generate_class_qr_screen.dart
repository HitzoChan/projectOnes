import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_app_bar.dart';
import '../models/section.dart';

class GenerateClassQrScreen extends StatefulWidget {
  const GenerateClassQrScreen({super.key});

  @override
  State<GenerateClassQrScreen> createState() => _GenerateClassQrScreenState();
}

class _GenerateClassQrScreenState extends State<GenerateClassQrScreen> {
  // Mock sections
  final List<Section> mockSections = [
    Section(
      id: '1',
      name: 'Mathematics 101',
      teacherName: 'Jane Smith',
      studentCount: 25,
      schedule: 'Mon, Wed 9:00 AM',
      joinCode: 'MATH101',
    ),
    Section(
      id: '2',
      name: 'Physics 201',
      teacherName: 'Jane Smith',
      studentCount: 22,
      schedule: 'Tue, Thu 10:30 AM',
      joinCode: 'PHYS201',
    ),
  ];

  Section? selectedSection;
  DateTime selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Generate Class QR'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Class & Date',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // FIXED: value → initialValue
            DropdownButtonFormField<Section>(
              initialValue: selectedSection,
              decoration: const InputDecoration(
                labelText: 'Select Section',
                border: OutlineInputBorder(),
              ),
              items: mockSections.map((section) {
                return DropdownMenuItem(
                  value: section,
                  child: Text(section.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedSection = value;
                });
              },
            ),

            const SizedBox(height: 16),

            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  setState(() {
                    selectedDate = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Select Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            if (selectedSection != null) ...[
              Text(
                'Generated QR Code',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: QrImageView(
                      data:
                          'SECTION:${selectedSection!.id}|DATE:${selectedDate.toIso8601String()}|CLASS:${selectedSection!.name}|JOINCODE:${selectedSection!.joinCode}',
                      version: QrVersions.auto,
                      size: 200.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Class: ${selectedSection!.name}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Date: ${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('QR code shared!')),
                  );
                },
                icon: const Icon(Icons.share),
                label: Text(
                  'Share QR Code',
                  style: GoogleFonts.poppins(),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
