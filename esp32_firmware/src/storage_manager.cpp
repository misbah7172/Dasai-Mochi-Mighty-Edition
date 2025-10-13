#include "storage_manager.h"
#include "config.h"
#include <LittleFS.h>

bool StorageManager::begin() {
    if (_initialized) return true;
    
    if (!LittleFS.begin(true)) {
        Serial.println("LittleFS mount failed");
        return false;
    }
    
    Serial.println("LittleFS mounted successfully");
    
    // Create audio directory if it doesn't exist
    if (!LittleFS.exists(AUDIO_DIR)) {
        createDir(AUDIO_DIR);
    }
    
    // Load existing files or create defaults
    if (!fileExists(SETTINGS_FILE)) {
        _loadDefaultSettings();
        saveJson(SETTINGS_FILE, _settingsDoc);
    } else {
        loadJson(SETTINGS_FILE, _settingsDoc);
    }
    
    if (!fileExists(REMINDERS_FILE)) {
        _loadDefaultReminders();
        saveJson(REMINDERS_FILE, _remindersDoc);
    } else {
        loadJson(REMINDERS_FILE, _remindersDoc);
    }
    
    if (fileExists(PROVISION_FILE)) {
        loadJson(PROVISION_FILE, _provisionDoc);
    }
    
    _initialized = true;
    return true;
}

void StorageManager::end() {
    LittleFS.end();
    _initialized = false;
}

bool StorageManager::loadJson(const String& filename, JsonDocument& doc) {
    if (!_initialized) return false;
    
    File file = LittleFS.open(filename, "r");
    if (!file) {
        Serial.printf("Failed to open %s for reading\n", filename.c_str());
        return false;
    }
    
    DeserializationError error = deserializeJson(doc, file);
    file.close();
    
    if (error) {
        Serial.printf("Failed to parse JSON from %s: %s\n", filename.c_str(), error.c_str());
        return false;
    }
    
    return true;
}

bool StorageManager::saveJson(const String& filename, const JsonDocument& doc) {
    if (!_initialized) return false;
    
    File file = LittleFS.open(filename, "w");
    if (!file) {
        Serial.printf("Failed to open %s for writing\n", filename.c_str());
        return false;
    }
    
    size_t written = serializeJson(doc, file);
    file.close();
    
    if (written == 0) {
        Serial.printf("Failed to write JSON to %s\n", filename.c_str());
        return false;
    }
    
    return true;
}

bool StorageManager::deleteFile(const String& filename) {
    if (!_initialized) return false;
    return LittleFS.remove(filename);
}

bool StorageManager::fileExists(const String& filename) {
    if (!_initialized) return false;
    return LittleFS.exists(filename);
}

bool StorageManager::isProvisioned() {
    return fileExists(PROVISION_FILE) && !getClientToken().isEmpty();
}

String StorageManager::getClientToken() {
    if (!_provisionDoc.containsKey("client_token")) {
        return "";
    }
    return _provisionDoc["client_token"].as<String>();
}

bool StorageManager::setClientToken(const String& token) {
    _provisionDoc["client_token"] = token;
    _provisionDoc["provisioned_at"] = millis();
    return saveJson(PROVISION_FILE, _provisionDoc);
}

JsonObject StorageManager::getSettings() {
    return _settingsDoc.as<JsonObject>();
}

bool StorageManager::updateSetting(const String& key, const String& value) {
    _settingsDoc[key] = value;
    return saveJson(SETTINGS_FILE, _settingsDoc);
}

JsonArray StorageManager::getReminders() {
    return _remindersDoc["reminders"].as<JsonArray>();
}

bool StorageManager::addReminder(const JsonObject& reminder) {
    JsonArray reminders = _remindersDoc["reminders"].as<JsonArray>();
    JsonObject newReminder = reminders.createNestedObject();
    
    newReminder["id"] = reminder["id"];
    newReminder["title"] = reminder["title"];
    newReminder["timestamp"] = reminder["timestamp"];
    newReminder["repeat"] = reminder["repeat"];
    newReminder["display_on_oled"] = reminder["display_on_oled"];
    newReminder["active"] = true;
    
    return saveJson(REMINDERS_FILE, _remindersDoc);
}

bool StorageManager::deleteReminder(const String& id) {
    JsonArray reminders = _remindersDoc["reminders"].as<JsonArray>();
    
    for (size_t i = 0; i < reminders.size(); i++) {
        if (reminders[i]["id"] == id) {
            reminders.remove(i);
            return saveJson(REMINDERS_FILE, _remindersDoc);
        }
    }
    
    return false;
}

bool StorageManager::updateReminder(const String& id, const JsonObject& reminder) {
    JsonArray reminders = _remindersDoc["reminders"].as<JsonArray>();
    
    for (JsonObject r : reminders) {
        if (r["id"] == id) {
            r["title"] = reminder["title"];
            r["timestamp"] = reminder["timestamp"];
            r["repeat"] = reminder["repeat"];
            r["display_on_oled"] = reminder["display_on_oled"];
            return saveJson(REMINDERS_FILE, _remindersDoc);
        }
    }
    
    return false;
}

bool StorageManager::writeFile(const String& filename, const uint8_t* data, size_t length) {
    if (!_initialized) return false;
    
    File file = LittleFS.open(filename, "w");
    if (!file) {
        Serial.printf("Failed to open %s for writing\n", filename.c_str());
        return false;
    }
    
    size_t written = file.write(data, length);
    file.close();
    
    return written == length;
}

size_t StorageManager::readFile(const String& filename, uint8_t* buffer, size_t maxLength) {
    if (!_initialized) return 0;
    
    File file = LittleFS.open(filename, "r");
    if (!file) {
        return 0;
    }
    
    size_t fileSize = file.size();
    size_t readSize = min(fileSize, maxLength);
    size_t bytesRead = file.read(buffer, readSize);
    
    file.close();
    return bytesRead;
}

size_t StorageManager::getFileSize(const String& filename) {
    if (!_initialized) return 0;
    
    File file = LittleFS.open(filename, "r");
    if (!file) return 0;
    
    size_t size = file.size();
    file.close();
    return size;
}

bool StorageManager::createDir(const String& dirname) {
    if (!_initialized) return false;
    return LittleFS.mkdir(dirname);
}

void StorageManager::listFiles(const String& dirname) {
    if (!_initialized) return;
    
    File root = LittleFS.open(dirname);
    if (!root || !root.isDirectory()) {
        Serial.println("Failed to open directory");
        return;
    }
    
    File file = root.openNextFile();
    while (file) {
        Serial.printf("File: %s, Size: %d bytes\n", file.name(), (int)file.size());
        file = root.openNextFile();
    }
}

void StorageManager::_loadDefaultSettings() {
    _settingsDoc.clear();
    _settingsDoc["mood"] = "normal";
    _settingsDoc["volume"] = 50;
    _settingsDoc["brightness"] = 128;
    _settingsDoc["wifi_enabled"] = false;
    _settingsDoc["timezone_offset"] = 0;
    _settingsDoc["battery_calibration"] = 1.0;
}

void StorageManager::_loadDefaultReminders() {
    _remindersDoc.clear();
    _remindersDoc["reminders"] = JsonArray();
}