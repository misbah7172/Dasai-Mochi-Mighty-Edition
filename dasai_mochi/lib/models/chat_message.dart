import 'package:hive/hive.dart';

part 'chat_message.g.dart';

@HiveType(typeId: 2)
class ChatMessage extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String message;

  @HiveField(2)
  bool isFromUser;

  @HiveField(3)
  DateTime timestamp;

  @HiveField(4)
  String? mood; // happy, sleepy, sad, crazy

  @HiveField(5)
  String? emotion; // for AI responses

  @HiveField(6)
  bool isVoiceMessage;

  @HiveField(7)
  String? audioFilePath;

  ChatMessage({
    required this.id,
    required this.message,
    required this.isFromUser,
    required this.timestamp,
    this.mood,
    this.emotion,
    this.isVoiceMessage = false,
    this.audioFilePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'isFromUser': isFromUser,
      'timestamp': timestamp.toIso8601String(),
      'mood': mood,
      'emotion': emotion,
      'isVoiceMessage': isVoiceMessage,
      'audioFilePath': audioFilePath,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      message: json['message'],
      isFromUser: json['isFromUser'],
      timestamp: DateTime.parse(json['timestamp']),
      mood: json['mood'],
      emotion: json['emotion'],
      isVoiceMessage: json['isVoiceMessage'] ?? false,
      audioFilePath: json['audioFilePath'],
    );
  }
}