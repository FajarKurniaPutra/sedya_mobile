/// Model User — mapping ke tabel `users` di backend Laravel
class AppUser {
  final int id;
  final String name;
  final String username;
  final String email;
  final String? photoUrl;
  final String? googleId;
  final bool status;

  /// Role di konteks proyek tertentu (diisi saat fetch member)
  String role;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    this.photoUrl,
    this.googleId,
    this.status = true,
    this.role = 'Anggota',
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _toInt(json['id']),
      name: json['username'] ?? json['name'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      photoUrl: json['photo_url'],
      googleId: json['google_id'],
      status: json['status'] == true || json['status'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'photo_url': photoUrl,
    'google_id': googleId,
  };
}

/// Model Project — mapping ke tabel `projects` di backend
class Project {
  final int id;
  final String name;       // nama_projek
  final String code;       // kode_projek
  final String description; // deskripsi
  final bool statusActive; // status_projek (boolean)
  final String phase;      // tahapan_projek
  final String? referralCode; // kode_referral
  final DateTime? startDate;  // tgl_mulai
  final DateTime? endDate;    // estimasi_selesai
  AppUser? creator;
  List<ProjectMember> members;

  Project({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.statusActive,
    required this.phase,
    this.referralCode,
    this.startDate,
    this.endDate,
    this.creator,
    this.members = const [],
  });

  String get status => statusActive ? 'Active' : 'Inactive';

  factory Project.fromJson(Map<String, dynamic> json) {
    List<ProjectMember> members = [];
    if (json['members'] != null) {
      members = (json['members'] as List).map((m) => ProjectMember.fromJson(m)).toList();
    }

    // Cari creator (Pemimpin Projek) dari members
    AppUser? creator;
    for (final m in members) {
      if (m.roleName == 'Pemimpin Projek') {
        creator = m.user;
        break;
      }
    }

    return Project(
      id: _toInt(json['id']),
      name: json['nama_projek'] ?? '',
      code: json['kode_projek'] ?? '',
      description: json['deskripsi'] ?? '',
      statusActive: json['status_projek'] == true || json['status_projek'] == 1,
      phase: json['tahapan_projek'] ?? 'Perencanaan',
      referralCode: json['kode_referral'],
      startDate: _parseDate(json['tgl_mulai']),
      endDate: _parseDate(json['estimasi_selesai']),
      creator: creator,
      members: members,
    );
  }

  Map<String, dynamic> toJsonForCreate() => {
    'nama_projek': name,
    'kode_projek': code,
    'deskripsi': description,
    'tahapan_projek': phase,
    'tgl_mulai': startDate?.toIso8601String().split('T')[0],
    'estimasi_selesai': endDate?.toIso8601String().split('T')[0],
  };
}

/// Model ProjectMember — mapping ke tabel `project_members`
class ProjectMember {
  final int? id;
  final int projectId;
  final int userId;
  final int roleId;
  final String roleName;
  final bool statusMember;
  final AppUser? user;

  ProjectMember({
    this.id,
    required this.projectId,
    required this.userId,
    required this.roleId,
    required this.roleName,
    required this.statusMember,
    this.user,
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    AppUser? user;
    if (json['user'] != null) {
      user = AppUser.fromJson(json['user']);
    }

    String roleName = 'Anggota';
    if (json['role'] != null) {
      roleName = json['role']['nama_role'] ?? 'Anggota';
    }

    // Set role pada user object
    if (user != null) {
      user.role = roleName;
    }

    return ProjectMember(
      id: json['id'] != null ? _toInt(json['id']) : null,
      projectId: _toInt(json['project_id']),
      userId: _toInt(json['user_id']),
      roleId: _toInt(json['role_id']),
      roleName: roleName,
      statusMember: json['status_member'] == true || json['status_member'] == 1,
      user: user,
    );
  }
}

/// Model Task — mapping ke tabel `tasks` di backend
class TaskItem {
  final int id;
  final int projectId;
  final String name;       // nama_task
  final String? description;
  final DateTime? startDate;  // tgl_mulai
  final DateTime? deadline;
  final int weight;         // bobot
  final String? label;
  final String status;      // status_task: TODO, IN_PROGRESS, REVIEW, DONE
  final String? priority;   // prioritas: Rendah, Sedang, Tinggi
  final AppUser? pic;       // assigned_to (primary PIC)
  final List<AppUser> picUsers; // multi-PIC
  final List<NoteItem> notes;
  final List<TaskImage> images;
  final DateTime? completedAt;
  final Project? project;

