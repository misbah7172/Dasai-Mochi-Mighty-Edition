import 'package:hive/hive.dart';

part 'music_models.g.dart';

/// Song model for music player
@HiveType(typeId: 3)
class Song {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String artist;
  
  @HiveField(3)
  final String album;
  
  @HiveField(4)
  final Duration duration;
  
  @HiveField(5)
  final String? albumArt;
  
  @HiveField(6)
  final String? filePath;
  
  @HiveField(7)
  final String? url;
  
  @HiveField(8)
  final DateTime dateAdded;
  
  @HiveField(9)
  final int playCount;
  
  @HiveField(10)
  final bool isFavorite;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.albumArt,
    this.filePath,
    this.url,
    required this.dateAdded,
    this.playCount = 0,
    this.isFavorite = false,
  });

  Song copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? albumArt,
    String? filePath,
    String? url,
    DateTime? dateAdded,
    int? playCount,
    bool? isFavorite,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      albumArt: albumArt ?? this.albumArt,
      filePath: filePath ?? this.filePath,
      url: url ?? this.url,
      dateAdded: dateAdded ?? this.dateAdded,
      playCount: playCount ?? this.playCount,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  String get durationString {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Playlist model for organizing songs
@HiveType(typeId: 4)
class Playlist {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String description;
  
  @HiveField(3)
  final List<String> songIds;
  
  @HiveField(4)
  final DateTime createdAt;
  
  @HiveField(5)
  final DateTime updatedAt;
  
  @HiveField(6)
  final String? coverArt;
  
  @HiveField(7)
  final PlaylistType type;

  const Playlist({
    required this.id,
    required this.name,
    required this.description,
    required this.songIds,
    required this.createdAt,
    required this.updatedAt,
    this.coverArt,
    this.type = PlaylistType.custom,
  });

  Playlist copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? coverArt,
    PlaylistType? type,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      songIds: songIds ?? this.songIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      coverArt: coverArt ?? this.coverArt,
      type: type ?? this.type,
    );
  }

  Duration get totalDuration {
    // This would need to be calculated with actual song data
    return Duration.zero;
  }

  int get songCount => songIds.length;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Types of playlists
@HiveType(typeId: 5)
enum PlaylistType {
  @HiveField(0)
  custom,
  
  @HiveField(1)
  favorites,
  
  @HiveField(2)
  recentlyPlayed,
  
  @HiveField(3)
  mostPlayed,
  
  @HiveField(4)
  smart,
}

/// Current playback state
enum PlaybackState {
  playing,
  paused,
  stopped,
  loading,
  error,
}

/// Repeat modes for music player
enum RepeatMode {
  off,
  all,
  one,
}

/// Current music player state
class MusicPlayerState {
  final Song? currentSong;
  final Playlist? currentPlaylist;
  final PlaybackState playbackState;
  final Duration position;
  final Duration duration;
  final bool isShuffleEnabled;
  final RepeatMode repeatMode;
  final double volume;
  final List<Song> queue;
  final int currentIndex;

  const MusicPlayerState({
    this.currentSong,
    this.currentPlaylist,
    this.playbackState = PlaybackState.stopped,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isShuffleEnabled = false,
    this.repeatMode = RepeatMode.off,
    this.volume = 1.0,
    this.queue = const [],
    this.currentIndex = 0,
  });

  MusicPlayerState copyWith({
    Song? currentSong,
    Playlist? currentPlaylist,
    PlaybackState? playbackState,
    Duration? position,
    Duration? duration,
    bool? isShuffleEnabled,
    RepeatMode? repeatMode,
    double? volume,
    List<Song>? queue,
    int? currentIndex,
  }) {
    return MusicPlayerState(
      currentSong: currentSong ?? this.currentSong,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      playbackState: playbackState ?? this.playbackState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isShuffleEnabled: isShuffleEnabled ?? this.isShuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
      volume: volume ?? this.volume,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  bool get isPlaying => playbackState == PlaybackState.playing;
  bool get isPaused => playbackState == PlaybackState.paused;
  bool get isStopped => playbackState == PlaybackState.stopped;
  bool get isLoading => playbackState == PlaybackState.loading;
  bool get hasError => playbackState == PlaybackState.error;
  
  double get progress {
    if (duration.inMilliseconds == 0) return 0.0;
    return position.inMilliseconds / duration.inMilliseconds;
  }
  
  bool get hasNext => currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;
}