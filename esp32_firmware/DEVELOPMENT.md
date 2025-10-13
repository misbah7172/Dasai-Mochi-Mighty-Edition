# Dasai Mochi ESP32 Firmware - Development Notes

## Quick Start

1. **Install PlatformIO**:
   ```bash
   pip install platformio
   ```

2. **Build and Flash**:
   ```bash
   cd esp32_firmware
   pio run --target upload
   ```

3. **Monitor Serial Output**:
   ```bash
   pio device monitor --baud 115200
   ```

## Development Workflow

### Initial Setup
- Flash firmware to ESP32
- Device boots in pairing mode
- Connect with Flutter app or demo script
- Device provisions and ready for use

### Testing Commands
Use the demo script to test BLE functionality:
```bash
python demo_setup.py --device-address <MAC_ADDRESS>
```

### File System Management
- Settings stored in `/settings.json`
- Reminders in `/reminders.json`
- Auth token in `/provision.json`
- Audio files in `/audio/` directory

### Security Notes
- Change default BLE UUIDs for production
- Implement proper base64 decoding for file uploads
- Add signature verification for OTA updates
- Enable BLE bonding/encryption in production

### Performance Optimization
- Adjust watchdog timeout if needed
- Monitor heap usage via serial output
- Optimize audio buffer sizes for better playback
- Consider PSRAM for larger audio files

### Hardware Validation
- Test all I2C devices (OLED, RTC)
- Verify audio output levels
- Calibrate battery voltage readings
- Test button responsiveness

## Known Limitations
- OTA update not fully implemented
- I2S microphone needs full driver implementation
- Base64 decoder simplified for demo
- Audio library may need tuning for specific hardware