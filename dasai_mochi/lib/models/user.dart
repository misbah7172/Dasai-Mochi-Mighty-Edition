import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  String fullName;

  @HiveField(1)
  String nickname;

  @HiveField(2)
  DateTime dateOfBirth;

  @HiveField(3)
  String? profileImage;

  @HiveField(4)
  String preferredLanguage;

  @HiveField(5)
  bool soundEffectsEnabled;

  @HiveField(6)
  bool animationsEnabled;

  @HiveField(7)
  String selectedTheme;

  @HiveField(8)
  String selectedVoice;

  @HiveField(9)
  bool festivalModeEnabled;

  @HiveField(10)
  bool petModeEnabled;

  User({
    required this.fullName,
    required this.nickname,
    required this.dateOfBirth,
    this.profileImage,
    this.preferredLanguage = 'English',
    this.soundEffectsEnabled = true,
    this.animationsEnabled = true,
    this.selectedTheme = 'default',
    this.selectedVoice = 'default',
    this.festivalModeEnabled = false,
    this.petModeEnabled = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'nickname': nickname,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'profileImage': profileImage,
      'preferredLanguage': preferredLanguage,
      'soundEffectsEnabled': soundEffectsEnabled,
      'animationsEnabled': animationsEnabled,
      'selectedTheme': selectedTheme,
      'selectedVoice': selectedVoice,
      'festivalModeEnabled': festivalModeEnabled,
      'petModeEnabled': petModeEnabled,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      fullName: json['fullName'],
      nickname: json['nickname'],
      dateOfBirth: DateTime.parse(json['dateOfBirth']),
      profileImage: json['profileImage'],
      preferredLanguage: json['preferredLanguage'] ?? 'English',
      soundEffectsEnabled: json['soundEffectsEnabled'] ?? true,
      animationsEnabled: json['animationsEnabled'] ?? true,
      selectedTheme: json['selectedTheme'] ?? 'default',
      selectedVoice: json['selectedVoice'] ?? 'default',
      festivalModeEnabled: json['festivalModeEnabled'] ?? false,
      petModeEnabled: json['petModeEnabled'] ?? false,
    );
  }
}