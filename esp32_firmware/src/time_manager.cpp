#include "time_manager.h"
#include "config.h"

// External reference to storage
extern StorageManager storage;

bool TimeManager::begin() {
    _rtc = new RTC_DS3231();
    
    if (!_rtc->begin()) {
        Serial.println("Could not find RTC! Check wiring.");
        _rtcConnected = false;
        return false;
    }
    
    if (_rtc->lostPower()) {
        Serial.println("RTC lost power, setting time to compile time");
        _rtc->adjust(DateTime(F(__DATE__), F(__TIME__)));
    }
    
    _rtcConnected = true;
    _lastAlarmCheck = getCurrentTime();
    
    // Load reminders from storage
    _loadRemindersFromStorage();
    
    Serial.println("Time manager initialized");
    return true;
}

void TimeManager::end() {
    if (_rtc) {
        delete _rtc;
        _rtc = nullptr;
    }
    _rtcConnected = false;
}

void TimeManager::update() {
    unsigned long now = millis();
    
    if (now - _lastUpdate >= 1000) { // Update every second
        if (_rtcConnected) {
            checkAlarms();
        }
        _lastUpdate = now;
    }
}

DateTime TimeManager::getCurrentTime() {
    if (_rtcConnected && _rtc) {
        return _rtc->now();
    }
    
    // Fallback to system time (less accurate)
    return DateTime(millis() / 1000);
}

bool TimeManager::setTime(const DateTime& time) {
    if (_rtcConnected && _rtc) {
        _rtc->adjust(time);
        Serial.printf("Time set to: %s\n", time.timestamp().c_str());
        return true;
    }
    return false;
}

bool TimeManager::syncTime(uint32_t timestamp, int timezoneOffset) {
    DateTime newTime = _parseTimestamp(timestamp);
    
    // Apply timezone offset (in hours)
    newTime = newTime + TimeSpan(0, timezoneOffset, 0, 0);
    
    return setTime(newTime);
}

void TimeManager::setAlarmCallback(AlarmCallback callback) {
    _alarmCallback = callback;
}

bool TimeManager::scheduleAlarm(const DateTime& time, const String& id) {
    if (!_rtcConnected) return false;
    
    // For DS3231, we can only set two alarms
    // This is a simplified implementation
    Serial.printf("Scheduling alarm for %s with ID: %s\n", time.timestamp().c_str(), id.c_str());
    
    // In a real implementation, you would use DS3231 alarm registers
    // For now, we'll rely on software checking in checkAlarms()
    
    return true;
}

bool TimeManager::cancelAlarm(const String& id) {
    Serial.printf("Cancelling alarm with ID: %s\n", id.c_str());
    
    // Remove from reminder list
    return deleteReminder(id);
}

void TimeManager::checkAlarms() {
    if (!_rtcConnected) return;
    
    DateTime now = getCurrentTime();
    
    // Only check once per minute to avoid duplicates
    if (now.minute() == _lastAlarmCheck.minute()) {
        return;
    }
    
    _lastAlarmCheck = now;
    
    for (auto& reminder : _reminders) {
        if (reminder.active && _isTimeForReminder(reminder, now)) {
            Serial.printf("Triggering reminder: %s\n", reminder.title.c_str());
            
            if (_alarmCallback) {
                _alarmCallback(reminder);
            }
            
            // If not repeating, mark as inactive
            if (!reminder.repeat) {
                reminder.active = false;
                _saveRemindersToStorage();
            }
        }
    }
}

bool TimeManager::addReminder(const Reminder& reminder) {
    _reminders.push_back(reminder);
    _saveRemindersToStorage();
    
    Serial.printf("Added reminder: %s for %s\n", 
                  reminder.title.c_str(), 
                  reminder.triggerTime.timestamp().c_str());
    return true;
}

bool TimeManager::deleteReminder(const String& id) {
    for (auto it = _reminders.begin(); it != _reminders.end(); ++it) {
        if (it->id == id) {
            _reminders.erase(it);
            _saveRemindersToStorage();
            Serial.printf("Deleted reminder with ID: %s\n", id.c_str());
            return true;
        }
    }
    return false;
}

