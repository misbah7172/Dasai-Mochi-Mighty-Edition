#include "ble_manager.h"
#include "config.h"

class BLEManager::ServerCallbacks : public NimBLEServerCallbacks {
    BLEManager* parent;
public:
    ServerCallbacks(BLEManager* p) : parent(p) {}
    
    void onConnect(NimBLEServer* pServer) {
        Serial.println("BLE Client connected");
        parent->_connected = true;
        parent->_clientAddress = pServer->getPeerInfo(0).getAddress().toString().c_str();
    }
    
    void onDisconnect(NimBLEServer* pServer) {
        Serial.println("BLE Client disconnected");
        parent->_connected = false;
        parent->_clientAddress = "";
        parent->startAdvertising();
    }
    
    void onMTUChange(uint16_t MTU, ble_gap_conn_desc* desc) {
        Serial.printf("MTU updated: %u for connection ID: %u\n", MTU, desc->conn_handle);
        parent->_mtu = MTU;
    }
};

class BLEManager::WriteCallbacks : public NimBLECharacteristicCallbacks {
    BLEManager* parent;
public:
    WriteCallbacks(BLEManager* p) : parent(p) {}
    
    void onWrite(NimBLECharacteristic* pCharacteristic) {
        String value = pCharacteristic->getValue().c_str();
        Serial.printf("Received: %s\n", value.c_str());
        
        // Handle chunked messages
        if (value.startsWith("{\"chunk\":")) {
            JsonDocument chunkDoc;
            deserializeJson(chunkDoc, value);
            
            int chunkIndex = chunkDoc["chunk"]["index"];
            int totalChunks = chunkDoc["chunk"]["total"];
            String data = chunkDoc["chunk"]["data"];
            
            if (chunkIndex == 0) {
                parent->_receiveBuffer = "";
            }
            
            parent->_receiveBuffer += data;
            
            if (chunkIndex == totalChunks - 1) {
                // All chunks received, process complete message
                parent->_processMessage(parent->_receiveBuffer);
                parent->_receiveBuffer = "";
            }
        } else {
            // Single message
            parent->_processMessage(value);
        }
    }
};

bool BLEManager::begin() {
    Serial.println("Initializing BLE...");
    
    NimBLEDevice::init(BLE_DEVICE_NAME);
    NimBLEDevice::setPower(ESP_PWR_LVL_P9);
    
    _setupServer();
    _setupService();
    
    Serial.println("BLE initialized successfully");
    return true;
}

void BLEManager::end() {
    if (_server) {
        _server->getAdvertising()->stop();
        NimBLEDevice::deinit(true);
    }
}

void BLEManager::setCommandCallback(CommandCallback callback) {
    _commandCallback = callback;
}

void BLEManager::setAuthCallback(AuthCallback callback) {
    _authCallback = callback;
}

bool BLEManager::sendNotification(const JsonObject& data) {
    if (!_connected || !_notifyChar) return false;
    
    String jsonString;
    serializeJson(data, jsonString);
    
    return _sendChunkedData(jsonString);
}

bool BLEManager::sendResponse(const String& command, bool success, const JsonObject& data) {
    if (!_connected) return false;
    
    JsonDocument responseDoc;
    responseDoc["command"] = command;
    responseDoc["success"] = success;
    
    if (!data.isNull()) {
        responseDoc["data"] = data;
    }
    
    String jsonString;
    serializeJson(responseDoc, jsonString);
    
    return _sendChunkedData(jsonString);
}

bool BLEManager::isConnected() {
    return _connected;
}

String BLEManager::getConnectedClientAddress() {
    return _clientAddress;
}

void BLEManager::startAdvertising() {
    if (!_server) return;
    
    NimBLEAdvertising* advertising = _server->getAdvertising();
    advertising->addServiceUUID(BLE_SERVICE_UUID);
    advertising->setScanResponse(true);
    advertising->setMinPreferred(0x06);
    advertising->setMaxPreferred(0x12);
    advertising->start();
    
    Serial.println("BLE advertising started");
}

void BLEManager::stopAdvertising() {
    if (!_server) return;
    
    _server->getAdvertising()->stop();
    Serial.println("BLE advertising stopped");
}

void BLEManager::_setupServer() {
    _server = NimBLEDevice::createServer();
    _server->setCallbacks(new ServerCallbacks(this));
}

void BLEManager::_setupService() {
    _service = _server->createService(BLE_SERVICE_UUID);
    
    // Write characteristic (app -> device)
    _writeChar = _service->createCharacteristic(
        BLE_WRITE_CHAR_UUID,
        NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR
    );
    _writeChar->setCallbacks(new WriteCallbacks(this));
    
    // Notify characteristic (device -> app)
    _notifyChar = _service->createCharacteristic(
        BLE_NOTIFY_CHAR_UUID,
        NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY
    );
    
    _service->start();
}

void BLEManager::_processMessage(const String& message) {
    JsonDocument doc;
    DeserializationError error = deserializeJson(doc, message);
    
    if (error) {
        Serial.printf("JSON parse error: %s\n", error.c_str());
        return;
    }
    
    // Check for authentication token
    if (doc.containsKey("auth_token")) {
        String token = doc["auth_token"];
        if (_authCallback && !_authCallback(token)) {
            JsonDocument errorDoc;
            errorDoc["error"] = "Authentication failed";
            sendNotification(errorDoc.as<JsonObject>());
            return;
        }
    } else if (_authCallback) {
        // Authentication required but no token provided
        JsonDocument errorDoc;
        errorDoc["error"] = "Authentication required";
        sendNotification(errorDoc.as<JsonObject>());
        return;
    }
    
    // Process command
    if (_commandCallback) {
        _commandCallback(doc.as<JsonObject>());
    }
}

bool BLEManager::_sendChunkedData(const String& data) {
    if (!_connected || !_notifyChar) return false;
    
    size_t dataLength = data.length();
    size_t maxChunkSize = _mtu - 3; // Account for ATT overhead
    
    if (dataLength <= maxChunkSize) {
        // Send as single message
        _notifyChar->setValue(data.c_str());
        _notifyChar->notify();
        return true;
    }
    
    // Send as chunked message
    int totalChunks = (dataLength + maxChunkSize - 1) / maxChunkSize;
    
    for (int i = 0; i < totalChunks; i++) {
        size_t start = i * maxChunkSize;
        size_t end = min(start + maxChunkSize, dataLength);
        String chunk = data.substring(start, end);
        
        JsonDocument chunkDoc;
        chunkDoc["chunk"]["index"] = i;
        chunkDoc["chunk"]["total"] = totalChunks;
        chunkDoc["chunk"]["data"] = chunk;
        
        String chunkJson;
        serializeJson(chunkDoc, chunkJson);
        
        _notifyChar->setValue(chunkJson.c_str());
        _notifyChar->notify();
        
        delay(10); // Small delay between chunks
    }
    
    return true;
}