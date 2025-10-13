#include "battery_manager.h"
#include "config.h"

bool BatteryManager::begin() {
    analogSetAttenuation(ADC_11db);
    
    Serial.println("Battery manager initialized");
    return true;
}

void BatteryManager::end() {
    // Nothing to clean up
}

void BatteryManager::update() {
    unsigned long now = millis();
    
    if (now - _lastUpdate >= _updateInterval) {
        float voltage = getVoltage();
        int percentage = getPercentage();
        bool critical = isCriticalLevel();
        
        // Check for significant changes
        if (abs(percentage - _lastPercentage) >= 5 || 
            critical != _lastCriticalState) {
            
            if (_batteryCallback) {
                _batteryCallback(percentage);
            }
            
            _lastPercentage = percentage;
            _lastCriticalState = critical;
        }
        
        _lastVoltage = voltage;
        _lastUpdate = now;
    }
}

float BatteryManager::getVoltage() {
    float rawVoltage = _readRawVoltage();
    
    // Apply voltage divider calculation
    // Assuming 2:1 voltage divider (R1=R2=100k)
    float actualVoltage = rawVoltage * 2.0f * _calibrationFactor;
    
    return actualVoltage;
}

int BatteryManager::getPercentage() {
    float voltage = getVoltage();
    return _voltageToPercentage(voltage);
}

bool BatteryManager::isCharging() {
    return _detectCharging();
}

bool BatteryManager::isCriticalLevel() {
    return getPercentage() <= _criticalPercent;
}

void BatteryManager::setCalibration(float calibrationFactor) {
    _calibrationFactor = calibrationFactor;
    Serial.printf("Battery calibration set to: %.3f\n", calibrationFactor);
}

float BatteryManager::getCalibration() {
    return _calibrationFactor;
}

void BatteryManager::setBatteryCallback(BatteryCallback callback) {
    _batteryCallback = callback;
}

void BatteryManager::setUpdateInterval(unsigned long interval) {
    _updateInterval = interval;
}

void BatteryManager::setThresholds(float minVoltage, float maxVoltage, int criticalPercent) {
    _minVoltage = minVoltage;
    _maxVoltage = maxVoltage;
    _criticalPercent = criticalPercent;
    
    Serial.printf("Battery thresholds set - Min: %.2fV, Max: %.2fV, Critical: %d%%\n",
                  minVoltage, maxVoltage, criticalPercent);
}

float BatteryManager::_readRawVoltage() {
    // Take multiple readings and average
    const int numReadings = 10;
    uint32_t sum = 0;
    
    for (int i = 0; i < numReadings; i++) {
        sum += analogRead(BATTERY_ADC_PIN);
        delay(1);
    }
    
    uint32_t average = sum / numReadings;
    
    // Convert ADC reading to voltage
    // ESP32 ADC: 12-bit (0-4095), reference voltage ~3.3V
    // With 11dB attenuation, max input ~3.9V
    float voltage = (average / 4095.0f) * 3.9f;
    
    return voltage;
}

int BatteryManager::_voltageToPercentage(float voltage) {
    if (voltage >= _maxVoltage) return 100;
    if (voltage <= _minVoltage) return 0;
    
    // Linear interpolation between min and max voltage
    float percentage = ((voltage - _minVoltage) / (_maxVoltage - _minVoltage)) * 100.0f;
    
    return constrain((int)percentage, 0, 100);
}

bool BatteryManager::_detectCharging() {
    // Simple charging detection by voltage increase rate
    static float lastVoltage = 0;
    static unsigned long lastCheck = 0;
    
    unsigned long now = millis();
    float currentVoltage = getVoltage();
    
    if (now - lastCheck > 5000) { // Check every 5 seconds
        bool charging = false;
        
        if (lastVoltage > 0) {
            float voltageChange = currentVoltage - lastVoltage;
            // If voltage is increasing, likely charging
            charging = (voltageChange > 0.01f); // 10mV increase
        }
        
        lastVoltage = currentVoltage;
        lastCheck = now;
        
        return charging;
    }
    
    return false; // Default to not charging
}