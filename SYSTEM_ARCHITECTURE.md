# EDUSCAN - System Architecture Flowchart

## Main Data Flow

```
┌─────────────────────────────────────────────────────────────────────────┐
│                     EDUSCAN SYSTEM ARCHITECTURE FLOW                     │
└─────────────────────────────────────────────────────────────────────────┘


                    ┌──────────────────────┐
                    │  USER ACTIVITY       │
                    │  / QUERIES           │
                    │  (Teachers &         │
                    │   Students)          │
                    └─────────┬────────────┘
                              │
                              ▼
                    ┌──────────────────────┐
                    │  QUERY ANALYSIS      │
                    │  & PROCESSING        │
                    │  • QR Scanning       │
                    │  • Search & Filter   │
                    │  • Attendance Track  │
                    │  • Analytics         │
                    │  • Announcements     │
                    └─────────┬────────────┘
                              │
                              ▼
                    ┌──────────────────────┐
                    │     FIRESTORE        │
                    │     DATABASE         │
                    │  (Cloud-based)       │
                    │  • Real-time Sync    │
                    │  • Data Persistence  │
                    └─────────┬────────────┘
                              │
                    ┌─────────┴──────────┐
                    ▼                    ▼
        ┌──────────────────────┐  ┌──────────────────┐
        │   RETRIEVED DATA     │  │ AUTHENTICATION   │
        │   Collections:       │  │   (Firebase      │
        │  • Attendance        │  │    Auth)         │
        │  • Announcements     │  │                  │
        │  • Sections          │  │  User Roles:     │
        │  • Users             │  │  • Teacher       │
        │  • Subjects          │  │  • Student       │
        └─────────┬────────────┘  └──────────────────┘
                  │
                  ▼
        ┌──────────────────────┐
        │   STATE MANAGEMENT   │
        │   (Provider Pattern)  │
        │  • AuthProvider      │
        │  • FirestoreProvider │
        │  • SectionProvider   │
        └─────────┬────────────┘
                  │
                  ▼
        ┌──────────────────────┐
        │   FLUTTER APP        │
        │   (Presentation)     │
        │  • Responsive UI     │
        │  • Real-time Updates │
        │  • Material Design 3 │
        └─────────┬────────────┘
                  │
        ┌─────────┴──────────────┐
        ▼                        ▼
   ┌──────────────┐         ┌──────────────┐
   │   TEACHER    │         │   STUDENT    │
   │  DASHBOARD   │         │  DASHBOARD   │
   │              │         │              │
   │ • Section    │         │ • My         │
   │   Management │         │   Sections   │
   │ • Mark       │         │ • View       │
   │   Attendance │         │   Attendance │
   │ • Create     │         │ • View       │
   │   Announce   │         │   Announcements│
   │ • Analytics  │         │ • Join via QR│
   └──────────────┘         └──────────────┘
```

---

## Detailed Component Breakdown

### 1. **USER ACTIVITY / QUERIES**
- Teachers: Create sections, mark attendance, post announcements, view analytics
- Students: Join sections via QR code, view attendance, check announcements, see reports

### 2. **QUERY ANALYSIS & PROCESSING**
This layer handles all business logic:
- **QR Code Scanning**: Parse QR codes, extract section/user info
- **Search & Filter**: Real-time section/student search with case-insensitive matching
- **Attendance Tracking**: Mark attendance with deduplication logic
- **Analytics**: Calculate attendance percentages, generate reports
- **Announcements**: Create, delete (48-hour auto-cleanup), display

### 3. **FIRESTORE DATABASE**
Cloud-based NoSQL database with collections:
- **Users**: `uid, name, email, role (teacher/student), profilePicture`
- **Sections**: `sectionId, name, teacherId, joinCode, subjects, schedule, createdAt`
- **Attendance**: `attendanceId, studentId, sectionId, date, status, timestamp`
- **Announcements**: `announcementId, sectionId, teacherId, title, content, createdAt`
- **Section_Members**: `sectionId, studentId, joinedAt, role`

### 4. **RETRIEVED DATA**
Data fetched from Firestore collections:
- Attendance records with status (Present/Absent)
- Announcements with timestamps
- Section details (name, teacher, students, schedule)
- User profiles and authentication info

