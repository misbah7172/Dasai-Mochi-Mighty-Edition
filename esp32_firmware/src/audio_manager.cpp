#include "audio_manager.h"
#include "config.h"

bool AudioManager::begin() {
    Serial.println("Initializing audio manager...");
    
    if (AUDIO_USE_I2S) {
        _setupI2S();
    } else {
        _setupDAC();
    }
    
    // Initialize audio components
    _audioOutput = new AudioOutputI2S();
    _audioGenerator = new AudioGeneratorWAV();
    
    Serial.println("Audio manager initialized");
    return true;
}

void AudioManager::end() {
    stopPlayback();
    
    if (_audioGenerator) {
        delete _audioGenerator;
        _audioGenerator = nullptr;
    }
    
    if (_audioOutput) {
        delete _audioOutput;
        _audioOutput = nullptr;
    }
    
    if (_audioSource) {
        delete _audioSource;
        _audioSource = nullptr;
    }
}

void AudioManager::update() {
    if (_isPlaying && _audioGenerator && _audioGenerator->isRunning()) {
        if (!_audioGenerator->loop()) {
            // Playback finished
            stopPlayback();
            _onPlaybackComplete();
        }
    }
}

bool AudioManager::playSound(SoundType soundType, const String& filename) {
    String soundFile;
    
    if (soundType == SoundType::CUSTOM_SOUND && !filename.isEmpty()) {
        soundFile = AUDIO_DIR + "/" + filename;
    } else {
        soundFile = _getSoundFilename(soundType);
    }
    
    return _playFile(soundFile);
}

bool AudioManager::playSound(int soundId) {
    SoundType soundType;
    
    switch (soundId) {
        case 0: soundType = SoundType::CHIME_SOFT; break;
        case 1: soundType = SoundType::CHIME_ALERT; break;
        case 2: soundType = SoundType::REMINDER_BELL; break;
        default: return false;
    }
    
    return playSound(soundType);
}

bool AudioManager::playTTS(const String& base64Audio) {
    // Decode base64 and save as temporary file
    String tempFile = "/temp_tts.wav";
    
    // Simple base64 decode (you'd use a proper decoder in production)
    // For now, just save the data as-is
    File file = LittleFS.open(tempFile, "w");
    if (!file) {
        Serial.println("Failed to create temp TTS file");
        return false;
    }
    
    file.print(base64Audio);
    file.close();
    
    return _playFile(tempFile);
}

bool AudioManager::stopPlayback() {
    if (_audioGenerator && _audioGenerator->isRunning()) {
        _audioGenerator->stop();
    }
    
    _isPlaying = false;
    _currentFile = "";
    
    return true;
}

bool AudioManager::isPlaying() {
    return _isPlaying;
}

void AudioManager::setVolume(uint8_t volume) {
    _volume = constrain(volume, 0, 100);
    
    if (_audioOutput) {
        float gain = _volume / 100.0f;
        _audioOutput->SetGain(gain);
    }
    
    Serial.printf("Volume set to: %d%%\n", _volume);
}

uint8_t AudioManager::getVolume() {
    return _volume;
}

bool AudioManager::uploadAudioFile(const String& filename, const uint8_t* data, size_t length) {
    String fullPath = AUDIO_DIR + "/" + filename;
    
    File file = LittleFS.open(fullPath, "w");
    if (!file) {
        Serial.printf("Failed to create audio file: %s\n", fullPath.c_str());
        return false;
    }
    
    size_t written = file.write(data, length);
    file.close();
    
    if (written != length) {
        Serial.printf("Failed to write complete audio file: %s\n", fullPath.c_str());
        return false;
    }
    
    Serial.printf("Audio file uploaded: %s (%d bytes)\n", fullPath.c_str(), length);
    return true;
}

bool AudioManager::deleteAudioFile(const String& filename) {
    String fullPath = AUDIO_DIR + "/" + filename;
    
    if (LittleFS.remove(fullPath)) {
        Serial.printf("Audio file deleted: %s\n", fullPath.c_str());
        return true;
    }
    
    return false;
}

std::vector<String> AudioManager::listAudioFiles() {
    std::vector<String> files;
    
    File root = LittleFS.open(AUDIO_DIR);
    if (!root || !root.isDirectory()) {
        return files;
    }
    
    File file = root.openNextFile();
    while (file) {
        if (!file.isDirectory()) {
            files.push_back(file.name());
        }
        file = root.openNextFile();
    }
    
    return files;
}

void AudioManager::setPlaybackCallback(PlaybackCallback callback) {
    _playbackCallback = callback;
}

void AudioManager::playBootChime() {
    playSound(SoundType::CHIME_SOFT);
}

void AudioManager::playReminderChime() {
    playSound(SoundType::REMINDER_BELL);
}

void AudioManager::playLowBatteryAlert() {
    playSound(SoundType::CHIME_ALERT);
}

void AudioManager::playErrorSound() {
    playSound(SoundType::CHIME_ALERT);
}

void AudioManager::_setupI2S() {
    Serial.println("Setting up I2S audio output");
    
    // I2S configuration will be handled by AudioOutputI2S library
    // Pin configuration is set in the library initialization
}

void AudioManager::_setupDAC() {
    Serial.println("Setting up DAC audio output");
    
    // Simple DAC setup for GPIO25 (DAC1)
    pinMode(DAC_PIN, OUTPUT);
}

bool AudioManager::_playFile(const String& filename) {
    if (_isPlaying) {
        stopPlayback();
    }
    
    if (!LittleFS.exists(filename)) {
        Serial.printf("Audio file not found: %s\n", filename.c_str());
        return false;
    }
    
    // Clean up previous source
    if (_audioSource) {
        delete _audioSource;
    }
    
    _audioSource = new AudioFileSourceLittleFS(filename.c_str());
    
    if (!_audioSource) {
        Serial.println("Failed to create audio source");
        return false;
    }
    
    // Set volume
    setVolume(_volume);
    
    // Start playback
    if (_audioGenerator->begin(_audioSource, _audioOutput)) {
        _isPlaying = true;
        _currentFile = filename;
        Serial.printf("Started playing: %s\n", filename.c_str());
        return true;
    } else {
        Serial.printf("Failed to start playback: %s\n", filename.c_str());
        return false;
    }
}

String AudioManager::_getSoundFilename(SoundType soundType) {
    switch (soundType) {
        case SoundType::CHIME_SOFT:
            return AUDIO_DIR + "/chime_soft.wav";
        case SoundType::CHIME_ALERT:
            return AUDIO_DIR + "/chime_alert.wav";
        case SoundType::REMINDER_BELL:
            return AUDIO_DIR + "/reminder_bell.wav";
        case SoundType::TTS_AUDIO:
            return "/temp_tts.wav";
        default:
            return AUDIO_DIR + "/chime_soft.wav";
    }
}

void AudioManager::_onPlaybackComplete() {
    if (_playbackCallback) {
        _playbackCallback();
    }
    
    Serial.println("Audio playback completed");
}