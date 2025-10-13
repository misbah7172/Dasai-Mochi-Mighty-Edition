#pragma once

#include <Arduino.h>
#include <ArduinoJson.h>

class CommandProcessor {
public:
    typedef std::function<void(const String&, bool, const JsonObject&)> ResponseCallback;
    
    void setResponseCallback(ResponseCallback callback);
    
    // Command handlers
    void processCommand(const JsonObject& command);
    
    bool handleAddReminder(const JsonObject& data);
    bool handleDeleteReminder(const JsonObject& data);
    bool handleShowReminder(const JsonObject& data);
    bool handleSyncTime(const JsonObject& data);
    bool handleSetMood(const JsonObject& data);
    bool handleRequestStatus(const JsonObject& data);
    bool handlePlaySound(const JsonObject& data);
    bool handleUpdateFace(const JsonObject& data);
    bool handleGetBattery(const JsonObject& data);
    bool handleScheduleAlarm(const JsonObject& data);
    bool handleProvision(const JsonObject& data);
    bool handleUploadFile(const JsonObject& data);
    bool handleOTAUpdate(const JsonObject& data);
    bool handleCalibrateBattery(const JsonObject& data);
    bool handleSetWiFi(const JsonObject& data);
    
private:
    ResponseCallback _responseCallback;
    
    void _sendResponse(const String& command, bool success, const JsonObject& data = JsonObject());
    void _sendError(const String& command, const String& error);
    
    bool _validateReminder(const JsonObject& data);
    bool _validateTimestamp(const JsonObject& data);
    bool _validateMood(const String& mood);
    bool _validateSoundId(int soundId);
    bool _validateProvisionData(const JsonObject& data);
};