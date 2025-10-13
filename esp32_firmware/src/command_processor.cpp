#include "command_processor.h"
#include "config.h"

// External references to global managers
extern StorageManager storage;
extern DisplayManager display;
extern TimeManager timeManager;
extern AudioManager audio;
extern BatteryManager battery;

void CommandProcessor::setResponseCallback(ResponseCallback callback) {
    _responseCallback = callback;
}

void CommandProcessor::processCommand(const JsonObject& command) {
    if (!command.containsKey("command")) {
        _sendError("unknown", "Missing command field");
        return;
    }
    
    String cmd = command["command"];
    JsonObject data = command["data"];
    
    Serial.printf("Processing command: %s\n", cmd.c_str());
    
    bool success = false;
    
    if (cmd == "add_reminder") {
        success = handleAddReminder(data);
    } else if (cmd == "delete_reminder") {
        success = handleDeleteReminder(data);
    } else if (cmd == "show_reminder") {
        success = handleShowReminder(data);
    } else if (cmd == "sync_time") {
        success = handleSyncTime(data);
    } else if (cmd == "set_mood") {
        success = handleSetMood(data);
    } else if (cmd == "request_status") {
        success = handleRequestStatus(data);
    } else if (cmd == "play_sound") {
        success = handlePlaySound(data);
    } else if (cmd == "update_face") {
        success = handleUpdateFace(data);
    } else if (cmd == "get_battery") {
        success = handleGetBattery(data);
    } else if (cmd == "schedule_local_alarm") {
        success = handleScheduleAlarm(data);
    } else if (cmd == "provision") {
        success = handleProvision(data);
    } else if (cmd == "upload_file") {
        success = handleUploadFile(data);
    } else if (cmd == "ota_update") {
        success = handleOTAUpdate(data);
    } else if (cmd == "calibrate_battery") {
        success = handleCalibrateBattery(data);
    } else if (cmd == "set_wifi") {
        success = handleSetWiFi(data);
    } else {
        _sendError(cmd, "Unknown command");
        return;
    }
    
    if (!success) {
        _sendError(cmd, "Command execution failed");
    }
}

bool CommandProcessor::handleAddReminder(const JsonObject& data) {
    if (!_validateReminder(data)) {
        return false;
    }
    
    if (storage.addReminder(data)) {
        // Also add to time manager for scheduling
        Reminder reminder;
        reminder.id = data["id"];
        reminder.title = data["title"];
        reminder.triggerTime = DateTime(data["timestamp"]);
        reminder.repeat = data["repeat"];
        reminder.displayOnOled = data["display_on_oled"];
        reminder.active = true;
        
        timeManager.addReminder(reminder);
        
        JsonDocument responseDoc;
        responseDoc["message"] = "Reminder added successfully";
        _sendResponse("add_reminder", true, responseDoc.as<JsonObject>());
        return true;
    }
    
    return false;
}

bool CommandProcessor::handleDeleteReminder(const JsonObject& data) {
    if (!data.containsKey("id")) {
        return false;
    }
    
    String id = data["id"];
    
    if (storage.deleteReminder(id)) {
        timeManager.deleteReminder(id);
        
        JsonDocument responseDoc;
        responseDoc["message"] = "Reminder deleted successfully";
        _sendResponse("delete_reminder", true, responseDoc.as<JsonObject>());
        return true;
    }
    
    return false;
}

bool CommandProcessor::handleShowReminder(const JsonObject& data) {
    if (!data.containsKey("id")) {
        return false;
    }
    
    String id = data["id"];
    Reminder* reminder = timeManager.getReminder(id);
    
    if (reminder) {
        display.showMessage("Reminder", reminder->title);
        
        JsonDocument responseDoc;
        responseDoc["message"] = "Reminder displayed";
        _sendResponse("show_reminder", true, responseDoc.as<JsonObject>());
        return true;
    }
    
    return false;
}

bool CommandProcessor::handleSyncTime(const JsonObject& data) {
    if (!_validateTimestamp(data)) {
        return false;
    }
    
    uint32_t timestamp = data["timestamp"];
    int timezoneOffset = data.containsKey("timezone") ? data["timezone"] : 0;
    
    if (timeManager.syncTime(timestamp, timezoneOffset)) {
        JsonDocument responseDoc;
        responseDoc["message"] = "Time synchronized";
        responseDoc["current_time"] = timeManager.getCurrentTime().unixtime();
        _sendResponse("sync_time", true, responseDoc.as<JsonObject>());
        return true;
    }
    
    return false;
}

