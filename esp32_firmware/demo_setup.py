#!/usr/bin/env python3
"""
Dasai Mochi Factory Demo Content Script

This script uploads demo audio files and sets up initial configuration
for the Dasai Mochi device. Use this after flashing firmware to prepare
the device for demonstration.

Requirements:
- Python 3.6+
- bleak (pip install bleak)
- Device must be in pairing mode

Usage:
python demo_setup.py --device-address <BLE_ADDRESS>
"""

import asyncio
import json
import base64
import argparse
from bleak import BleakClient
import os

# BLE UUIDs
SERVICE_UUID = "12345678-1234-1234-1234-123456789abc"
WRITE_CHAR_UUID = "12345678-1234-1234-1234-123456789abd"
NOTIFY_CHAR_UUID = "12345678-1234-1234-1234-123456789abe"

class DemoSetup:
    def __init__(self, device_address):
        self.device_address = device_address
        self.client = None
        self.auth_token = "demo_client_token_12345"
        
    async def connect(self):
        """Connect to the Dasai Mochi device"""
        print(f"Connecting to {self.device_address}...")
        self.client = BleakClient(self.device_address)
        await self.client.connect()
        print("Connected!")
        
    async def disconnect(self):
        """Disconnect from the device"""
        if self.client:
            await self.client.disconnect()
            print("Disconnected")
            
    async def send_command(self, command, data=None):
        """Send a command to the device"""
        message = {
            "command": command,
            "auth_token": self.auth_token,
            "data": data or {}
        }
        
        json_data = json.dumps(message)
        print(f"Sending: {command}")
        
        await self.client.write_gatt_char(WRITE_CHAR_UUID, json_data.encode())
        
    async def provision_device(self):
        """Provision the device with demo token"""
        print("Provisioning device...")
        await self.send_command("provision", {
            "client_token": self.auth_token
        })
        
    async def sync_time(self):
        """Sync current time to device"""
        import time
        current_time = int(time.time())
        
        print("Syncing time...")
        await self.send_command("sync_time", {
            "timestamp": current_time,
            "timezone": -8  # PST
        })
        
    async def upload_demo_audio(self):
        """Upload demo audio files"""
        audio_files = [
            ("chime_soft.wav", self._generate_demo_wav()),
            ("chime_alert.wav", self._generate_demo_wav()),
            ("reminder_bell.wav", self._generate_demo_wav())
        ]
        
        for filename, wav_data in audio_files:
            print(f"Uploading {filename}...")
            base64_data = base64.b64encode(wav_data).decode()
            
            await self.send_command("upload_file", {
                "filename": filename,
                "data": base64_data
            })
            
    async def add_demo_reminders(self):
        """Add demo reminders"""
        import time
        
        current_time = int(time.time())
        
        reminders = [
            {
                "id": "demo_reminder_1",
                "title": "Demo Reminder 1",
                "timestamp": current_time + 300,  # 5 minutes from now
                "repeat": False,
                "display_on_oled": True
            },
            {
                "id": "demo_reminder_2", 
                "title": "Daily Medicine",
                "timestamp": current_time + 600,  # 10 minutes from now
                "repeat": True,
                "display_on_oled": True
            }
        ]
        
        for reminder in reminders:
            print(f"Adding reminder: {reminder['title']}")
            await self.send_command("add_reminder", reminder)
            
    async def set_demo_mood(self):
        """Set demo mood"""
        print("Setting mood to happy...")
        await self.send_command("set_mood", {
            "mood": "happy"
        })
        
    async def run_demo_setup(self):
        """Run complete demo setup"""
        try:
            await self.connect()
            
            # Setup sequence
            await self.provision_device()
            await asyncio.sleep(1)
            
            await self.sync_time()
            await asyncio.sleep(1)
            
            await self.upload_demo_audio()
            await asyncio.sleep(2)
            
            await self.add_demo_reminders()
            await asyncio.sleep(1)
            
            await self.set_demo_mood()
            await asyncio.sleep(1)
            
            # Test audio
            print("Testing audio playback...")
            await self.send_command("play_sound", {"sound_id": 0})
            
            print("Demo setup complete!")
            
        except Exception as e:
            print(f"Error during demo setup: {e}")
        finally:
            await self.disconnect()
            
    def _generate_demo_wav(self):
        """Generate a simple demo WAV file (sine wave)"""
        # This is a simplified WAV generation
        # In practice, you'd use proper audio files
        
        import struct
        import math
        
        sample_rate = 22050
        duration = 1.0  # 1 second
        frequency = 440  # A note
        
        num_samples = int(sample_rate * duration)
        
        # WAV header
        wav_data = bytearray()
        wav_data.extend(b'RIFF')
        wav_data.extend(struct.pack('<I', 36 + num_samples * 2))
        wav_data.extend(b'WAVE')
        wav_data.extend(b'fmt ')
        wav_data.extend(struct.pack('<I', 16))  # PCM
        wav_data.extend(struct.pack('<H', 1))   # Audio format
        wav_data.extend(struct.pack('<H', 1))   # Channels
        wav_data.extend(struct.pack('<I', sample_rate))
        wav_data.extend(struct.pack('<I', sample_rate * 2))
        wav_data.extend(struct.pack('<H', 2))   # Block align
        wav_data.extend(struct.pack('<H', 16))  # Bits per sample
        wav_data.extend(b'data')
        wav_data.extend(struct.pack('<I', num_samples * 2))
        
        # Audio data
        for i in range(num_samples):
            sample = int(16383 * math.sin(2 * math.pi * frequency * i / sample_rate))
            wav_data.extend(struct.pack('<h', sample))
            
        return bytes(wav_data)

async def main():
    parser = argparse.ArgumentParser(description='Setup demo content for Dasai Mochi')
    parser.add_argument('--device-address', required=True,
                       help='BLE MAC address of the device')
    
    args = parser.parse_args()
    
    demo = DemoSetup(args.device_address)
    await demo.run_demo_setup()

if __name__ == "__main__":
    asyncio.run(main())