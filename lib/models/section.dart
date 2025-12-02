class Section {
  final String id;
  final String name;
  final String teacherName;
  final String? teacherId;
  final int studentCount;
  final String schedule;
  final String joinCode; // New field for join code
  final List<String> subjects; // Subjects taught in this section

  Section({
    required this.id,
    required this.name,
    required this.teacherName,
    this.teacherId,
    required this.studentCount,
    required this.schedule,
    required this.joinCode,
    this.subjects = const [],
  });
}
