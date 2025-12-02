import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user.dart' as app_user;
import '../models/section.dart';
import '../models/attendance.dart';

class FirestoreProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> createUser(app_user.User user) async {
    String? studentId = user.studentId;
    if (user.role == 'student' && studentId == null) {
      final year = DateTime.now().year;
      final counterRef =
          _firestore.collection('counters').doc('student_id_$year');

      final result =
          await _firestore.runTransaction<int>((transaction) async {
        final counterDoc = await transaction.get(counterRef);
        int nextNumber = 1;
        if (counterDoc.exists) {
          nextNumber = (counterDoc.data()?['count'] as int? ?? 0) + 1;
        }
        transaction.set(counterRef, {'count': nextNumber},
            SetOptions(merge: true));
        return nextNumber;
      });

      studentId = 'S-$year-${result.toString().padLeft(3, '0')}';
    }

    await _firestore.collection('users').doc(user.id).set({
      'name': user.name,
      'email': user.email,
      'role': user.role,
      'profileImageUrl': user.profileImageUrl,
      'studentId': studentId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get students enrolled in a section
  Future<List<app_user.User>> getStudentsForSection(String sectionId) async {
    final enrollmentSnapshot = await _firestore
        .collection('enrollments')
        .where('sectionId', isEqualTo: sectionId)
        .get();

    final studentIds = enrollmentSnapshot.docs
        .map((doc) => doc['studentId'] as String)
        .toList();

    if (studentIds.isEmpty) {
      return [];
    }

    final usersSnapshot = await _firestore
        .collection('users')
        .where(FieldPath.documentId, whereIn: studentIds)
        .get();

    return usersSnapshot.docs.map((doc) {
      final data = doc.data();
      return app_user.User(
        id: doc.id,
        name: data['name'],
        email: data['email'],
        role: data['role'],
        profileImageUrl: data['profileImageUrl'],
        studentId: data['studentId'],
        phone: data['phone'],
        address: data['address'],
        grade: data['grade'],
        section: data['section'],
        subject: data['subject'],
        department: data['department'],
        yearsOfExperience: data['yearsOfExperience'],
        bio: data['bio'],
        certifications: data['certifications'],
        specializations: data['specializations'],
        availableForConsultation: data['availableForConsultation'],
      );
    }).toList();
  }

  Future<app_user.User?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      
      // Helper function to get non-empty string or null
      String? getNonEmptyString(String key) {
        final value = data[key];
        if (value == null || value.toString().isEmpty) {
          return null;
        }
        return value.toString();
      }
      
      return app_user.User(
        id: doc.id,
        name: data['name'],
        email: data['email'],
        role: data['role'],
        profileImageUrl: getNonEmptyString('profileImageUrl'),
        studentId: getNonEmptyString('studentId'),
        phone: getNonEmptyString('phone'),
        address: getNonEmptyString('address'),
        grade: getNonEmptyString('grade'),
        section: getNonEmptyString('section'),
        subject: getNonEmptyString('subject'),
        department: getNonEmptyString('department'),
        yearsOfExperience: data['yearsOfExperience'],
        bio: getNonEmptyString('bio'),
        certifications: getNonEmptyString('certifications'),
        specializations: getNonEmptyString('specializations'),
        availableForConsultation: data['availableForConsultation'],
      );
    }
    return null;
  }

