import 'package:hive/hive.dart';

part 'reminder.g.dart';

@HiveType(typeId: 1)
class Reminder extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  DateTime scheduledTime;

  @HiveField(4)
  bool isActive;

  @HiveField(5)
  bool isRepeating;

  @HiveField(6)
  String? repeatPattern; // daily, weekly, monthly

  @HiveField(7)
  bool notifyOnMochi;

  @HiveField(8)
  DateTime createdAt;

  @HiveField(9)
  DateTime? completedAt;

  @HiveField(10)
  String priority; // low, medium, high

  @HiveField(11)
  String? emoji;

  Reminder({
    required this.id,
    required this.title,
    this.description,
    required this.scheduledTime,
    this.isActive = true,
    this.isRepeating = false,
    this.repeatPattern,
    this.notifyOnMochi = true,
    required this.createdAt,
    this.completedAt,
    this.priority = 'medium',
    this.emoji,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'isActive': isActive,
      'isRepeating': isRepeating,
      'repeatPattern': repeatPattern,
      'notifyOnMochi': notifyOnMochi,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'priority': priority,
      'emoji': emoji,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      isActive: json['isActive'] ?? true,
      isRepeating: json['isRepeating'] ?? false,
      repeatPattern: json['repeatPattern'],
      notifyOnMochi: json['notifyOnMochi'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : null,
      priority: json['priority'] ?? 'medium',
      emoji: json['emoji'],
    );
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? scheduledTime,
    bool? isActive,
    bool? isRepeating,
    String? repeatPattern,
    bool? notifyOnMochi,
    DateTime? createdAt,
    DateTime? completedAt,
    String? priority,
    String? emoji,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      isActive: isActive ?? this.isActive,
      isRepeating: isRepeating ?? this.isRepeating,
      repeatPattern: repeatPattern ?? this.repeatPattern,
      notifyOnMochi: notifyOnMochi ?? this.notifyOnMochi,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      priority: priority ?? this.priority,
      emoji: emoji ?? this.emoji,
    );
  }
}