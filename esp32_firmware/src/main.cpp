#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <esp_task_wdt.h>

#include "config.h"
#include "storage_manager.h"
#include "ble_manager.h"
#include "display_manager.h"
#include "time_manager.h"
#include "audio_manager.h"
#include "battery_manager.h"
#include "input_manager.h"
#include "command_processor.h"

// Global managers
StorageManager storage;
BLEManager bleManager;
DisplayManager display;
TimeManager timeManager;
AudioManager audio;
BatteryManager battery;
InputManager input;
CommandProcessor commandProcessor;

// Global state
bool systemInitialized = false;
unsigned long lastHeartbeat = 0;
unsigned long lastDisplayUpdate = 0;

void setup() {
    Serial.begin(115200);
    Serial.println("Dasai Mochi ESP32 Firmware Starting...");
    
    // Enable watchdog timer
    esp_task_wdt_init(30, true);
    esp_task_wdt_add(NULL);
    
    // Initialize I2C
    Wire.begin(OLED_SDA_PIN, OLED_SCL_PIN);
    Wire.setClock(400000);
    
    // Initialize storage first
    if (!storage.begin()) {
        Serial.println("ERROR: Storage initialization failed!");
        while(1) delay(1000);
    }
    
    // Initialize display
    if (!display.begin()) {
        Serial.println("ERROR: Display initialization failed!");
        while(1) delay(1000);
    }
    
    display.showMessage("Dasai Mochi", "Initializing...");
    
    // Initialize time manager
    if (!timeManager.begin()) {
        Serial.println("WARNING: RTC initialization failed!");
        display.showMessage("Warning", "RTC not found");
        delay(2000);
    }
    
    // Initialize audio
    if (!audio.begin()) {
        Serial.println("WARNING: Audio initialization failed!");
    } else {
        audio.playBootChime();
    }
    
    // Initialize battery manager
    if (!battery.begin()) {
        Serial.println("WARNING: Battery manager initialization failed!");
    }
    
    // Initialize input manager
    if (!input.begin()) {
        Serial.println("WARNING: Input manager initialization failed!");
    }
    
    // Setup callbacks
    setupCallbacks();
    
    // Initialize BLE
    if (!bleManager.begin()) {
        Serial.println("ERROR: BLE initialization failed!");
        display.showMessage("Error", "BLE Failed");
        while(1) delay(1000);
    }
    
    // Check if device is provisioned
    if (!storage.isProvisioned()) {
        Serial.println("Device not provisioned - waiting for pairing...");
        display.showMessage("Pairing Mode", "Connect with app");
        bleManager.startAdvertising();
    } else {
        Serial.println("Device provisioned - ready for connections");
        display.showTimeView();
        bleManager.startAdvertising();
    }
    
    systemInitialized = true;
    Serial.println("System initialization complete!");
}

void loop() {
    // Feed watchdog
    esp_task_wdt_reset();
    
    if (!systemInitialized) {
        delay(100);
        return;
    }
    
    // Update all managers
    timeManager.update();
    audio.update();
    battery.update();
    input.update();
    
    // Update display
    unsigned long now = millis();
    if (now - lastDisplayUpdate >= OLED_UPDATE_INTERVAL) {
        display.update();
        lastDisplayUpdate = now;
    }
    
    // Heartbeat
    if (now - lastHeartbeat >= 30000) { // 30 seconds
        Serial.printf("Heartbeat - Free heap: %d bytes\n", ESP.getFreeHeap());
        lastHeartbeat = now;
    }
    
    delay(10); // Small delay to prevent watchdog issues
}

void setupCallbacks() {
    // BLE command callback
    bleManager.setCommandCallback([](const JsonObject& command) {
        commandProcessor.processCommand(command);
    });
    
    // BLE authentication callback
    bleManager.setAuthCallback([](const String& token) -> bool {
        if (!storage.isProvisioned()) {
            // First time pairing - accept any token and store it
            storage.setClientToken(token);
            Serial.println("Device provisioned with new token");
            display.showMessage("Paired!", "Connection secure");
            audio.playBootChime();
            return true;
        } else {
            // Check against stored token
            return (storage.getClientToken() == token);
        }
    });
    
    // Command processor response callback
    commandProcessor.setResponseCallback([](const String& command, bool success, const JsonObject& data) {
        bleManager.sendResponse(command, success, data);
    });
    
    // Time manager alarm callback
    timeManager.setAlarmCallback([](const Reminder& reminder) {
        Serial.printf("Alarm triggered: %s\n", reminder.title.c_str());
        
        // Show reminder on display
        if (reminder.displayOnOled) {
            display.showMessage("Reminder", reminder.title);
        }
        
        // Play reminder sound
        audio.playReminderChime();
        
        // Notify app via BLE
        if (bleManager.isConnected()) {
            JsonDocument doc;
            doc["type"] = "alarm_triggered";
            doc["reminder_id"] = reminder.id;
            doc["title"] = reminder.title;
            bleManager.sendNotification(doc.as<JsonObject>());
        }
    });
    
    // Battery callback
    battery.setBatteryCallback([](int percentage) {
        if (percentage <= BATTERY_CRITICAL_PERCENT) {
            Serial.printf("Critical battery level: %d%%\n", percentage);
            display.showBatteryLow(percentage);
            audio.playLowBatteryAlert();
            
            // Notify app
            if (bleManager.isConnected()) {
                JsonDocument doc;
                doc["status"] = "ok";
                doc["action"] = "low_battery";
                doc["value"]["percent"] = percentage;
                bleManager.sendNotification(doc.as<JsonObject>());
            }
        }
    });
    
    // Input callbacks
    input.setSnoozeCallback([]() {
        Serial.println("Snooze button pressed");
        // Handle snooze logic here
        display.showMessage("Snoozed", "5 minutes");
    });
    
    input.setPairCallback([]() {
        Serial.println("Pair button long pressed - factory reset");
        
        // Clear all stored data
        storage.deleteFile(PROVISION_FILE);
        storage.deleteFile(SETTINGS_FILE);
        storage.deleteFile(REMINDERS_FILE);
        
        display.showMessage("Reset", "Restarting...");
        delay(2000);
        ESP.restart();
    });
    
    // Audio playback callback
    audio.setPlaybackCallback([]() {
        Serial.println("Audio playback completed");
    });
}