  Future<void> updateUser(app_user.User user) async {
    try {
      final data = <String, dynamic>{
        'name': user.name,
        'email': user.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Add optional fields only if they have values
      if (user.phone != null && user.phone!.isNotEmpty) {
        data['phone'] = user.phone;
      }
      if (user.address != null && user.address!.isNotEmpty) {
        data['address'] = user.address;
      }
      if (user.grade != null && user.grade!.isNotEmpty) {
        data['grade'] = user.grade;
      }
      if (user.section != null && user.section!.isNotEmpty) {
        data['section'] = user.section;
      }
      if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
        data['profileImageUrl'] = user.profileImageUrl;
      }
      
      // Teacher-specific fields - only add if they have actual values
      if (user.subject != null && user.subject!.isNotEmpty) {
        data['subject'] = user.subject;
      }
      
      if (user.department != null && user.department!.isNotEmpty) {
        data['department'] = user.department;
      }
      
      if (user.yearsOfExperience != null && user.yearsOfExperience! > 0) {
        data['yearsOfExperience'] = user.yearsOfExperience;
      }
      
      if (user.bio != null && user.bio!.isNotEmpty) {
        data['bio'] = user.bio;
      }
      
      if (user.certifications != null && user.certifications!.isNotEmpty) {
        data['certifications'] = user.certifications;
      }
      
      if (user.specializations != null && user.specializations!.isNotEmpty) {
        data['specializations'] = user.specializations;
      }
      
      if (user.availableForConsultation != null) {
        data['availableForConsultation'] = user.availableForConsultation;
      }
      
      // Use set with merge to create fields if they don't exist
      await _firestore.collection('users').doc(user.id).set(data, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // Section operations
  Future<void> createSection(Section section) async {
    final data = <String, dynamic>{
      'name': section.name,
      'teacherName': section.teacherName,
      'studentCount': section.studentCount,
      'schedule': section.schedule,
      'subjects': section.subjects,
      'joinCode': section.joinCode,
      'createdAt': FieldValue.serverTimestamp(),
    };
    if (section.teacherId != null) {
      data['teacherId'] = section.teacherId;
    }

    // Use set with merge to avoid overwriting unexpected fields
    await _firestore.collection('sections').doc(section.id).set(data, SetOptions(merge: true));
  }

  Future<List<Section>> getSections() async {
    final snapshot = await _firestore.collection('sections').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Section(
        id: doc.id,
        name: data['name'],
        teacherName: data['teacherName'],
        studentCount: data['studentCount'],
        schedule: data['schedule'],
        joinCode: data['joinCode'] ?? '', // Fix: provide joinCode
        subjects: List<String>.from(data['subjects'] ?? []),
      );
    }).toList();
  }

  // Get sections for a teacher. Prefer querying by UID (teacherId).
  // `teacherIdentifier` should be the teacher UID; UI callers should pass the current user's uid.
  // For backward compatibility this will fallback to matching `teacherName` and attach teacherId to matched docs.
  Future<List<Section>> getSectionsByTeacher(String teacherUid, {String? teacherName}) async {
    // First try by teacherId
    final snapshotById = await _firestore
        .collection('sections')
        .where('teacherId', isEqualTo: teacherUid)
        .get();

    if (snapshotById.docs.isNotEmpty) {
      return snapshotById.docs.map((doc) {
        final data = doc.data();
        return Section(
          id: doc.id,
          name: data['name'],
          teacherName: data['teacherName'] ?? '',
          teacherId: data['teacherId'],
          studentCount: data['studentCount'] ?? 0,
          schedule: data['schedule'] ?? '',
          joinCode: data['joinCode'] ?? '',
          subjects: List<String>.from(data['subjects'] ?? []),
        );
      }).toList();
    }

    // Fallback: if a teacherName was provided, query by teacherName (for existing data), then migrate docs by adding teacherId
    if (teacherName != null && teacherName.isNotEmpty) {
      final snapshotByName = await _firestore
          .collection('sections')
          .where('teacherName', isEqualTo: teacherName)
          .get();

      // If we find sections by name, migrate them to include teacherId = teacherUid
      if (snapshotByName.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshotByName.docs) {
          final ref = _firestore.collection('sections').doc(doc.id);
          batch.set(ref, {'teacherId': teacherUid}, SetOptions(merge: true));
        }
        await batch.commit();
      }

      return snapshotByName.docs.map((doc) {
        final data = doc.data();
        return Section(
          id: doc.id,
          name: data['name'],
          teacherName: data['teacherName'] ?? '',
          teacherId: data['teacherId'] ?? teacherUid,
          studentCount: data['studentCount'] ?? 0,
          schedule: data['schedule'] ?? '',
          joinCode: data['joinCode'] ?? '',
          subjects: List<String>.from(data['subjects'] ?? []),
        );
      }).toList();
    }

    return [];
  }

  Future<List<Section>> getSectionsForStudent(String studentId) async {
    final enrollmentSnapshot = await _firestore
        .collection('enrollments')
        .where('studentId', isEqualTo: studentId)
        .get();

    final sectionIds =
        enrollmentSnapshot.docs.map((doc) => doc['sectionId'] as String).toList();

    if (sectionIds.isEmpty) return [];

    final sectionsSnapshot = await _firestore
        .collection('sections')
        .where(FieldPath.documentId, whereIn: sectionIds)
        .get();

    return sectionsSnapshot.docs.map((doc) {
      final data = doc.data();
      return Section(
        id: doc.id,
        name: data['name'],
        teacherName: data['teacherName'],
        studentCount: (data['studentCount'] ?? 0) is int
            ? data['studentCount']
            : int.tryParse(data['studentCount']?.toString() ?? '0') ?? 0,
        schedule: data['schedule'],
        joinCode: data['joinCode'] ?? '', // Fix: include joinCode
        subjects: List<String>.from(data['subjects'] ?? []),
      );
    }).toList();
  }