bool CommandProcessor::handleSetMood(const JsonObject& data) {
    if (!data.containsKey("mood") || !_validateMood(data["mood"])) {
        return false;
    }
    
    String moodStr = data["mood"];
    MochiMood mood = MochiMood::NORMAL;
    
    if (moodStr == "happy") mood = MochiMood::HAPPY;
    else if (moodStr == "sleepy") mood = MochiMood::SLEEPY;
    else if (moodStr == "sad") mood = MochiMood::SAD;
    else if (moodStr == "crazy") mood = MochiMood::CRAZY;
    
    display.setMood(mood);
    display.showFace(mood);
    
    // Save mood to storage
    storage.updateSetting("mood", moodStr);
    
    JsonDocument responseDoc;
    responseDoc["message"] = "Mood updated";
    responseDoc["mood"] = moodStr;
    _sendResponse("set_mood", true, responseDoc.as<JsonObject>());
    return true;
}

bool CommandProcessor::handleRequestStatus(const JsonObject& data) {
    JsonDocument responseDoc;
    
    responseDoc["status"] = "ok";
    responseDoc["time"] = timeManager.getCurrentTime().unixtime();
    responseDoc["battery"]["percent"] = battery.getPercentage();
    responseDoc["battery"]["voltage"] = battery.getVoltage();
    responseDoc["battery"]["charging"] = battery.isCharging();
    responseDoc["rtc_connected"] = timeManager.isRTCConnected();
    responseDoc["free_heap"] = ESP.getFreeHeap();
    responseDoc["uptime"] = millis();
    
    // Get reminder count
    auto reminders = timeManager.getActiveReminders();
    responseDoc["reminders"]["total"] = reminders.size();
    
    auto todayReminders = timeManager.getTodayReminders();
    responseDoc["reminders"]["today"] = todayReminders.size();
    
    _sendResponse("request_status", true, responseDoc.as<JsonObject>());
    return true;
}

bool CommandProcessor::handlePlaySound(const JsonObject& data) {
    if (!data.containsKey("sound_id") || !_validateSoundId(data["sound_id"])) {
        return false;
    }
    
    int soundId = data["sound_id"];
    
    if (audio.playSound(soundId)) {
        JsonDocument responseDoc;
        responseDoc["message"] = "Sound playing";
        responseDoc["sound_id"] = soundId;
        _sendResponse("play_sound", true, responseDoc.as<JsonObject>());
        return true;
    }
    
    return false;
}

bool CommandProcessor::handleUpdateFace(const JsonObject& data) {
    if (!data.containsKey("face_name")) {
        return false;
    }
    
    String faceName = data["face_name"];
    
    // Map face name to mood
    MochiMood mood = MochiMood::NORMAL;
    if (faceName == "happy") mood = MochiMood::HAPPY;
    else if (faceName == "sleepy") mood = MochiMood::SLEEPY;
    else if (faceName == "sad") mood = MochiMood::SAD;
    else if (faceName == "crazy") mood = MochiMood::CRAZY;
    
    display.showFace(mood);
    
    JsonDocument responseDoc;
    responseDoc["message"] = "Face updated";
    responseDoc["face_name"] = faceName;
    _sendResponse("update_face", true, responseDoc.as<JsonObject>());
    return true;
}

bool CommandProcessor::handleGetBattery(const JsonObject& data) {
    JsonDocument responseDoc;
    responseDoc["voltage"] = battery.getVoltage();
    responseDoc["percent"] = battery.getPercentage();
    responseDoc["charging"] = battery.isCharging();
    responseDoc["critical"] = battery.isCriticalLevel();
    
    _sendResponse("get_battery", true, responseDoc.as<JsonObject>());
    return true;
}

bool CommandProcessor::handleScheduleAlarm(const JsonObject& data) {
    if (!_validateTimestamp(data) || !data.containsKey("id")) {
        return false;
    }
    
    DateTime alarmTime(data["timestamp"]);
    String id = data["id"];
    
    if (timeManager.scheduleAlarm(alarmTime, id)) {
        JsonDocument responseDoc;
        responseDoc["message"] = "Alarm scheduled";
        responseDoc["alarm_time"] = data["timestamp"];
        _sendResponse("schedule_local_alarm", true, responseDoc.as<JsonObject>());
        return true;
    }
    
    return false;
}

