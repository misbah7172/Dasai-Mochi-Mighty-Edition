import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/music_service.dart';
import '../models/music_models.dart';
import '../utils/theme.dart';
import '../components/mochi_widgets.dart';

class MusicScreen extends StatefulWidget {
  const MusicScreen({super.key});

  @override
  State<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends State<MusicScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _albumArtController;
  
  int _currentPageIndex = 0;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  
  // Sample music data
  final List<Song> _sampleSongs = [
    Song(
      id: '1',
      title: 'Mochi\'s Sweet Dreams',
      artist: 'Kawaii Sounds',
      album: 'Pastel Collection',
      duration: const Duration(minutes: 3, seconds: 45),
      dateAdded: DateTime.now(),
    ),
    Song(
      id: '2',
      title: 'Digital Harmony',
      artist: 'Synth Dreams',
      album: 'Electronic Vibes',
      duration: const Duration(minutes: 4, seconds: 12),
      dateAdded: DateTime.now(),
      isFavorite: true,
    ),
    Song(
      id: '3',
      title: 'Gentle Breeze',
      artist: 'Nature Sounds',
      album: 'Peaceful Moments',
      duration: const Duration(minutes: 2, seconds: 58),
      dateAdded: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _albumArtController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );
    _albumArtController.repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _albumArtController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF0),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPageIndex = index),
              children: [
                _buildNowPlayingPage(),
                _buildMusicLibraryPage(),
                _buildPlaylistsPage(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildMiniPlayer(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Color(0xFF2D3748),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: _isSearching 
          ? _buildSearchField()
          : const Text(
              '🎵 Music Player',
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
      actions: [
        IconButton(
          icon: Icon(
            _isSearching ? Icons.close : Icons.search,
            color: MochiTheme.pastelColors['blue']!,
          ),
          onPressed: () {
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
              }
            });
          },
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      style: const TextStyle(color: Color(0xFF2D3748)),
      decoration: const InputDecoration(
        hintText: 'Search music...',
        hintStyle: TextStyle(color: Color(0xFF718096)),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildTabIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem('Now Playing', 0, Icons.music_note),
          _buildTabItem('Library', 1, Icons.library_music),
          _buildTabItem('Playlists', 2, Icons.playlist_play),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index, IconData icon) {
    final isSelected = _currentPageIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? MochiTheme.pastelColors['blue']!.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected 
                    ? MochiTheme.pastelColors['blue']!
                    : const Color(0xFF718096),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected 
                      ? MochiTheme.pastelColors['blue']!
                      : const Color(0xFF718096),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNowPlayingPage() {
    return Consumer<MusicService>(
      builder: (context, musicService, child) {
        final currentSong = musicService.currentSong;
        
        if (currentSong == null) {
          return _buildNoMusicPlaying();
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAlbumArt(currentSong),
              const SizedBox(height: 30),
              _buildSongInfo(currentSong),
              const SizedBox(height: 30),
              _buildProgressBar(musicService),
              const SizedBox(height: 30),
              _buildPlaybackControls(musicService),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoMusicPlaying() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: MochiTheme.pastelColors['lavender']!.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_off,
              size: 80,
              color: MochiTheme.pastelColors['lavender'],
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(duration: 2.seconds),
          const SizedBox(height: 30),
          const Text(
            'No music playing',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Choose a song from your library to start playing',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          MochiButton(
            text: 'Browse Music',
            onPressed: () {
              _pageController.animateToPage(
                1,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(Song song) {
    return Container(
      width: 250,
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MochiTheme.pastelColors['blue']!.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: _buildDefaultAlbumArt(),
      ),
    )
        .animate(onPlay: (controller) => controller.repeat())
        .rotate(duration: 20.seconds);
  }

  Widget _buildDefaultAlbumArt() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MochiTheme.pastelColors['softPink']!,
            MochiTheme.pastelColors['lavender']!,
            MochiTheme.pastelColors['mintGreen']!,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.music_note,
          size: 80,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSongInfo(Song song) {
    return Column(
      children: [
        Text(
          song.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
          textAlign: TextAlign.center,
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .slide(begin: const Offset(0, 0.2)),
        const SizedBox(height: 8),
        Text(
          song.artist,
          style: const TextStyle(
            fontSize: 18,
            color: Color(0xFF718096),
          ),
          textAlign: TextAlign.center,
        )
            .animate(delay: 200.ms)
            .fadeIn(duration: 500.ms)
            .slide(begin: const Offset(0, 0.2)),
        const SizedBox(height: 4),
        Text(
          song.album,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9CA3AF),
          ),
          textAlign: TextAlign.center,
        )
            .animate(delay: 400.ms)
            .fadeIn(duration: 500.ms)
            .slide(begin: const Offset(0, 0.2)),
      ],
    );
  }

  Widget _buildProgressBar(MusicService musicService) {
    return Column(
      children: [
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: const Color(0xFFE5E7EB),
          ),
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: const Color(0xFFE5E7EB),
                ),
              ),
              FractionallySizedBox(
                widthFactor: musicService.progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      colors: [
                        MochiTheme.pastelColors['blue']!,
                        MochiTheme.pastelColors['softPink']!,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(musicService.position),
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
            Text(
              _formatDuration(musicService.duration),
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaybackControls(MusicService musicService) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.shuffle,
          isActive: musicService.state.isShuffleEnabled,
          onPressed: () => musicService.toggleShuffle(),
          size: 30,
        ),
        _buildControlButton(
          icon: Icons.skip_previous,
          onPressed: () => musicService.playPrevious(),
          size: 40,
        ),
        _buildPlayPauseButton(musicService),
        _buildControlButton(
          icon: Icons.skip_next,
          onPressed: () => musicService.playNext(),
          size: 40,
        ),
        _buildControlButton(
          icon: _getRepeatIcon(musicService.state.repeatMode),
          isActive: musicService.state.repeatMode != RepeatMode.off,
          onPressed: () => musicService.toggleRepeat(),
          size: 30,
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton(MusicService musicService) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            MochiTheme.pastelColors['blue']!,
            MochiTheme.pastelColors['softPink']!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: MochiTheme.pastelColors['blue']!.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          musicService.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 35,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          if (musicService.isPlaying) {
            musicService.pause();
          } else {
            musicService.resume();
          }
        },
      ),
    )
        .animate(target: musicService.isPlaying ? 1 : 0)
        .scale(duration: 200.ms);
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isActive = false,
    double size = 30,
  }) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive 
            ? MochiTheme.pastelColors['blue']!.withOpacity(0.2)
            : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: isActive 
              ? MochiTheme.pastelColors['blue']!
              : const Color(0xFF2D3748),
          size: size,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
      ),
    );
  }

  Widget _buildMusicLibraryPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Music Library',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _sampleSongs.length,
              itemBuilder: (context, index) {
                return _buildSongTile(_sampleSongs[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(Song song, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              colors: [
                MochiTheme.pastelColors['softPink']!,
                MochiTheme.pastelColors['lavender']!,
              ],
            ),
          ),
          child: const Icon(
            Icons.music_note,
            color: Colors.white,
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        subtitle: Text(
          '${song.artist} • ${song.durationString}',
          style: const TextStyle(
            color: Color(0xFF718096),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (song.isFavorite)
              Icon(
                Icons.favorite,
                color: MochiTheme.pastelColors['softPink'],
                size: 20,
              ),
            const SizedBox(width: 10),
            const Icon(
              Icons.more_vert,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
        onTap: () {
          final musicService = Provider.of<MusicService>(context, listen: false);
          musicService.playSong(song, queue: _sampleSongs, index: index);
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 500.ms)
        .slide(begin: const Offset(0.2, 0));
  }

  Widget _buildPlaylistsPage() {
    return const Center(
      child: Text(
        'Playlists coming soon! 🎵',
        style: TextStyle(
          fontSize: 18,
          color: Color(0xFF718096),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer() {
    return Consumer<MusicService>(
      builder: (context, musicService, child) {
        final currentSong = musicService.currentSong;
        
        if (currentSong == null) return const SizedBox.shrink();
        
        return Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        MochiTheme.pastelColors['softPink']!,
                        MochiTheme.pastelColors['lavender']!,
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentSong.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        currentSong.artist,
                        style: const TextStyle(
                          color: Color(0xFF718096),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    musicService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: MochiTheme.pastelColors['blue'],
                  ),
                  onPressed: () {
                    if (musicService.isPlaying) {
                      musicService.pause();
                    } else {
                      musicService.resume();
                    }
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.skip_next,
                    color: MochiTheme.pastelColors['blue'],
                  ),
                  onPressed: () => musicService.playNext(),
                ),
              ],
            ),
          ),
        )
            .animate()
            .slideY(begin: 1, duration: 500.ms, curve: Curves.easeOut);
      },
    );
  }

  IconData _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return Icons.repeat;
      case RepeatMode.all:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
