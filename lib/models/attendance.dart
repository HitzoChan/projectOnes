class Attendance {
  final String id;
  final String studentId;
  final String sectionId;
  final DateTime date;
  final bool isPresent;
  final DateTime? timestamp;
  final String? status; // 'Present', 'Late', 'Absent'

  Attendance({
    required this.id,
    required this.studentId,
    required this.sectionId,
    required this.date,
    required this.isPresent,
    this.timestamp,
    this.status,
  });

  // Helper method to get status
  String get attendanceStatus {
    if (status != null) return status!;
    return isPresent ? 'Present' : 'Absent';
  }

  // Helper method to get display time
  String get displayTime {
    if (timestamp != null) {
      return '${timestamp!.hour.toString().padLeft(2, '0')}:${timestamp!.minute.toString().padLeft(2, '0')}';
    }
    return '-';
  }
}
