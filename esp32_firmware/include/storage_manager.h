#pragma once

#include <Arduino.h>
#include <ArduinoJson.h>
#include <LittleFS.h>

class StorageManager {
public:
    bool begin();
    void end();
    
    // JSON file operations
    bool loadJson(const String& filename, JsonDocument& doc);
    bool saveJson(const String& filename, const JsonDocument& doc);
    bool deleteFile(const String& filename);
    bool fileExists(const String& filename);
    
    // Provisioning
    bool isProvisioned();
    String getClientToken();
    bool setClientToken(const String& token);
    
    // Settings
    JsonObject getSettings();
    bool updateSetting(const String& key, const String& value);
    
    // Reminders
    JsonArray getReminders();
    bool addReminder(const JsonObject& reminder);
    bool deleteReminder(const String& id);
    bool updateReminder(const String& id, const JsonObject& reminder);
    
    // File operations
    bool writeFile(const String& filename, const uint8_t* data, size_t length);
    size_t readFile(const String& filename, uint8_t* buffer, size_t maxLength);
    size_t getFileSize(const String& filename);
    
    // Directory operations
    bool createDir(const String& dirname);
    void listFiles(const String& dirname);
    
private:
    bool _initialized = false;
    JsonDocument _settingsDoc;
    JsonDocument _remindersDoc;
    JsonDocument _provisionDoc;
    
    void _loadDefaultSettings();
    void _loadDefaultReminders();
};