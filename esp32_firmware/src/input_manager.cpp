#include "input_manager.h"
#include "config.h"

bool InputManager::begin() {
    // Initialize button pins
    pinMode(BUTTON_SNOOZE_PIN, INPUT_PULLUP);
    pinMode(BUTTON_PAIR_PIN, INPUT_PULLUP);
    
    // Initialize microphone if enabled
    if (MIC_ENABLE) {
        _setupMicrophone();
        _micEnabled = true;
    }
    
    Serial.println("Input manager initialized");
    return true;
}

void InputManager::end() {
    // Nothing specific to clean up
}

void InputManager::update() {
    _handleSnoozeButton();
    _handlePairButton();
    
    if (_micEnabled && _wakeWordEnabled) {
        _handleAudioInput();
    }
}

void InputManager::setSnoozeCallback(ButtonCallback callback) {
    _snoozeCallback = callback;
}

void InputManager::setPairCallback(ButtonCallback callback) {
    _pairCallback = callback;
}

void InputManager::setAudioCallback(AudioCallback callback) {
    _audioCallback = callback;
}

void InputManager::enableWakeWordDetection(bool enable) {
    _wakeWordEnabled = enable && _micEnabled;
    Serial.printf("Wake word detection: %s\n", _wakeWordEnabled ? "enabled" : "disabled");
}

bool InputManager::isWakeWordEnabled() {
    return _wakeWordEnabled;
}

bool InputManager::isSnoozePressed() {
    return _snoozePressed;
}

bool InputManager::isPairPressed() {
    return _pairPressed;
}

bool InputManager::isPairLongPressed() {
    return _pairLongPressed;
}

void InputManager::_handleSnoozeButton() {
    bool currentState = digitalRead(BUTTON_SNOOZE_PIN) == LOW;
    unsigned long now = millis();
    
    if (currentState != _snoozePressed) {
        if (now - _lastSnoozePress > DEBOUNCE_DELAY) {
            _snoozePressed = currentState;
            _lastSnoozePress = now;
            
            if (_snoozePressed && _snoozeCallback) {
                _snoozeCallback();
            }
        }
    }
}

void InputManager::_handlePairButton() {
    bool currentState = digitalRead(BUTTON_PAIR_PIN) == LOW;
    unsigned long now = millis();
    
    if (currentState != _pairPressed) {
        if (now - _lastPairPress > DEBOUNCE_DELAY) {
            _pairPressed = currentState;
            _lastPairPress = now;
            
            if (_pairPressed) {
                // Button pressed - start timing for long press
                _pairPressStart = now;
                _pairLongPressed = false;
            } else {
                // Button released
                if (_pairLongPressed && _pairCallback) {
                    _pairCallback();
                }
                _pairLongPressed = false;
            }
        }
    }
    
    // Check for long press
    if (_pairPressed && !_pairLongPressed) {
        if (now - _pairPressStart >= LONG_PRESS_DURATION) {
            _pairLongPressed = true;
            Serial.println("Pair button long press detected");
        }
    }
}

void InputManager::_handleAudioInput() {
    if (!_micEnabled) return;
    
    float audioLevel = _readAudioLevel();
    
    if (audioLevel > _audioThreshold) {
        Serial.printf("Audio level: %.3f (threshold: %.3f)\n", audioLevel, _audioThreshold);
        
        if (_audioCallback) {
            _audioCallback(audioLevel);
        }
    }
}

void InputManager::_setupMicrophone() {
    if (!MIC_ENABLE) return;
    
    Serial.println("Setting up I2S microphone");
    
    // I2S microphone configuration
    // This would be implemented using ESP32 I2S driver
    // For now, it's a placeholder
    
    _micEnabled = true;
}

float InputManager::_readAudioLevel() {
    if (!_micEnabled) return 0.0f;
    
    // This would read actual I2S microphone data
    // For now, return a simulated value
    
    // In a real implementation:
    // 1. Read I2S samples into buffer
    // 2. Calculate RMS or peak level
    // 3. Return normalized audio level (0.0 - 1.0)
    
    return 0.0f; // Placeholder
}