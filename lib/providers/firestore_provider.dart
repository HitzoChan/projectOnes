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
  /// Marks attendance for a student in a section.
  /// Ensures only one attendance record per student per section per day.
  /// Returns `true` if a new attendance document was created, `false` if an existing record was updated.
  Future<bool> markAttendance(Attendance attendance) async {
    final dayStart = DateTime(attendance.date.year, attendance.date.month, attendance.date.day);

    // Use a deterministic daily document ID to avoid race conditions and duplicate writes.
    // Format: {sectionId}_{studentId}_YYYYMMDD
    final dayKey = '${dayStart.year.toString().padLeft(4, '0')}${dayStart.month.toString().padLeft(2, '0')}${dayStart.day.toString().padLeft(2, '0')}';
    final docId = '${attendance.sectionId}_${attendance.studentId}_$dayKey';
    final docRef = _firestore.collection('attendance').doc(docId);

    final existing = await docRef.get();
    final section = await getSectionById(attendance.sectionId);
    if (existing.exists) {
      await docRef.update({
        'isPresent': attendance.isPresent,
        'status': attendance.status ?? attendance.attendanceStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'teacherId': section?.teacherId,
      });
      return false;
    }

    // Create a new deterministic document for today's attendance for this student-section
    await docRef.set({
      'studentId': attendance.studentId,
      'sectionId': attendance.sectionId,
      'date': attendance.date,
      'isPresent': attendance.isPresent,
      'status': attendance.status ?? attendance.attendanceStatus,
      'timestamp': FieldValue.serverTimestamp(),
      'teacherId': section?.teacherId,
    });

    return true;
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

  /// Returns daily aggregated attendance counts for a teacher's sections for the past [days] days.
  /// Each map contains: 'date' (ISO yyyy-MM-dd), 'present', 'absent', 'late'.
  Future<List<Map<String, dynamic>>> getDailyAttendanceCountsForTeacher(String teacherUid, {int days = 7}) async {
    // Prefer querying by teacherId on attendance docs. This is more efficient than whereIn(sectionId).
    // If attendance docs were created before teacherId was added, consider running `backfillAttendanceTeacherIds`.
    final now = DateTime.now();
    final results = <Map<String, dynamic>>[];

    for (var d = days - 1; d >= 0; d--) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: d));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      int present = 0;
      int absent = 0;
      int late = 0;

      try {
        final snapshot = await _firestore
            .collection('attendance')
            .where('teacherId', isEqualTo: teacherUid)
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
            .where('date', isLessThan: Timestamp.fromDate(dayEnd))
            .get();

        for (final doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>?;
          final statusRaw = data?['status'];
          final isPresentRaw = data?['isPresent'];
          final status = statusRaw?.toString() ?? (isPresentRaw == true ? 'Present' : 'Absent');
          if (status == 'Present') {
            present++;
          } else if (status == 'Late') {
            late++;
          } else {
            absent++;
          }
        }
      } on FirebaseException catch (e) {
        // If the query fails (e.g. due to index issues), fallback to section-based chunked queries.
        debugPrint('teacher-based attendance query failed: ${e.code} ${e.message}');
        // Fallback: fetch sections and use previous chunking logic
        final sections = await getSectionsByTeacher(teacherUid);
        final sectionIds = sections.map((s) => s.id).toList();

        if (sectionIds.isNotEmpty) {
          // Helper to chunk list into groups of 10 (Firestore whereIn limit)
          List<List<String>> chunked(List<String> list, int size) {
            final out = <List<String>>[];
            for (var i = 0; i < list.length; i += size) {
              out.add(list.sublist(i, i + size > list.length ? list.length : i + size));
            }
            return out;
          }

          final chunks = chunked(sectionIds, 10);
          for (final chunk in chunks) {
            Query query = _firestore.collection('attendance')
                .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
                .where('date', isLessThan: Timestamp.fromDate(dayEnd));

            if (chunk.length == 1) {
              query = query.where('sectionId', isEqualTo: chunk.first);
            } else {
              query = query.where('sectionId', whereIn: chunk);
            }

            final snapshot = await query.get();
            for (final doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>?;
              final statusRaw = data?['status'];
              final isPresentRaw = data?['isPresent'];
              final status = statusRaw?.toString() ?? (isPresentRaw == true ? 'Present' : 'Absent');
              if (status == 'Present') {
                present++;
              } else if (status == 'Late') {
                late++;
              } else {
                absent++;
              }
            }
          }
        }
      }

      results.add({
        'date': '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
        'present': present,
        'absent': absent,
        'late': late,
      });
    }

    return results;
  }

  /// Backfill `teacherId` on attendance documents that are missing it.
  ///
  /// This queries attendance documents where `teacherId` is null (or missing depending on Firestore)
  /// and updates them by looking up the corresponding section's `teacherId`. Commit is done in batches
  /// to reduce writes and avoid large single transactions.
  ///
  /// WARNING: This can be an expensive operation on large collections. Run during off-hours and
  /// consider limiting the batch size.
  Future<int> backfillAttendanceTeacherIds({int batchSize = 200}) async {
    int updated = 0;
    // Query attendance docs that don't have teacherId set. Firestore supports `where('field', isNull: true)`.
    Query query = _firestore.collection('attendance').where('teacherId', isNull: true).limit(batchSize);

    while (true) {
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        final Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        final sectionId = data?['sectionId'] as String?;
        if (sectionId == null) continue;

        final section = await getSectionById(sectionId);
        if (section?.teacherId != null) {
          batch.update(doc.reference, {'teacherId': section!.teacherId});
          updated++;
        }
      }

      await batch.commit();

      // If less than batchSize docs were returned, we're done
      if (snapshot.docs.length < batchSize) break;
    }

    return updated;
  }

  /// Deduplicate attendance documents per student-section-day.
  ///
  /// This scans documents in `attendance`, groups them by a key of
  /// `{sectionId}_{studentId}_{YYYYMMDD}`, and for groups with more than one
  /// document it keeps the newest (by `timestamp`) and deletes others.
  ///
  /// Returns the number of deleted documents.
  Future<int> dedupeAttendanceDocs({int batchSize = 200}) async {
    int deleted = 0;

    // We'll page through attendance docs ordered by sectionId then studentId.
    Query query = _firestore.collection('attendance').orderBy('sectionId').orderBy('studentId').limit(batchSize);
    while (true) {
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      // Group docs by day key
      final Map<String, List<QueryDocumentSnapshot>> groups = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final sectionId = data?['sectionId'] as String?;
        final studentId = data?['studentId'] as String?;
        final rawDate = data?['date'];
        DateTime? dt;
        if (rawDate is Timestamp) {
          dt = rawDate.toDate();
        } else if (rawDate is DateTime) {
          dt = rawDate;
        }
        if (sectionId == null || studentId == null || dt == null) {
          continue;
        }

        final dayKey = '${sectionId}_${studentId}_${dt.year.toString().padLeft(4,'0')}${dt.month.toString().padLeft(2,'0')}${dt.day.toString().padLeft(2,'0')}';
        groups.putIfAbsent(dayKey, () => []).add(doc);
      }

      final batch = _firestore.batch();
      for (final entry in groups.entries) {
        final docs = entry.value;
        if (docs.length <= 1) {
          continue;
        }

        // Keep the newest by timestamp (or last write time)
        docs.sort((a, b) {
          final ta = (a.data() as Map<String, dynamic>?)?['timestamp'];
          final tb = (b.data() as Map<String, dynamic>?)?['timestamp'];
          DateTime? da;
          DateTime? db;
          if (ta is Timestamp) {
            da = ta.toDate();
          } else if (ta is DateTime) {
            da = ta;
          }
          if (tb is Timestamp) {
            db = tb.toDate();
          } else if (tb is DateTime) {
            db = tb;
          }
          da ??= DateTime.fromMillisecondsSinceEpoch(0);
          db ??= DateTime.fromMillisecondsSinceEpoch(0);
          return db.compareTo(da); // descending
        });

        // keep docs.first (newest), delete others
        for (var i = 1; i < docs.length; i++) {
          batch.delete(docs[i].reference);
          deleted++;
        }
      }

      if ((batch as dynamic) != null) {
        await batch.commit();
      }

      if (snapshot.docs.length < batchSize) {
        break;
      }
      query = _firestore.collection('attendance').orderBy('sectionId').orderBy('studentId').startAfterDocument(snapshot.docs.last).limit(batchSize);
    }

    return deleted;
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
