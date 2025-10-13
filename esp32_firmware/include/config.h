#pragma once

#include <Arduino.h>

// Hardware Configuration
#define OLED_SDA_PIN 21
#define OLED_SCL_PIN 22
#define OLED_RESET_PIN -1

#define RTC_SDA_PIN 21  // Shared with OLED
#define RTC_SCL_PIN 22  // Shared with OLED

#define BATTERY_ADC_PIN 36
#define BUTTON_SNOOZE_PIN 4
#define BUTTON_PAIR_PIN 0

// Audio Configuration
#define AUDIO_USE_I2S true  // Set to false for DAC mode
#define I2S_BCLK_PIN 26
#define I2S_LRC_PIN 25
#define I2S_DIN_PIN 27
#define DAC_PIN 25  // GPIO25 = DAC1

// Microphone Configuration (Optional)
#define MIC_ENABLE false  // Set to true to enable microphone
#define MIC_I2S_SCK_PIN 14
#define MIC_I2S_WS_PIN 15
#define MIC_I2S_SD_PIN 32

// BLE Configuration
#define BLE_DEVICE_NAME "DasaiMochi"
#define BLE_SERVICE_UUID "12345678-1234-1234-1234-123456789abc"
#define BLE_WRITE_CHAR_UUID "12345678-1234-1234-1234-123456789abd"
#define BLE_NOTIFY_CHAR_UUID "12345678-1234-1234-1234-123456789abe"

// Battery Configuration
#define BATTERY_MIN_VOLTAGE 3.2f
#define BATTERY_MAX_VOLTAGE 4.2f
#define BATTERY_CRITICAL_PERCENT 10
#define BATTERY_R1 100000.0f  // 100k resistor
#define BATTERY_R2 100000.0f  // 100k resistor
#define BATTERY_CALIBRATION 1.0f  // Adjust based on actual measurements

// Timing Configuration
#define OLED_UPDATE_INTERVAL 1000
#define BATTERY_CHECK_INTERVAL 30000
#define RTC_SYNC_INTERVAL 3600000  // 1 hour

// File System Paths
#define SETTINGS_FILE "/settings.json"
#define REMINDERS_FILE "/reminders.json"
#define PROVISION_FILE "/provision.json"
#define AUDIO_DIR "/audio"