  TaskItem({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    this.startDate,
    this.deadline,
    this.weight = 1,
    this.label,
    required this.status,
    this.priority,
    this.pic,
    this.picUsers = const [],
    this.notes = const [],
    this.images = const [],
    this.completedAt,
    this.project,
  });

  /// Mapping status backend → FE display
  String get displayStatus {
    switch (status) {
      case 'TODO': return 'Not Started';
      case 'IN_PROGRESS': return 'In Progress';
      case 'REVIEW': return 'Review';
      case 'DONE': return 'Done';
      default: return status;
    }
  }

  /// Mapping status FE display → backend value
  static String toBackendStatus(String displayStatus) {
    switch (displayStatus) {
      case 'Not Started': return 'TODO';
      case 'In Progress': return 'IN_PROGRESS';
      case 'Review': return 'REVIEW';
      case 'Done': return 'DONE';
      default: return displayStatus;
    }
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    // Parse PIC users
    List<AppUser> picUsers = [];
    if (json['pic_users'] != null) {
      picUsers = (json['pic_users'] as List).map((u) => AppUser.fromJson(u)).toList();
    }

    // Parse notes
    List<NoteItem> notes = [];
    if (json['notes'] != null) {
      notes = (json['notes'] as List).map((n) => NoteItem.fromJson(n)).toList();
    }

    // Parse images
    List<TaskImage> images = [];
    if (json['images'] != null) {
      images = (json['images'] as List).map((i) => TaskImage.fromJson(i)).toList();
    }

    // Parse assignee
    AppUser? pic;
    if (json['assignee'] != null) {
      pic = AppUser.fromJson(json['assignee']);
    } else if (picUsers.isNotEmpty) {
      pic = picUsers.first;
    }

    // Parse project
    Project? project;
    if (json['project'] != null) {
      project = Project.fromJson(json['project']);
    }

    return TaskItem(
      id: _toInt(json['id']),
      projectId: _toInt(json['project_id']),
      name: json['nama_task'] ?? '',
      description: json['detail_task'] ?? json['description'],
      startDate: _parseDate(json['tgl_mulai']),
      deadline: _parseDate(json['deadline']),
      weight: json['bobot'] ?? 1,
      label: json['label'],
      status: json['status_task'] ?? 'TODO',
      priority: json['prioritas'],
      pic: pic,
      picUsers: picUsers,
      notes: notes,
      images: images,
      completedAt: _parseDateTime(json['completed_at']),
      project: project,
    );
  }

  Map<String, dynamic> toJsonForCreate() => {
    'project_id': projectId,
    'nama_task': name,
    'deadline': deadline?.toIso8601String().split('T')[0],
    'bobot': weight,
    'label': label,
    'prioritas': priority ?? 'Sedang',
    'pic_ids': picUsers.map((u) => u.id).toList(),
  };

  Map<String, dynamic> toJsonForUpdate() => {
    'nama_task': name,
    'deadline': deadline?.toIso8601String().split('T')[0],
    'bobot': weight,
    'label': label,
    'prioritas': priority ?? 'Sedang',
    'pic_ids': picUsers.map((u) => u.id).toList(),
  };
}

/// Model Note/Catatan — mapping ke tabel `notes`
class NoteItem {
  final int id;
  final int taskId;
  final int userId;
  final String message;       // isi_catatan
  final String? attachmentPath;
  final DateTime? createdAt;
  final AppUser? sender;

  NoteItem({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.message,
    this.attachmentPath,
    this.createdAt,
    this.sender,
  });

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: _toInt(json['id']),
      taskId: _toInt(json['task_id']),
      userId: _toInt(json['user_id']),
      message: json['isi_catatan'] ?? '',
      attachmentPath: json['attachment_path'],
      createdAt: _parseDateTime(json['created_at']),
      sender: json['user'] != null ? AppUser.fromJson(json['user']) : null,
    );
  }
}

/// Model TaskImage — mapping ke tabel `task_images`
class TaskImage {
  final int id;
  final int taskId;
  final String imagePath;
  final String? originalName;

  TaskImage({
    required this.id,
    required this.taskId,
    required this.imagePath,
    this.originalName,
  });

  factory TaskImage.fromJson(Map<String, dynamic> json) {
    return TaskImage(
      id: _toInt(json['id']),
      taskId: _toInt(json['task_id']),
      imagePath: json['image_path'] ?? '',
      originalName: json['original_name'],
    );
  }
}

/// Model Sprint — mapping ke tabel `sprints`
class Sprint {
  final int id;
  final int projectId;
  final String? name;        // nama_sprint
  final DateTime startDate;
  final DateTime endDate;
  final List<SprintGoal> goals;
  final List<WeeklyPlan> weeklyPlans;

