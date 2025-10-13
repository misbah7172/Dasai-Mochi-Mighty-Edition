import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/music_models.dart';

class MusicService extends ChangeNotifier {
  static final MusicService _instance = MusicService._internal();
  factory MusicService() => _instance;
  MusicService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  
  MusicPlayerState _state = const MusicPlayerState();
  StreamSubscription? _positionSubscription;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _durationSubscription;
  Timer? _progressTimer;
  
  // Getters
  MusicPlayerState get state => _state;
  Song? get currentSong => _state.currentSong;
  bool get isPlaying => _state.isPlaying;
  bool get isPaused => _state.isPaused;
  double get progress => _state.progress;
  Duration get position => _state.position;
  Duration get duration => _state.duration;
  List<Song> get queue => _state.queue;
  
  /// Initialize the music service
  Future<void> initialize() async {
    try {
      await _setupAudioPlayer();
      await _loadSavedState();
      debugPrint("Music Service: Initialized successfully");
    } catch (e) {
      debugPrint("Music Service: Initialization error: $e");
    }
  }
  
  /// Setup audio player listeners
  Future<void> _setupAudioPlayer() async {
    // Position updates
    _positionSubscription = _audioPlayer.onPositionChanged.listen((position) {
      _updateState(_state.copyWith(position: position));
    });
    
    // Player state changes
    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((playerState) {
      PlaybackState newState;
      switch (playerState) {
        case PlayerState.playing:
          newState = PlaybackState.playing;
          break;
        case PlayerState.paused:
          newState = PlaybackState.paused;
          break;
        case PlayerState.stopped:
          newState = PlaybackState.stopped;
          break;
        case PlayerState.completed:
          _onSongCompleted();
          return;
        case PlayerState.disposed:
          newState = PlaybackState.stopped;
          break;
      }
      _updateState(_state.copyWith(playbackState: newState));
    });
    
    // Duration updates
    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      _updateState(_state.copyWith(duration: duration));
    });
  }
  
  /// Load saved music state
  Future<void> _loadSavedState() async {
    // Load last playing song, volume, etc. from storage
    // This would integrate with LocalStorageService
  }
  
  /// Update state and notify listeners
  void _updateState(MusicPlayerState newState) {
    _state = newState;
    notifyListeners();
  }
  
  /// Play a specific song
  Future<void> playSong(Song song, {List<Song>? queue, int? index}) async {
    try {
      _updateState(_state.copyWith(playbackState: PlaybackState.loading));
      
      // Set up queue if provided
      if (queue != null) {
        _updateState(_state.copyWith(
          queue: queue,
          currentIndex: index ?? 0,
        ));
      }
      
      // Stop current playback
      await _audioPlayer.stop();
      
      // Start new song
      if (song.url != null) {
        await _audioPlayer.play(UrlSource(song.url!));
      } else if (song.filePath != null) {
        await _audioPlayer.play(DeviceFileSource(song.filePath!));
      } else {
        throw Exception('No valid audio source for song: ${song.title}');
      }
      
      _updateState(_state.copyWith(
        currentSong: song,
        playbackState: PlaybackState.playing,
        position: Duration.zero,
      ));
      
      // Increment play count
      await _incrementPlayCount(song);
      
      debugPrint("Music Service: Playing ${song.title} by ${song.artist}");
    } catch (e) {
      debugPrint("Music Service: Play error: $e");
      _updateState(_state.copyWith(playbackState: PlaybackState.error));
    }
  }
  
  /// Play from playlist
  Future<void> playPlaylist(Playlist playlist, {int startIndex = 0}) async {
    try {
      final songs = await _getSongsFromPlaylist(playlist);
      if (songs.isNotEmpty && startIndex < songs.length) {
        await playSong(
          songs[startIndex],
          queue: songs,
          index: startIndex,
        );
        _updateState(_state.copyWith(currentPlaylist: playlist));
      }
    } catch (e) {
      debugPrint("Music Service: Play playlist error: $e");
    }
  }
  
  /// Resume playback
  Future<void> resume() async {
    try {
      await _audioPlayer.resume();
      debugPrint("Music Service: Resumed playback");
    } catch (e) {
      debugPrint("Music Service: Resume error: $e");
    }
  }
  
  /// Pause playback
  Future<void> pause() async {
    try {
      await _audioPlayer.pause();
      debugPrint("Music Service: Paused playback");
    } catch (e) {
      debugPrint("Music Service: Pause error: $e");
    }
  }
  
  /// Stop playback
  Future<void> stop() async {
    try {
      await _audioPlayer.stop();
      _updateState(_state.copyWith(
        playbackState: PlaybackState.stopped,
        position: Duration.zero,
      ));
      debugPrint("Music Service: Stopped playback");
    } catch (e) {
      debugPrint("Music Service: Stop error: $e");
    }
  }
  
  /// Seek to position
  Future<void> seek(Duration position) async {
    try {
      await _audioPlayer.seek(position);
      debugPrint("Music Service: Seeked to ${position.inSeconds}s");
    } catch (e) {
      debugPrint("Music Service: Seek error: $e");
    }
  }
  
  /// Play next song
  Future<void> playNext() async {
    if (_state.hasNext) {
      final nextIndex = _state.currentIndex + 1;
      await playSong(
        _state.queue[nextIndex],
        queue: _state.queue,
        index: nextIndex,
      );
    } else if (_state.repeatMode == RepeatMode.all && _state.queue.isNotEmpty) {
      await playSong(
        _state.queue.first,
        queue: _state.queue,
        index: 0,
      );
    }
  }
  
  /// Play previous song
  Future<void> playPrevious() async {
    if (_state.position.inSeconds > 3) {
      // If more than 3 seconds into the song, restart current song
      await seek(Duration.zero);
    } else if (_state.hasPrevious) {
      final prevIndex = _state.currentIndex - 1;
      await playSong(
        _state.queue[prevIndex],
        queue: _state.queue,
        index: prevIndex,
      );
    } else if (_state.repeatMode == RepeatMode.all && _state.queue.isNotEmpty) {
      await playSong(
        _state.queue.last,
        queue: _state.queue,
        index: _state.queue.length - 1,
      );
    }
  }
  
  /// Toggle shuffle mode
  void toggleShuffle() {
    final newShuffle = !_state.isShuffleEnabled;
    _updateState(_state.copyWith(isShuffleEnabled: newShuffle));
    
    if (newShuffle) {
      _shuffleQueue();
    } else {
      // Restore original order
      // This would need to store original queue order
    }
  }
  
  /// Toggle repeat mode
  void toggleRepeat() {
    RepeatMode newMode;
    switch (_state.repeatMode) {
      case RepeatMode.off:
        newMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        newMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        newMode = RepeatMode.off;
        break;
    }
    _updateState(_state.copyWith(repeatMode: newMode));
  }
  
  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    try {
      final clampedVolume = volume.clamp(0.0, 1.0);
      await _audioPlayer.setVolume(clampedVolume);
      _updateState(_state.copyWith(volume: clampedVolume));
    } catch (e) {
      debugPrint("Music Service: Set volume error: $e");
    }
  }
  
  /// Handle song completion
  void _onSongCompleted() {
    if (_state.repeatMode == RepeatMode.one) {
      // Repeat current song
      playSong(_state.currentSong!, queue: _state.queue, index: _state.currentIndex);
    } else {
      // Play next song
      playNext();
    }
  }
  
  /// Shuffle the current queue
  void _shuffleQueue() {
    if (_state.queue.isEmpty) return;
    
    final random = Random();
    final shuffledQueue = List<Song>.from(_state.queue);
    
    // Keep current song at index 0
    if (_state.currentSong != null) {
      shuffledQueue.removeWhere((song) => song.id == _state.currentSong!.id);
      shuffledQueue.shuffle(random);
      shuffledQueue.insert(0, _state.currentSong!);
      
      _updateState(_state.copyWith(
        queue: shuffledQueue,
        currentIndex: 0,
      ));
    } else {
      shuffledQueue.shuffle(random);
      _updateState(_state.copyWith(queue: shuffledQueue));
    }
  }
  
  /// Get songs from playlist
  Future<List<Song>> _getSongsFromPlaylist(Playlist playlist) async {
    // This would integrate with LocalStorageService to get actual songs
    return [];
  }
  
  /// Increment play count for song
  Future<void> _incrementPlayCount(Song song) async {
    // This would update the song's play count in storage
  }
  
  /// Add song to queue
  void addToQueue(Song song) {
    final newQueue = List<Song>.from(_state.queue)..add(song);
    _updateState(_state.copyWith(queue: newQueue));
  }
  
  /// Remove song from queue
  void removeFromQueue(int index) {
    if (index < 0 || index >= _state.queue.length) return;
    
    final newQueue = List<Song>.from(_state.queue)..removeAt(index);
    int newCurrentIndex = _state.currentIndex;
    
    if (index < _state.currentIndex) {
      newCurrentIndex--;
    } else if (index == _state.currentIndex) {
      // Removed current song, stop playback
      stop();
    }
    
    _updateState(_state.copyWith(
      queue: newQueue,
      currentIndex: newCurrentIndex,
    ));
  }
  
  /// Clear the queue
  void clearQueue() {
    stop();
    _updateState(_state.copyWith(
      queue: [],
      currentIndex: 0,
      currentSong: null,
      currentPlaylist: null,
    ));
  }
  
  /// Dispose of resources
  @override
  void dispose() {
    _positionSubscription?.cancel();
    _stateSubscription?.cancel();
    _durationSubscription?.cancel();
    _progressTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}