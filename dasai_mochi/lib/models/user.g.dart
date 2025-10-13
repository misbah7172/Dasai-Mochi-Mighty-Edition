// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0;

  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return User(
      fullName: fields[0] as String,
      nickname: fields[1] as String,
      dateOfBirth: fields[2] as DateTime,
      profileImage: fields[3] as String?,
      preferredLanguage: fields[4] as String,
      soundEffectsEnabled: fields[5] as bool,
      animationsEnabled: fields[6] as bool,
      selectedTheme: fields[7] as String,
      selectedVoice: fields[8] as String,
      festivalModeEnabled: fields[9] as bool,
      petModeEnabled: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.fullName)
      ..writeByte(1)
      ..write(obj.nickname)
      ..writeByte(2)
      ..write(obj.dateOfBirth)
      ..writeByte(3)
      ..write(obj.profileImage)
      ..writeByte(4)
      ..write(obj.preferredLanguage)
      ..writeByte(5)
      ..write(obj.soundEffectsEnabled)
      ..writeByte(6)
      ..write(obj.animationsEnabled)
      ..writeByte(7)
      ..write(obj.selectedTheme)
      ..writeByte(8)
      ..write(obj.selectedVoice)
      ..writeByte(9)
      ..write(obj.festivalModeEnabled)
      ..writeByte(10)
      ..write(obj.petModeEnabled);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
