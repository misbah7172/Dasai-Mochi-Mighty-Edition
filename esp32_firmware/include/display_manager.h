#pragma once

#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_SSD1306.h>
#include <RTClib.h>

enum class MochiMood {
    HAPPY,
    SLEEPY,
    SAD,
    CRAZY,
    NORMAL
};

enum class DisplayState {
    TIME_VIEW,
    REMINDER_LIST,
    MESSAGE_VIEW,
    FACE_VIEW,
    BATTERY_LOW
};

class DisplayManager {
public:
    bool begin();
    void end();
    
    void update();
    void clear();
    void setBrightness(uint8_t brightness);
    
    // Display states
    void showTimeView();
    void showReminderList();
    void showMessage(const String& title, const String& message);
    void showFace(MochiMood mood);
    void showBatteryLow(int percent);
    
    // Face management
    void setMood(MochiMood mood);
    MochiMood getMood() const;
    
    // Text display
    void drawCenteredText(const String& text, int y, int textSize = 1);
    void drawScrollingText(const String& text, int y, int textSize = 1);
    
    // Status indicators
    void showBLEStatus(bool connected);
    void showBatteryPercent(int percent);
    void showWiFiStatus(bool connected);
    
private:
    Adafruit_SSD1306* _display = nullptr;
    DisplayState _currentState = DisplayState::TIME_VIEW;
    MochiMood _currentMood = MochiMood::NORMAL;
    
    unsigned long _lastUpdate = 0;
    int _scrollOffset = 0;
    String _scrollText = "";
    
    void _drawFace(MochiMood mood);
    void _drawHappyFace();
    void _drawSleepyFace();
    void _drawSadFace();
    void _drawCrazyFace();
    void _drawNormalFace();
    
    void _drawTime();
    void _drawReminders();
    void _drawStatusBar();
    
    // Animation helpers
    void _animateEyes(int frame);
    void _animateMouth(int frame);
};