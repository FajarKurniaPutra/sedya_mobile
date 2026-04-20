class AppUser {
  final String id;
  final String name;
  final String username;
  final String email;
  final String role;

  AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.role,
  });
}

class Project {
  final String id;
  final String name;
  final String code;
  final String description;
  final String status; // Active, Inactive
  final String phase; // Planning, Execution, etc.
  final AppUser creator;

  Project({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.status,
    required this.phase,
    required this.creator,
  });
}

class TaskItem {
  final String id;
  final String projectId;
  final String name;
  final String code;
  final String description;
  final DateTime startDate;
  final DateTime deadline;
  final int weight;
  final String label;
  final String status; // Not Started, In Progress, Review, Done
  final AppUser pic;

  TaskItem({
    required this.id,
    required this.projectId,
    required this.name,
    required this.code,
    required this.description,
    required this.startDate,
    required this.deadline,
    required this.weight,
    required this.label,
    required this.status,
    required this.pic,
  });
}

class ChatMessage {
  final String id;
  final String taskId;
  final AppUser sender;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.taskId,
    required this.sender,
    required this.message,
    required this.timestamp,
  });
}
