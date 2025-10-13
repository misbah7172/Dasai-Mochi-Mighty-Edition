#pragma once

#include <Arduino.h>
#include <NimBLEDevice.h>
#include <ArduinoJson.h>
#include <functional>

class BLEManager {
public:
    typedef std::function<void(const JsonObject&)> CommandCallback;
    typedef std::function<bool(const String&)> AuthCallback;
    
    bool begin();
    void end();
    
    void setCommandCallback(CommandCallback callback);
    void setAuthCallback(AuthCallback callback);
    
    bool sendNotification(const JsonObject& data);
    bool sendResponse(const String& command, bool success, const JsonObject& data = JsonObject());
    
    bool isConnected();
    String getConnectedClientAddress();
    
    void startAdvertising();
    void stopAdvertising();
    
private:
    NimBLEServer* _server = nullptr;
    NimBLEService* _service = nullptr;
    NimBLECharacteristic* _writeChar = nullptr;
    NimBLECharacteristic* _notifyChar = nullptr;
    
    bool _connected = false;
    String _clientAddress;
    CommandCallback _commandCallback;
    AuthCallback _authCallback;
    
    String _receiveBuffer;
    uint16_t _mtu = 23;
    
    void _setupServer();
    void _setupService();
    void _processMessage(const String& message);
    bool _sendChunkedData(const String& data);
    
    class ServerCallbacks;
    class WriteCallbacks;
};