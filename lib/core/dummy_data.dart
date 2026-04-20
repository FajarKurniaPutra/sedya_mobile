import '../models/models.dart';

class DummyData {
  // --- USERS ---
  static final AppUser userLeader = AppUser(
    id: 'u1',
    name: 'Klein Moretti',
    username: 'The Fool',
    email: 'foolishgod@gmail.com',
    role: 'Pemimpin Proyek',
  );

  static final AppUser userAssistant = AppUser(
    id: 'u2',
    name: 'Gerhman Sparrow',
    username: 'The World',
    email: 'worldpuppet@gmail.com',
    role: 'Asisten',
  );

  static final AppUser userHR = AppUser(
    id: 'u3',
    name: 'Audrey Hall',
    username: 'The Justice',
    email: 'justiceInvestor@gmail.com',
    role: 'Human Resource',
  );

  static final AppUser userMember1 = AppUser(
    id: 'u4',
    name: 'Alger Wilson',
    username: 'The Hangedman',
    email: 'singingSailor@gmail.com',
    role: 'Anggota',
  );

  static final AppUser userMember2 = AppUser(
    id: 'u5',
    name: 'Trissy Cheek',
    username: 'The Empress',
    email: 'demonessTrick@gmail.com',
    role: 'Anggota',
  );

  static final List<AppUser> allUsers = [
    userLeader,
    userAssistant,
    userHR,
    userMember1,
    userMember2,
  ];

  static AppUser currentUser = userLeader; // Default login for now

  // --- PROJECTS ---
  static final List<Project> projects = [
    Project(
      id: 'p1',
      name: 'Tarot Club App',
      code: 'SDY-2024',
      description: 'Platform untuk pertemuan anggota The Fool.',
      status: 'Active',
      phase: 'Planning',
      creator: userLeader,
    ),
    Project(
      id: 'p2',
      name: 'Tingen City Defense',
      code: 'SDY-2025',
      description: 'Sistem pertahanan keamanan dari entitas luar.',
      status: 'Active',
      phase: 'Execution',
      creator: userLeader,
    ),
  ];

  // --- TASKS ---
  static final List<TaskItem> tasks = [
    TaskItem(
      id: 't1',
      projectId: 'p1',
      name: 'Desain UI/UX Tampilan',
      code: 'TSK-001',
      description: 'Membuat desain tampilan minimalis dan fungsional.',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      deadline: DateTime.now().add(const Duration(days: 5)),
      weight: 5,
      label: 'Design',
      status: 'In Progress',
      pic: userMember1,
    ),
    TaskItem(
      id: 't2',
      projectId: 'p1',
      name: 'Siapkan Backend API',
      code: 'TSK-002',
      description: 'Setup database dan endpoint untuk auth.',
      startDate: DateTime.now(),
      deadline: DateTime.now().add(const Duration(days: 7)),
      weight: 8,
      label: 'Backend',
      status: 'Not Started',
      pic: userMember2,
    ),
    TaskItem(
      id: 't3',
      projectId: 'p1',
      name: 'Riset Kompetitor',
      code: 'TSK-003',
      description: 'Cari tahu aplikasi sejenis.',
      startDate: DateTime.now().subtract(const Duration(days: 5)),
      deadline: DateTime.now().subtract(const Duration(days: 1)),
      weight: 3,
      label: 'Research',
      status: 'Done',
      pic: userAssistant,
    ),
  ];

  // --- CHATS ---
  static final List<ChatMessage> chats = [
    ChatMessage(
      id: 'c1',
      taskId: 't1',
      sender: userLeader,
      message: 'Tolong percepat desainnya, kita butuh secepatnya.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChatMessage(
      id: 'c2',
      taskId: 't1',
      sender: userMember1,
      message: 'Baik, akan saya selesaikan besok pagi.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];
}
