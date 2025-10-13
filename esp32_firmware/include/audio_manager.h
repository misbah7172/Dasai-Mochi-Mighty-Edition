#pragma once

#include <Arduino.h>
#include <AudioFileSourceLittleFS.h>
#include <AudioGeneratorWAV.h>
#include <AudioOutputI2S.h>
#include <functional>

enum class SoundType {
    CHIME_SOFT,
    CHIME_ALERT,
    REMINDER_BELL,
    TTS_AUDIO,
    CUSTOM_SOUND
};

class AudioManager {
public:
    typedef std::function<void()> PlaybackCallback;
    
    bool begin();
    void end();
    
    void update();
    
    // Playback control
    bool playSound(SoundType soundType, const String& filename = "");
    bool playSound(int soundId);
    bool playTTS(const String& base64Audio);
    bool stopPlayback();
    bool isPlaying();
    
    // Volume control
    void setVolume(uint8_t volume); // 0-100
    uint8_t getVolume();
    
    // File management
    bool uploadAudioFile(const String& filename, const uint8_t* data, size_t length);
    bool deleteAudioFile(const String& filename);
    std::vector<String> listAudioFiles();
    
    // Callbacks
    void setPlaybackCallback(PlaybackCallback callback);
    
    // Built-in sounds
    void playBootChime();
    void playReminderChime();
    void playLowBatteryAlert();
    void playErrorSound();
    
private:
    AudioOutputI2S* _audioOutput = nullptr;
    AudioGeneratorWAV* _audioGenerator = nullptr;
    AudioFileSourceLittleFS* _audioSource = nullptr;
    
    PlaybackCallback _playbackCallback;
    uint8_t _volume = 50;
    bool _isPlaying = false;
    String _currentFile;
    
    void _setupI2S();
    void _setupDAC();
    bool _playFile(const String& filename);
    String _getSoundFilename(SoundType soundType);
    void _onPlaybackComplete();
};