  Sprint({
    required this.id,
    required this.projectId,
    this.name,
    required this.startDate,
    required this.endDate,
    this.goals = const [],
    this.weeklyPlans = const [],
  });

  factory Sprint.fromJson(Map<String, dynamic> json) {
    List<SprintGoal> goals = [];
    if (json['goals'] != null) {
      goals = (json['goals'] as List).map((g) => SprintGoal.fromJson(g)).toList();
    }
    List<WeeklyPlan> weeklyPlans = [];
    if (json['weekly_plans'] != null) {
      weeklyPlans = (json['weekly_plans'] as List).map((wp) => WeeklyPlan.fromJson(wp)).toList();
    }
    return Sprint(
      id: _toInt(json['id']),
      projectId: _toInt(json['project_id']),
      name: json['nama_sprint'],
      startDate: _parseDate(json['start_date']) ?? DateTime.now(),
      endDate: _parseDate(json['end_date']) ?? DateTime.now(),
      goals: goals,
      weeklyPlans: weeklyPlans,
    );
  }
}

/// Model WeeklyPlan — mapping ke tabel `weekly_plans`
class WeeklyPlan {
  final int id;
  final int sprintId;
  final List<String> planningPoin;

  WeeklyPlan({required this.id, required this.sprintId, this.planningPoin = const []});

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    List<String> points = [];
    if (json['planning_poin'] != null) {
      if (json['planning_poin'] is List) {
        points = (json['planning_poin'] as List).map((e) => e.toString()).toList();
      } else if (json['planning_poin'] is String) {
        // Just in case it's stringified JSON
        // Actually, let's keep it simple
      }
    }
    return WeeklyPlan(
      id: _toInt(json['id']),
      sprintId: _toInt(json['sprint_id']),
      planningPoin: points,
    );
  }
}

/// Model SprintGoal — mapping ke tabel `sprint_goals`
class SprintGoal {
  final int id;
  final int sprintId;
  final String text; // goal_text

  SprintGoal({required this.id, required this.sprintId, required this.text});

  factory SprintGoal.fromJson(Map<String, dynamic> json) {
    return SprintGoal(
      id: _toInt(json['id']),
      sprintId: _toInt(json['sprint_id']),
      text: json['goal_text'] ?? '',
    );
  }
}

/// Model Notification — mapping ke tabel `notifications`
class AppNotification {
  final int id;
  final int userId;
  final String message;  // pesan
  final bool isRead;
  final String? referenceType;
  final int? referenceId;
  final DateTime? createdAt;

  AppNotification({
    required this.id,
    required this.userId,
    required this.message,
    this.isRead = false,
    this.referenceType,
    this.referenceId,
    this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _toInt(json['id']),
      userId: _toInt(json['user_id']),
      message: json['pesan'] ?? '',
      isRead: json['is_read'] == true || json['is_read'] == 1,
      referenceType: json['reference_type'],
      referenceId: json['reference_id'] != null ? _toInt(json['reference_id']) : null,
      createdAt: _parseDateTime(json['created_at']),
    );
  }
}

/// Model HR Team Performance — mapping ke response `/hr/team-performance`
class HRMemberPerformance {
  final int userId;
  final String username;
  final String? photoUrl;
  final String role;
  final int totalTasks;
  final int done;
  final int delayed;
  final double avgHours;
  final int score;
  final String badge;

  HRMemberPerformance({
    required this.userId,
    required this.username,
    this.photoUrl,
    required this.role,
    required this.totalTasks,
    required this.done,
    required this.delayed,
    required this.avgHours,
    required this.score,
    required this.badge,
  });

  factory HRMemberPerformance.fromJson(Map<String, dynamic> json) {
    return HRMemberPerformance(
      userId: _toInt(json['user_id']),
      username: json['username'] ?? '',
      photoUrl: json['photo_url'],
      role: json['role'] ?? 'Anggota',
      totalTasks: json['total_tasks'] ?? 0,
      done: json['done'] ?? 0,
      delayed: json['delayed'] ?? 0,
      avgHours: (json['avg_hours'] ?? 0).toDouble(),
      score: json['score'] ?? 0,
      badge: json['badge'] ?? 'Kritis',
    );
  }
}

// ===== HELPER FUNCTIONS =====

/// Safe int parsing — backend bisa mengirim int atau String
int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Parse date string (yyyy-MM-dd) ke DateTime
DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}

/// Parse datetime string (ISO 8601) ke DateTime
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}
