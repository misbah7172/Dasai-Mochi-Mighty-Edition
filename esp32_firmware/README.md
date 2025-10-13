# Dasai Mochi ESP32 Firmware

Production-ready firmware for the Dasai Mochi smart assistant device, designed to work seamlessly with the Flutter mobile application.

## Hardware Requirements

### Core Components
- **ESP32 DevKit**: Main microcontroller
- **SSD1306 OLED**: 128x64 I²C display for UI and notifications
- **DS3231 RTC**: Real-time clock module for accurate timekeeping and alarms
- **PAM8403 Amplifier**: Audio amplification for speakers
- **TP4056**: Battery charging module
- **Li-ion Battery**: 3.7V rechargeable battery

### Optional Components
- **INMP441**: I²S microphone for voice input
- **Speaker**: 4-8Ω speaker for audio output

## Wiring Diagram

```
ESP32 Pin Connections:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

I²C Bus (SSD1306 OLED + DS3231 RTC):
├─ GPIO 21 (SDA) ──┬── SSD1306 SDA ──┬── DS3231 SDA
├─ GPIO 22 (SCL) ──┼── SSD1306 SCL ──┼── DS3231 SCL
├─ 3.3V ───────────┼── SSD1306 VCC ──┼── DS3231 VCC
└─ GND ────────────┼── SSD1306 GND ──┼── DS3231 GND

Audio Output (I²S to PAM8403):
├─ GPIO 26 (I2S_BCLK) ── PAM8403 BCLK
├─ GPIO 25 (I2S_LRC)  ── PAM8403 LRC
├─ GPIO 27 (I2S_DIN)  ── PAM8403 DIN
└─ GND ──────────────── PAM8403 GND

Audio Input (Optional INMP441):
├─ GPIO 14 (I2S_SCK) ── INMP441 SCK
├─ GPIO 15 (I2S_WS)  ── INMP441 WS
├─ GPIO 32 (I2S_SD)  ── INMP441 SD
├─ 3.3V ─────────────── INMP441 VDD
└─ GND ──────────────── INMP441 GND

Battery Monitoring:
├─ GPIO 36 (ADC) ── Battery Voltage Divider
│   Battery+ ──[100kΩ]── GPIO 36 ──[100kΩ]── GND
│
├─ Battery+ ── TP4056 BATT+
├─ Battery- ── TP4056 BATT-
├─ 5V USB ── TP4056 VIN
└─ GND ──── TP4056 GND

User Input:
├─ GPIO 4 ── Snooze Button ── GND (with internal pullup)
└─ GPIO 0 ── Pair/Reset Button ── GND (with internal pullup)

Power Supply:
├─ TP4056 OUT+ ── ESP32 VIN (or 5V pin)
└─ TP4056 OUT- ── ESP32 GND
```

## BLE Protocol

### Service & Characteristics
- **Service UUID**: `12345678-1234-1234-1234-123456789abc`
- **Write Characteristic**: `12345678-1234-1234-1234-123456789abd` (App → Device)
- **Notify Characteristic**: `12345678-1234-1234-1234-123456789abe` (Device → App)

### Message Format
All messages use JSON format with optional chunking for large payloads.

#### Basic Command Structure
```json
{
  "command": "command_name",
  "auth_token": "client_authentication_token",
  "data": {
    // Command-specific data
  }
}
```

#### Response Structure
```json
{
  "command": "original_command",
  "success": true/false,
  "data": {
    // Response data
  }
}
```

### Supported Commands

#### Device Management
```json
// Provision device (first-time setup)
{
  "command": "provision",
  "data": {
    "client_token": "unique_client_identifier"
  }
}

// Request device status
{
  "command": "request_status",
  "auth_token": "token",
  "data": {}
}

// Get battery information
{
  "command": "get_battery",
  "auth_token": "token",
  "data": {}
}
```

#### Time Management
```json
// Synchronize time
{
  "command": "sync_time",
  "auth_token": "token",
  "data": {
    "timestamp": 1697097600,
    "timezone": -8
  }
}
```

#### Reminder Management
```json
// Add reminder
{
  "command": "add_reminder",
  "auth_token": "token",
  "data": {
    "id": "reminder_123",
    "title": "Take medicine",
    "timestamp": 1697097600,
    "repeat": false,
    "display_on_oled": true
  }
}

// Delete reminder
{
  "command": "delete_reminder",
  "auth_token": "token",
  "data": {
    "id": "reminder_123"
  }
}

// Show specific reminder
{
  "command": "show_reminder",
  "auth_token": "token",
  "data": {
    "id": "reminder_123"
  }
}
```

