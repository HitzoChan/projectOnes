class User {
  final String id;
  final String name;
  final String email;
  final String role; // 'student' or 'teacher'
  final String? profileImageUrl;
  final String? studentId; // Unique student ID like S-2025-001
  final String? phone;
  final String? address;
  final String? grade;
  final String? section;
  // Teacher-specific fields
  final String? subject;
  final String? department;
  final int? yearsOfExperience;
  final String? bio;
  final String? certifications;
  final String? specializations;
  final bool? availableForConsultation;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.profileImageUrl,
    this.studentId,
    this.phone,
    this.address,
    this.grade,
    this.section,
    this.subject,
    this.department,
    this.yearsOfExperience,
    this.bio,
    this.certifications,
    this.specializations,
    this.availableForConsultation,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? profileImageUrl,
    String? studentId,
    String? phone,
    String? address,
    String? grade,
    String? section,
    String? subject,
    String? department,
    int? yearsOfExperience,
    String? bio,
    String? certifications,
    String? specializations,
    bool? availableForConsultation,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      studentId: studentId ?? this.studentId,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      grade: grade ?? this.grade,
      section: section ?? this.section,
      subject: subject ?? this.subject,
      department: department ?? this.department,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      bio: bio ?? this.bio,
      certifications: certifications ?? this.certifications,
      specializations: specializations ?? this.specializations,
      availableForConsultation: availableForConsultation ?? this.availableForConsultation,
    );
  }
}
