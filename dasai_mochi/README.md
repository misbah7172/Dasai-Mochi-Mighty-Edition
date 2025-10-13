# 🍡 Dasai Mochi - Smart Cute Assistant App

A delightful Flutter mobile app that pairs with an ESP32-based Mochi device via Bluetooth Low Energy (BLE). Featuring a childish, crazy, but clean and minimal design with pastel colors, bubbly animations, and a friendly AI companion.

## ✨ Features

### 🎤 Voice Command
- Floating circular microphone button
- Speech-to-text conversion using device API
- Real-time command processing
- ESP32 communication via JSON packets
- Voice feedback with customizable Mochi voices

### ⏰ Clock & Reminder System
- Real-time clock synchronization with ESP32
- Create, edit, and delete reminders
- Local notifications with sound and vibration
- Mochi device OLED display integration
- Cute scrollable reminder cards

### 📱 Dashboard
- Current time and date display
- Mochi connection status indicator
- ESP32 battery level monitoring
- Weather information (location-based)
- Animated Mochi character with expressions:
  - 😄 Happy when connected
  - 😴 Sleepy at night
  - 😳 Shocked on low battery
  - 🤭 Laughing during interaction

### 💬 Mood & Chat
- Lightweight AI chatbox
- Mood selection: Happy, Sleepy, Sad, Crazy
- Dynamic color themes based on mood
- Animated character responses

### ⚙️ Settings
- Voice customization (default, robotic, funny, baby)
- Pastel theme color selection
- Language support (English + Bangla)
- Sound effects and animation toggles

### 🎉 Special Features
- **Festival Mode**: Special themes for Dasai and other festivals
- **Pet Mode**: Random "Feed me" or "Play with me" notifications
- Daily motivational quotes from Mochi
- No authentication required - simple user data collection

## 🎨 Design Guidelines

### Color Palette
- **Baby Blue**: `#B8E6E6`
- **Soft Pink**: `#F7C6D2`
- **Mint Green**: `#B8F2B8`
- **Peach Orange**: `#FFD6B8`
- **Lavender**: `#E1C6FF`
- **Lemon Yellow**: `#FFF2B8`

### Typography
- **Font**: Poppins (via Google Fonts)
- **Style**: Rounded, friendly, clean
- **Sizes**: Responsive across Android and iOS

### Animations
- Lottie animations for Mochi character
- Smooth micro-interactions
- Bounce effects on button presses
- Soft transitions between screens
- Rounded corners (2xl+) everywhere

## 🔧 Technical Architecture

### State Management
- **Provider** for dependency injection and state management
- **Hive** for local data persistence
- **SharedPreferences** for app settings

### Services
- **BLE Service**: ESP32 communication via flutter_blue_plus
- **Voice Service**: Speech recognition and TTS
- **Local Storage Service**: Hive-based data management
- **Notification Service**: Awesome Notifications integration

### Models
- **User**: Profile and preferences
- **Reminder**: Task management
- **ChatMessage**: Conversation history
- **MochiDevice**: ESP32 device state
- **ESP32Protocol**: Communication commands

## 📡 ESP32 Communication Protocol

### Commands (App → ESP32)
```json
{
  "cmd": "action_name",
  "data": "optional_value",
  "timestamp": "2023-10-12T10:30:00Z"
}
```

### Responses (ESP32 → App)
```json
{
  "status": "ok",
  "action": "action_name", 
  "value": "optional_value",
  "timestamp": "2023-10-12T10:30:00Z"
}
```

### Available Commands
- `show_time`: Display current time
- `show_reminder`: Show reminder on OLED
- `show_mood`: Change Mochi's mood
- `update_face`: Update character expression
- `get_battery`: Request battery level
- `heartbeat`: Connection keep-alive

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.9.2)
- Android Studio / VS Code
- Android device with BLE support
- ESP32 Mochi device (optional for testing)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd dasai_mochi
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Configure environment**
   ```bash
   cp .env.example .env
   # Edit .env with your API keys
   ```

5. **Run the app**
   ```bash
   flutter run
   ```

### Environment Variables

**IMPORTANT SECURITY NOTE:** Never commit your `.env` file to version control!

1. **Copy the environment template:**
   ```bash
   cp .env.example .env
   ```

2. **Configure your API keys in `.env`:**
   ```env
   # Weather API (OpenWeatherMap) - Get free key from: https://openweathermap.org/api
   WEATHER_API_KEY=your_actual_openweathermap_api_key_here
   
   # Firebase Configuration - Get from Firebase Console
   FIREBASE_API_KEY=your_actual_firebase_key_here
   FIREBASE_PROJECT_ID=your_firebase_project_id
   
   # OpenAI API (for AI features) - Get from: https://platform.openai.com/api-keys
   OPENAI_API_KEY=your_actual_openai_key_here
   
   # Google Maps (for location features) - Get from Google Cloud Console
   GOOGLE_MAPS_API_KEY=your_actual_maps_key_here
   
   # App Configuration
   APP_VERSION=1.0.0
   DEBUG_MODE=true
   ```

3. **Required API Keys:**
   - **OpenWeatherMap API** (Free): For weather functionality
   - **Firebase** (Free tier available): For cloud storage and authentication
   - **OpenAI API** (Paid): For AI chat features
   - **Google Maps API** (Free tier available): For location services

4. **Security Best Practices:**
   - The `.env` file is already excluded in `.gitignore`
   - Never commit API keys to version control
   - Use different keys for development and production
   - Regularly rotate your API keys
   - Keep your keys secure and don't share them

## 📁 Project Structure

```
lib/
├── components/          # Reusable UI components
│   └── mochi_widgets.dart
├── models/             # Data models
│   ├── user.dart
│   ├── reminder.dart
│   ├── chat_message.dart
│   ├── mochi_device.dart
│   └── esp32_protocol.dart
├── screens/            # App screens
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── main_screen.dart
│   └── settings_screen.dart
├── services/           # Business logic
│   ├── ble_service.dart
│   ├── voice_service.dart
│   └── local_storage_service.dart
├── utils/              # Utilities and themes
│   └── theme.dart
└── main.dart          # App entry point

assets/
├── animations/         # Lottie animations
├── images/            # Static images
├── sounds/            # Sound effects
└── fonts/             # Custom fonts
```

## 🔧 Development

### Code Style
- Use environment variables for all API keys
- Keep credentials secure with .gitignore
- Clear comments above functions only
- Modular and production-ready code
- Follow Flutter/Dart conventions

### Testing
```bash
# Run tests
flutter test

# Run with coverage
flutter test --coverage

# Build APK
flutter build apk --release
```

### Code Generation
```bash
# Generate Hive adapters
flutter packages pub run build_runner build

# Watch for changes
flutter packages pub run build_runner watch
```

## 📱 Platform Support

- **Android**: API 21+ (Android 5.0+)
- **iOS**: iOS 12.0+
- **Permissions**: Bluetooth, Microphone, Notifications, Location

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Google Fonts for Poppins typography
- Lottie for smooth animations
- ESP32 community for hardware inspiration

---

Made with 💕 by the Dasai Mochi Team

*"Your cute AI companion for a smarter, happier life!"* 🍡✨
