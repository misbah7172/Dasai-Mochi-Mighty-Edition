// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_models.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SongAdapter extends TypeAdapter<Song> {
  @override
  final int typeId = 3;

  @override
  Song read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Song(
      id: fields[0] as String,
      title: fields[1] as String,
      artist: fields[2] as String,
      album: fields[3] as String,
      duration: fields[4] as Duration,
      albumArt: fields[5] as String?,
      filePath: fields[6] as String?,
      url: fields[7] as String?,
      dateAdded: fields[8] as DateTime,
      playCount: fields[9] as int,
      isFavorite: fields[10] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Song obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.artist)
      ..writeByte(3)
      ..write(obj.album)
      ..writeByte(4)
      ..write(obj.duration)
      ..writeByte(5)
      ..write(obj.albumArt)
      ..writeByte(6)
      ..write(obj.filePath)
      ..writeByte(7)
      ..write(obj.url)
      ..writeByte(8)
      ..write(obj.dateAdded)
      ..writeByte(9)
      ..write(obj.playCount)
      ..writeByte(10)
      ..write(obj.isFavorite);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SongAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlaylistAdapter extends TypeAdapter<Playlist> {
  @override
  final int typeId = 4;

  @override
  Playlist read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Playlist(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      songIds: (fields[3] as List).cast<String>(),
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
      coverArt: fields[6] as String?,
      type: fields[7] as PlaylistType,
    );
  }

  @override
  void write(BinaryWriter writer, Playlist obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.songIds)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.coverArt)
      ..writeByte(7)
      ..write(obj.type);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PlaylistTypeAdapter extends TypeAdapter<PlaylistType> {
  @override
  final int typeId = 5;

  @override
  PlaylistType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PlaylistType.custom;
      case 1:
        return PlaylistType.favorites;
      case 2:
        return PlaylistType.recentlyPlayed;
      case 3:
        return PlaylistType.mostPlayed;
      case 4:
        return PlaylistType.smart;
      default:
        return PlaylistType.custom;
    }
  }

  @override
  void write(BinaryWriter writer, PlaylistType obj) {
    switch (obj) {
      case PlaylistType.custom:
        writer.writeByte(0);
        break;
      case PlaylistType.favorites:
        writer.writeByte(1);
        break;
      case PlaylistType.recentlyPlayed:
        writer.writeByte(2);
        break;
      case PlaylistType.mostPlayed:
        writer.writeByte(3);
        break;
      case PlaylistType.smart:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlaylistTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