#### Mood & Display
```json
// Set Mochi mood
{
  "command": "set_mood",
  "auth_token": "token",
  "data": {
    "mood": "happy" // "happy", "sleepy", "sad", "crazy", "normal"
  }
}

// Update face display
{
  "command": "update_face",
  "auth_token": "token",
  "data": {
    "face_name": "happy"
  }
}
```

#### Audio Control
```json
// Play sound
{
  "command": "play_sound",
  "auth_token": "token",
  "data": {
    "sound_id": 1 // 0-10 for built-in sounds
  }
}

// Upload audio file
{
  "command": "upload_file",
  "auth_token": "token",
  "data": {
    "filename": "custom_chime.wav",
    "data": "base64_encoded_wav_data"
  }
}
```

#### Network Configuration
```json
// Configure WiFi (stored securely)
{
  "command": "set_wifi",
  "auth_token": "token",
  "data": {
    "ssid": "YourWiFiNetwork",
    "password": "YourWiFiPassword"
  }
}
```

#### Device Calibration
```json
// Calibrate battery readings
{
  "command": "calibrate_battery",
  "auth_token": "token",
  "data": {
    "calibration_factor": 1.05
  }
}
```

## Provisioning Flow

### Initial Pairing
1. **Device boots unpaired**: Shows "Pairing Mode" on OLED, starts BLE advertising
2. **App discovers device**: Connects to BLE service
3. **App sends provision command**: Includes generated client token
4. **Device stores token**: Saves to LittleFS, confirms pairing
5. **Secure connection established**: All future commands require this token

### Security Notes
- Device only accepts one client token (first-come-first-served)
- Factory reset (long-press pair button) clears stored token
- All sensitive data encrypted in storage
- BLE bonding recommended for production use

## Development Setup

### Building the Firmware
```bash
# Clone project
git clone <repository_url>
cd esp32_firmware

# Install PlatformIO
pip install platformio

# Build firmware
pio run

# Upload to device
pio run --target upload

# Monitor serial output
pio device monitor
```

### Configuration Options

#### WiFi Setup (Optional)
Modify `platformio.ini` to enable WiFi features:
```ini
build_flags = 
    -DWIFI_ENABLED=true
    ; WiFi credentials can be set via BLE or hardcoded for testing
    ; -DWIFI_SSID=\"YourTestNetwork\"
    ; -DWIFI_PASSWORD=\"YourTestPassword\"
```

#### Audio Configuration
Choose audio output method in `config.h`:
```cpp
#define AUDIO_USE_I2S true  // false for simple DAC output
```

#### Microphone Enable
Enable voice input in `config.h`:
```cpp
#define MIC_ENABLE true
```

### File System Structure
```
/
├── settings.json      # Device configuration
├── reminders.json     # Stored reminders
├── provision.json     # Authentication token
└── audio/
    ├── boot_chime.wav
    ├── reminder_bell.wav
    ├── low_battery.wav
    └── custom_sounds/
```

## Production Deployment

### Security Checklist
- [ ] Enable BLE bonding/encryption
- [ ] Use secure bootloader
- [ ] Enable flash encryption
- [ ] Implement OTA signature verification
- [ ] Remove debug serial output
- [ ] Set production log levels

### Manufacturing Configuration
1. **Flash firmware** with production build
2. **Verify hardware** connections and functionality  
3. **Test BLE pairing** with mobile app
4. **Calibrate battery** monitoring with known voltages
5. **Quality test** all features (display, audio, RTC, etc.)

### Troubleshooting

#### Common Issues
- **OLED not displaying**: Check I²C connections and address (0x3C)
- **RTC time loss**: Verify DS3231 battery and connections
- **Audio distortion**: Check PAM8403 wiring and power supply
- **BLE connection fails**: Verify device not already paired
- **Battery readings incorrect**: Calibrate voltage divider resistors

#### Debug Commands
```bash
# View serial output
pio device monitor --baud 115200

# Check file system
# Connect via BLE and send: {"command": "request_status"}

# Factory reset
# Long-press pair button (GPIO 0) for 3+ seconds
```

## API Integration

The firmware is designed to work with the companion Flutter app. Key integration points:

### App → Device Communication
- Send commands via BLE Write characteristic
- Receive responses via BLE Notify characteristic
- Handle authentication with stored client tokens
- Support for chunked message transfer

### Device → App Notifications
- Alarm/reminder triggers
- Battery low warnings
- System status updates
- Error notifications

## License
This firmware is designed for the Dasai Mochi project and includes production-ready features for commercial deployment.

## Support
For technical support or bug reports, please refer to the project documentation or contact the development team.