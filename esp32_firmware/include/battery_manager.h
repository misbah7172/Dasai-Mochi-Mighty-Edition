#pragma once

#include <Arduino.h>
#include <functional>

class BatteryManager {
public:
    typedef std::function<void(int)> BatteryCallback;
    
    bool begin();
    void end();
    
    void update();
    
    // Battery status
    float getVoltage();
    int getPercentage();
    bool isCharging();
    bool isCriticalLevel();
    
    // Calibration
    void setCalibration(float calibrationFactor);
    float getCalibration();
    
    // Callbacks
    void setBatteryCallback(BatteryCallback callback);
    
    // Configuration
    void setUpdateInterval(unsigned long interval);
    void setThresholds(float minVoltage, float maxVoltage, int criticalPercent);
    
private:
    BatteryCallback _batteryCallback;
    
    float _lastVoltage = 0.0f;
    int _lastPercentage = 0;
    bool _lastCriticalState = false;
    
    unsigned long _lastUpdate = 0;
    unsigned long _updateInterval = 30000; // 30 seconds
    
    float _minVoltage = 3.2f;
    float _maxVoltage = 4.2f;
    int _criticalPercent = 10;
    float _calibrationFactor = 1.0f;
    
    float _readRawVoltage();
    int _voltageToPercentage(float voltage);
    bool _detectCharging();
};