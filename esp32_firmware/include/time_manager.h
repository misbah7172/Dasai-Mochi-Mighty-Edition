#pragma once

#include <Arduino.h>
#include <RTClib.h>
#include <ArduinoJson.h>
#include <functional>

struct Reminder {
    String id;
    String title;
    DateTime triggerTime;
    bool repeat;
    bool displayOnOled;
    bool active;
};

class TimeManager {
public:
    typedef std::function<void(const Reminder&)> AlarmCallback;
    
    bool begin();
    void end();
    
    void update();
    
    // Time operations
    DateTime getCurrentTime();
    bool setTime(const DateTime& time);
    bool syncTime(uint32_t timestamp, int timezoneOffset = 0);
    
    // Alarm operations
    void setAlarmCallback(AlarmCallback callback);
    bool scheduleAlarm(const DateTime& time, const String& id);
    bool cancelAlarm(const String& id);
    void checkAlarms();
    
    // Reminder operations
    bool addReminder(const Reminder& reminder);
    bool deleteReminder(const String& id);
    Reminder* getReminder(const String& id);
    std::vector<Reminder> getActiveReminders();
    std::vector<Reminder> getTodayReminders();
    
    // Status
    bool isRTCConnected();
    bool hasValidTime();
    String getTimeString(bool includeSeconds = false);
    String getDateString();
    
private:
    RTC_DS3231* _rtc = nullptr;
    std::vector<Reminder> _reminders;
    AlarmCallback _alarmCallback;
    
    DateTime _lastAlarmCheck;
    unsigned long _lastUpdate = 0;
    bool _rtcConnected = false;
    
    void _loadRemindersFromStorage();
    void _saveRemindersToStorage();
    DateTime _parseTimestamp(uint32_t timestamp);
    bool _isTimeForReminder(const Reminder& reminder, const DateTime& now);
};