#pragma once

#include <Arduino.h>
#include <functional>

class InputManager {
public:
    typedef std::function<void()> ButtonCallback;
    typedef std::function<void(float)> AudioCallback;
    
    bool begin();
    void end();
    
    void update();
    
    // Button management
    void setSnoozeCallback(ButtonCallback callback);
    void setPairCallback(ButtonCallback callback);
    
    // Audio input (if enabled)
    void setAudioCallback(AudioCallback callback);
    void enableWakeWordDetection(bool enable);
    bool isWakeWordEnabled();
    
    // Button states
    bool isSnoozePressed();
    bool isPairPressed();
    bool isPairLongPressed();
    
private:
    ButtonCallback _snoozeCallback;
    ButtonCallback _pairCallback;
    AudioCallback _audioCallback;
    
    bool _snoozePressed = false;
    bool _pairPressed = false;
    bool _pairLongPressed = false;
    
    unsigned long _pairPressStart = 0;
    unsigned long _lastSnoozePress = 0;
    unsigned long _lastPairPress = 0;
    
    const unsigned long DEBOUNCE_DELAY = 50;
    const unsigned long LONG_PRESS_DURATION = 3000;
    
    // Audio input variables
    bool _micEnabled = false;
    bool _wakeWordEnabled = false;
    float _audioThreshold = 0.1f;
    
    void _handleSnoozeButton();
    void _handlePairButton();
    void _handleAudioInput();
    void _setupMicrophone();
    float _readAudioLevel();
};