Reminder* TimeManager::getReminder(const String& id) {
    for (auto& reminder : _reminders) {
        if (reminder.id == id) {
            return &reminder;
        }
    }
    return nullptr;
}

std::vector<Reminder> TimeManager::getActiveReminders() {
    std::vector<Reminder> active;
    for (const auto& reminder : _reminders) {
        if (reminder.active) {
            active.push_back(reminder);
        }
    }
    return active;
}

std::vector<Reminder> TimeManager::getTodayReminders() {
    std::vector<Reminder> today;
    DateTime now = getCurrentTime();
    
    for (const auto& reminder : _reminders) {
        if (reminder.active && 
            reminder.triggerTime.year() == now.year() &&
            reminder.triggerTime.month() == now.month() &&
            reminder.triggerTime.day() == now.day()) {
            today.push_back(reminder);
        }
    }
    return today;
}

bool TimeManager::isRTCConnected() {
    return _rtcConnected;
}

bool TimeManager::hasValidTime() {
    if (!_rtcConnected) return false;
    
    DateTime now = getCurrentTime();
    return now.year() > 2020; // Assume any time after 2020 is valid
}

String TimeManager::getTimeString(bool includeSeconds) {
    DateTime now = getCurrentTime();
    
    char buffer[20];
    if (includeSeconds) {
        sprintf(buffer, "%02d:%02d:%02d", now.hour(), now.minute(), now.second());
    } else {
        sprintf(buffer, "%02d:%02d", now.hour(), now.minute());
    }
    
    return String(buffer);
}

String TimeManager::getDateString() {
    DateTime now = getCurrentTime();
    
    const char* months[] = {"Jan", "Feb", "Mar", "Apr", "May", "Jun",
                           "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};
    
    const char* days[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
    
    char buffer[50];
    sprintf(buffer, "%s, %s %d", 
            days[now.dayOfTheWeek()], 
            months[now.month() - 1], 
            now.day());
    
    return String(buffer);
}

void TimeManager::_loadRemindersFromStorage() {
    JsonArray reminders = storage.getReminders();
    
    _reminders.clear();
    
    for (JsonObject reminderJson : reminders) {
        Reminder reminder;
        reminder.id = reminderJson["id"].as<String>();
        reminder.title = reminderJson["title"].as<String>();
        reminder.triggerTime = DateTime(reminderJson["timestamp"]);
        reminder.repeat = reminderJson["repeat"];
        reminder.displayOnOled = reminderJson["display_on_oled"];
        reminder.active = reminderJson["active"];
        
        _reminders.push_back(reminder);
    }
    
    Serial.printf("Loaded %d reminders from storage\n", _reminders.size());
}

void TimeManager::_saveRemindersToStorage() {
    // Create JSON array
    JsonDocument doc;
    JsonArray remindersArray = doc["reminders"].to<JsonArray>();
    
    for (const auto& reminder : _reminders) {
        JsonObject reminderObj = remindersArray.createNestedObject();
        reminderObj["id"] = reminder.id;
        reminderObj["title"] = reminder.title;
        reminderObj["timestamp"] = reminder.triggerTime.unixtime();
        reminderObj["repeat"] = reminder.repeat;
        reminderObj["display_on_oled"] = reminder.displayOnOled;
        reminderObj["active"] = reminder.active;
    }
    
    storage.saveJson(REMINDERS_FILE, doc);
}

DateTime TimeManager::_parseTimestamp(uint32_t timestamp) {
    return DateTime(timestamp);
}

bool TimeManager::_isTimeForReminder(const Reminder& reminder, const DateTime& now) {
    // Simple time matching (within the same minute)
    return (reminder.triggerTime.year() == now.year() &&
            reminder.triggerTime.month() == now.month() &&
            reminder.triggerTime.day() == now.day() &&
            reminder.triggerTime.hour() == now.hour() &&
            reminder.triggerTime.minute() == now.minute());
}