  /// Find a section by its join code (used when QR contains JOINCODE token)
  Future<Section?> getSectionByJoinCode(String joinCode) async {
    final snapshot = await _firestore
        .collection('sections')
        .where('joinCode', isEqualTo: joinCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final doc = snapshot.docs.first;
    final data = doc.data();
    return Section(
      id: doc.id,
      name: data['name'],
      teacherName: data['teacherName'] ?? '',
      teacherId: data['teacherId'],
      studentCount: data['studentCount'] ?? 0,
      schedule: data['schedule'] ?? '',
      joinCode: data['joinCode'] ?? '',
      subjects: List<String>.from(data['subjects'] ?? []),
    );
  }

  Future<void> enrollStudentInSection(
      String studentId, String sectionId) async {
    final enrollmentsRef = _firestore.collection('enrollments');
    final sectionRef = _firestore.collection('sections').doc(sectionId);

    // Use a batch write to add enrollment and increment student count atomically
    final batch = _firestore.batch();

    final newEnrollmentRef = enrollmentsRef.doc();
    batch.set(newEnrollmentRef, {
      'studentId': studentId,
      'sectionId': sectionId,
      'enrolledAt': FieldValue.serverTimestamp(),
    });

    batch.update(sectionRef, {
      'studentCount': FieldValue.increment(1),
    });

    await batch.commit();
  }

  // Attendance operations
  Future<void> markAttendance(Attendance attendance) async {
    await _firestore.collection('attendance').add({
      'studentId': attendance.studentId,
      'sectionId': attendance.sectionId,
      'date': attendance.date,
      'isPresent': attendance.isPresent,
      'status': attendance.status ?? attendance.attendanceStatus,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<app_user.User?> getUserByStudentId(String studentId) async {
    final snapshot = await _firestore
        .collection('users')
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    
    if (snapshot.docs.isEmpty) return null;
    
    final doc = snapshot.docs.first;
    final data = doc.data();
    return app_user.User(
      id: doc.id,
      name: data['name'],
      email: data['email'],
      role: data['role'],
      studentId: data['studentId'],
    );
  }

  Future<List<Attendance>> getAttendanceForSection(String sectionId) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('sectionId', isEqualTo: sectionId)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Attendance(
        id: doc.id,
        studentId: data['studentId'],
        sectionId: data['sectionId'],
        date: (data['date'] as Timestamp).toDate(),
        isPresent: data['isPresent'],
        status: data['status'],
        timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null,
      );
    }).toList();
  }

  Future<List<Attendance>> getAttendanceForStudent(String studentId) async {
    final snapshot = await _firestore
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .get();
    final attendances = snapshot.docs.map((doc) {
      final data = doc.data();
      return Attendance(
        id: doc.id,
        studentId: data['studentId'],
        sectionId: data['sectionId'],
        date: (data['date'] as Timestamp).toDate(),
        isPresent: data['isPresent'],
        status: data['status'],
        timestamp: data['timestamp'] != null ? (data['timestamp'] as Timestamp).toDate() : null,
      );
    }).toList();

    attendances.sort((a, b) => b.date.compareTo(a.date));
    return attendances;
  }

  // Announcement operations
  Future<void> createAnnouncement(
      String title, String content, String teacherId,
      {List<String>? sectionIds}) async {
    await _firestore.collection('announcements').add({
      'title': title,
      'content': content,
      'teacherId': teacherId,
      'sectionIds': sectionIds ?? [],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await _firestore.collection('announcements').doc(announcementId).delete();
  }

  // Delete a section by its ID
  Future<void> deleteSection(String sectionId) async {
    final sectionRef = _firestore.collection('sections').doc(sectionId);

    // Optional: delete enrollments related to this section
    final enrollmentsSnapshot = await _firestore
        .collection('enrollments')
        .where('sectionId', isEqualTo: sectionId)
        .get();

    final batch = _firestore.batch();

    for (final doc in enrollmentsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    batch.delete(sectionRef);

    await batch.commit();
  }

  Future<void> updateSectionSubjects(String sectionId, List<String> subjects) async {
    debugPrint('Updating section($sectionId) subjects: $subjects');
    await _firestore.collection('sections').doc(sectionId).update({
      'subjects': subjects,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Fetch a single section by id and return Section model
  Future<Section?> getSectionById(String sectionId) async {
    final doc = await _firestore.collection('sections').doc(sectionId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return Section(
      id: doc.id,
      name: data['name'] ?? '',
      teacherName: data['teacherName'] ?? '',
      studentCount: (data['studentCount'] ?? 0) is int
          ? data['studentCount']
          : int.tryParse(data['studentCount']?.toString() ?? '0') ?? 0,
      schedule: data['schedule'] ?? '',
      joinCode: data['joinCode'] ?? '',
      subjects: List<String>.from(data['subjects'] ?? []),
    );
  }

  // FIXED NULL-SAFETY + TYPE CASTING HERE 👇
  Future<List<Map<String, dynamic>>> getAnnouncements(
      {String? sectionId}) async {
    Query query = _firestore
        .collection('announcements')
        .orderBy('createdAt', descending: true);

    if (sectionId != null) {
      query = query.where('sectionIds', arrayContains: sectionId);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) {
      final Map<String, dynamic>? data =
          doc.data() as Map<String, dynamic>?;

      if (data == null) {
        return {
          'id': doc.id,
          'title': '',
          'content': '',
          'teacherId': '',
          'sectionIds': <String>[],
          'createdAt': DateTime.now(),
        };
      }

      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'content': data['content'] ?? '',
        'teacherId': data['teacherId'] ?? '',
        'sectionIds': List<String>.from(data['sectionIds'] ?? []),
        'createdAt':
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      };
    }).toList();
  }
}