### 5. **AUTHENTICATION**
Firebase Authentication:
- Email/Password login
- User role-based routing (Teacher vs Student)
- Persistent session management
- Logout functionality

### 6. **STATE MANAGEMENT**
Provider pattern for reactive updates:
- **AuthProvider**: Manages authentication state, user info, login/logout
- **FirestoreProvider**: Handles all Firestore CRUD operations, real-time listeners
- **SectionProvider**: Manages section-specific data, filtering, searching

### 7. **FLUTTER APP (UI LAYER)**
- Responsive design with breakpoint at 600px width
- Material Design 3 components
- Real-time UI updates via Provider listeners
- Bottom navigation for role-based routing

### 8. **TEACHER DASHBOARD**
- Create and manage sections
- Mark student attendance via QR scanner
- Post announcements (auto-delete after 48 hours)
- View attendance analytics (7-day bar chart)
- Manage section members

### 9. **STUDENT DASHBOARD**
- View enrolled sections
- Search sections by name or teacher
- Check attendance status per section
- View recent announcements
- Join sections via QR code
- View attendance reports

---

## Data Flow Examples

### **Attendance Marking Flow**
```
1. Teacher scans QR code
   ↓
2. App extracts: sectionId, studentId
   ↓
3. Business Logic checks:
   - Valid QR code format
   - Student in section
   - Not already marked today (deduplication)
   ↓
4. Call: FirestoreProvider.markAttendance()
   ↓
5. Firestore: Add attendance document
   ↓
6. Real-time listener triggers
   ↓
7. UI updates: Show marked students, green checkmark appears
```

### **Announcement Flow**
```
1. Teacher creates announcement
   ↓
2. FirestoreProvider.addAnnouncement()
   ↓
3. Firestore stores: title, content, createdAt timestamp
   ↓
4. Student receives real-time update
   ↓
5. Dashboard shows recent announcements
   ↓
6. After 48 hours: Automatic cleanup deletes old announcements
   ↓
7. UI reflects deleted items
```

### **Search & Filter Flow**
```
1. Student types in search bar
   ↓
2. TextEditingController listener triggered
   ↓
3. _filterSections() called:
   - Case-insensitive comparison
   - Filter by: section name OR teacher name
   ↓
4. Update _filteredSections list
   ↓
5. UI rebuilds with filtered results
   ↓
6. Clear button appears/disappears based on input
```

### **Responsive Design Flow**
```
1. Widget builds
   ↓
2. Check: MediaQuery.of(context).size.width
   ↓
3. If width < 600px (Small Screen):
   - Padding: 12-16px
   - Font: 11-13px
   - Icons: 16-18px
   ↓
4. If width >= 600px (Large Screen):
   - Padding: 16-24px
   - Font: 12-14px
   - Icons: 18-20px
   ↓
5. Render UI with responsive sizes
```

---

## Key Technologies Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart) |
| **State Management** | Provider |
| **Backend** | Firebase (Firestore + Auth) |
| **Charts** | fl_chart |
| **Typography** | google_fonts |
| **Date Handling** | intl |
| **QR Code** | mobile_scanner |
| **UI Framework** | Material Design 3 |

---

## Design Patterns Used

1. **Provider Pattern**: State management with Provider/Consumer widgets
2. **Repository Pattern**: FirestoreProvider encapsulates data access
3. **Builder Pattern**: Responsive layouts with MediaQuery checks
4. **Observer Pattern**: Real-time Firestore listeners
5. **Singleton Pattern**: Firebase instances (single app instance)

---

## Security & Best Practices

- **Firebase Rules**: Role-based access control (teachers can only modify their sections)
- **Authentication**: Only authenticated users can access data
- **Deduplication**: Prevents duplicate attendance records
- **Auto-cleanup**: 48-hour announcement cleanup prevents data bloat
- **Error Handling**: Try-catch blocks with user-friendly error messages
- **Offline Support**: Firestore offline persistence enabled (optional)

---

## Performance Considerations

- **Real-time Listeners**: Firestore listeners update UI instantly
- **Lazy Loading**: Load data on-demand, not all at once
- **Pagination**: Large datasets paginated for better performance
- **Responsive Design**: Optimized layouts for different screen sizes
- **Image Caching**: Profile pictures cached locally