bool CommandProcessor::handleProvision(const JsonObject& data) {
    if (!_validateProvisionData(data)) {
        return false;
    }
    
    String clientToken = data["client_token"];
    
    if (storage.setClientToken(clientToken)) {
        JsonDocument responseDoc;
        responseDoc["message"] = "Device provisioned successfully";
        responseDoc["device_id"] = WiFi.macAddress();
        _sendResponse("provision", true, responseDoc.as<JsonObject>());
        return true;
    }
    
    return false;
}

bool CommandProcessor::handleUploadFile(const JsonObject& data) {
    if (!data.containsKey("filename") || !data.containsKey("data")) {
        return false;
    }
    
    String filename = data["filename"];
    String base64Data = data["data"];
    
    // Decode base64 data (simplified - you'd use a proper base64 decoder)
    // For now, just store as-is
    bool success = storage.writeFile(AUDIO_DIR + "/" + filename, 
                                   (const uint8_t*)base64Data.c_str(), 
                                   base64Data.length());
    
    if (success) {
        JsonDocument responseDoc;
        responseDoc["message"] = "File uploaded successfully";
        responseDoc["filename"] = filename;
        _sendResponse("upload_file", true, responseDoc.as<JsonObject>());
        return true;
    }
    
    return false;
}

bool CommandProcessor::handleOTAUpdate(const JsonObject& data) {
    // OTA update implementation would go here
    // This is a complex feature requiring secure download and verification
    
    JsonDocument responseDoc;
    responseDoc["message"] = "OTA update not implemented yet";
    _sendResponse("ota_update", false, responseDoc.as<JsonObject>());
    return false;
}

bool CommandProcessor::handleCalibrateBattery(const JsonObject& data) {
    if (!data.containsKey("calibration_factor")) {
        return false;
    }
    
    float calibration = data["calibration_factor"];
    battery.setCalibration(calibration);
    storage.updateSetting("battery_calibration", String(calibration));
    
    JsonDocument responseDoc;
    responseDoc["message"] = "Battery calibration updated";
    responseDoc["calibration_factor"] = calibration;
    _sendResponse("calibrate_battery", true, responseDoc.as<JsonObject>());
    return true;
}

bool CommandProcessor::handleSetWiFi(const JsonObject& data) {
    if (!data.containsKey("ssid") || !data.containsKey("password")) {
        return false;
    }
    
    String ssid = data["ssid"];
    String password = data["password"];
    
    storage.updateSetting("wifi_ssid", ssid);
    storage.updateSetting("wifi_password", password);
    storage.updateSetting("wifi_enabled", "true");
    
    JsonDocument responseDoc;
    responseDoc["message"] = "WiFi credentials stored";
    _sendResponse("set_wifi", true, responseDoc.as<JsonObject>());
    return true;
}

void CommandProcessor::_sendResponse(const String& command, bool success, const JsonObject& data) {
    if (_responseCallback) {
        _responseCallback(command, success, data);
    }
}

void CommandProcessor::_sendError(const String& command, const String& error) {
    JsonDocument errorDoc;
    errorDoc["error"] = error;
    _sendResponse(command, false, errorDoc.as<JsonObject>());
}

bool CommandProcessor::_validateReminder(const JsonObject& data) {
    return data.containsKey("id") && 
           data.containsKey("title") && 
           data.containsKey("timestamp") && 
           data.containsKey("repeat") && 
           data.containsKey("display_on_oled");
}

bool CommandProcessor::_validateTimestamp(const JsonObject& data) {
    return data.containsKey("timestamp") && data["timestamp"].is<uint32_t>();
}

bool CommandProcessor::_validateMood(const String& mood) {
    return mood == "happy" || mood == "sleepy" || mood == "sad" || mood == "crazy" || mood == "normal";
}

bool CommandProcessor::_validateSoundId(int soundId) {
    return soundId >= 0 && soundId <= 10; // Adjust based on available sounds
}

bool CommandProcessor::_validateProvisionData(const JsonObject& data) {
    return data.containsKey("client_token") && !data["client_token"].as<String>().isEmpty();
}