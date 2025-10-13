# WiFi Configuration for Mochi Device

## Overview
The Mochi app now includes comprehensive WiFi configuration functionality that allows users to configure their Mochi device's WiFi connection through Bluetooth.

## How It Works

### Connection Flow
1. **Bluetooth Connection**: User must first connect to Mochi via Bluetooth
2. **WiFi Configuration**: Once connected via Bluetooth, user can configure WiFi settings
3. **ESP32 Communication**: WiFi credentials are sent to ESP32 via Bluetooth
4. **WiFi Connection**: Mochi connects to the specified WiFi network

### Key Features

#### 📱 **Device Settings Screen**
- **WiFi Status Display**: Shows current WiFi connection status
- **Network Configuration**: SSID and password input fields
- **Network Scanning**: Scan and select from available networks
- **Connection Management**: Connect, disconnect, and reset WiFi

#### 🔧 **Enhanced BLE Service**
- **WiFi Commands**: Configure, scan, status, disconnect, reset
- **Device Settings**: Brightness, volume, power modes, calibration
- **Real-time Communication**: Send commands and receive responses

#### 🛠️ **ESP32 Protocol**
- **WiFi Commands**: 
  - `configure_wifi`: Set SSID and password
  - `scan_wifi`: Scan for available networks
  - `get_wifi_status`: Check connection status
  - `disconnect_wifi`: Disconnect from WiFi
  - `reset_wifi`: Reset WiFi settings

- **Device Settings Commands**:
  - `set_brightness`: Control display brightness
  - `set_volume`: Control audio volume
  - `set_auto_connect`: Configure auto-connection
  - `set_low_power_mode`: Enable/disable power saving
  - `calibrate_sensors`: Recalibrate device sensors
  - `update_firmware`: Update device firmware
  - `factory_reset`: Reset to factory defaults

## Usage Instructions

### WiFi Configuration Steps
1. **Open Device Settings** from the main dashboard
2. **Connect to Mochi** via Bluetooth if not already connected
3. **Configure WiFi**:
   - Enter WiFi network name (SSID)
   - Enter WiFi password
   - Optionally scan for networks to select from list
   - Tap "Connect" to send credentials to Mochi
4. **Monitor Status**: Check WiFi status updates in real-time

### Device Settings Management
- **Brightness & Volume**: Adjust sliders - changes are sent to device instantly
- **Behavior Settings**: Toggle switches - settings are synced with device
- **Advanced Options**:
  - Update firmware
  - Calibrate sensors
  - Factory reset (requires confirmation)

## Technical Implementation

### ESP32 Command Structure
```json
{
  "cmd": "configure_wifi",
  "data": "{\"ssid\":\"NetworkName\",\"password\":\"NetworkPassword\"}",
  "timestamp": "2025-10-13T10:30:00Z"
}
```

### WiFi Status Response
```json
{
  "status": "ok",
  "action": "get_wifi_status",
  "value": "{\"connected\":true,\"ssid\":\"NetworkName\",\"ip\":\"192.168.1.100\"}",
  "timestamp": "2025-10-13T10:30:00Z"
}
```

## Security Features
- **Password Protection**: WiFi passwords are transmitted securely via Bluetooth
- **Connection Validation**: Status checks confirm successful WiFi connection
- **Error Handling**: Comprehensive error messages for troubleshooting

## Troubleshooting

### Common Issues
1. **"Connect to Mochi first"**: Ensure Bluetooth connection is established
2. **"No networks found"**: Check if WiFi is enabled on the device
3. **"WiFi configuration failed"**: Verify SSID and password are correct
4. **Connection timeout**: Ensure Mochi is in range and charged

### Reset Options
- **Disconnect WiFi**: Disconnect from current network
- **Reset WiFi**: Clear all WiFi settings
- **Factory Reset**: Reset entire device to defaults

## Future Enhancements
- **Network Profiles**: Save multiple WiFi configurations
- **WPS Support**: One-touch WiFi setup
- **Hotspot Mode**: Mochi as WiFi access point
- **OTA Updates**: Over-the-air firmware updates via WiFi