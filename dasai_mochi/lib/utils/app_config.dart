import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration helper class to manage environment variables
/// This class provides type-safe access to all environment variables
/// defined in the .env file with proper fallbacks and validation.
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();
  
  /// Initialize configuration by loading environment variables
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (e) {
      throw Exception('Failed to load environment configuration: $e');
    }
  }
  
  // ============ WEATHER CONFIGURATION ============
  
  /// OpenWeatherMap API key for weather services
  static String get weatherApiKey => 
      _getRequired('WEATHER_API_KEY', 'Weather API key is required for weather functionality');
  
  /// Weather API base URL
  static String get weatherBaseUrl => 
      _getOptional('WEATHER_BASE_URL', 'https://api.openweathermap.org/data/2.5');
  
  /// Weather units (metric, imperial, kelvin)
  static String get weatherUnits => 
      _getOptional('WEATHER_UNITS', 'metric');
  
  /// Weather language code
  static String get weatherLanguage => 
      _getOptional('WEATHER_LANGUAGE', 'en');
  
  // ============ AI/ML CONFIGURATION ============
  
  /// OpenAI API key for AI chat features
  static String? get openAiApiKey => 
      _getOptional('OPENAI_API_KEY');
  
  /// OpenAI base URL
  static String get openAiBaseUrl => 
      _getOptional('OPENAI_BASE_URL', 'https://api.openai.com/v1');
  
  /// OpenAI model to use
  static String get openAiModel => 
      _getOptional('OPENAI_MODEL', 'gpt-3.5-turbo');
  
  // ============ FIREBASE CONFIGURATION ============
  
  /// Firebase API key
  static String? get firebaseApiKey => 
      _getOptional('FIREBASE_API_KEY');
  
  /// Firebase project ID
  static String? get firebaseProjectId => 
      _getOptional('FIREBASE_PROJECT_ID');
  
  /// Firebase storage bucket
  static String? get firebaseStorageBucket => 
      _getOptional('FIREBASE_STORAGE_BUCKET');
  
  /// Firebase messaging sender ID
  static String? get firebaseMessagingSenderId => 
      _getOptional('FIREBASE_MESSAGING_SENDER_ID');
  
  /// Firebase app ID
  static String? get firebaseAppId => 
      _getOptional('FIREBASE_APP_ID');
  
  // ============ GOOGLE SERVICES ============
  
  /// Google Maps API key
  static String? get googleMapsApiKey => 
      _getOptional('GOOGLE_MAPS_API_KEY');
  
  /// Google Places API key
  static String? get googlePlacesApiKey => 
      _getOptional('GOOGLE_PLACES_API_KEY');
  
  // ============ ESP32 CONFIGURATION ============
  
  /// ESP32 BLE service UUID
  static String get esp32ServiceUuid => 
      _getOptional('ESP32_SERVICE_UUID', '12345678-1234-1234-1234-123456789abc');
  
  /// ESP32 BLE write characteristic UUID
  static String get esp32WriteCharUuid => 
      _getOptional('ESP32_WRITE_CHAR_UUID', '12345678-1234-1234-1234-123456789abd');
  
  /// ESP32 BLE notify characteristic UUID
  static String get esp32NotifyCharUuid => 
      _getOptional('ESP32_NOTIFY_CHAR_UUID', '12345678-1234-1234-1234-123456789abe');
  
  /// Default ESP32 device name
  static String get esp32DefaultName => 
      _getOptional('ESP32_DEFAULT_NAME', 'DasaiMochi');
  
  // ============ AUDIO SERVICES ============
  
  /// Spotify client ID
  static String? get spotifyClientId => 
      _getOptional('SPOTIFY_CLIENT_ID');
  
  /// Spotify client secret
  static String? get spotifyClientSecret => 
      _getOptional('SPOTIFY_CLIENT_SECRET');
  
  /// YouTube API key
  static String? get youtubeApiKey => 
      _getOptional('YOUTUBE_API_KEY');
  
  // ============ BACKEND API CONFIGURATION ============
  
  /// Backend API base URL
  static String? get apiBaseUrl => 
      _getOptional('API_BASE_URL');
  
  /// API version
  static String get apiVersion => 
      _getOptional('API_VERSION', 'v1');
  
  /// API request timeout in milliseconds
  static int get apiTimeout => 
      int.tryParse(_getOptional('API_TIMEOUT', '30000')) ?? 30000;
  
  // ============ APP CONFIGURATION ============
  
  /// Application name
  static String get appName => 
      _getOptional('APP_NAME', 'Dasai Mochi');
  
  /// Application version
  static String get appVersion => 
      _getOptional('APP_VERSION', '1.0.0');
  
  /// Application environment (development, staging, production)
  static String get appEnvironment => 
      _getOptional('APP_ENVIRONMENT', 'development');
  
  /// Debug mode flag
  static bool get debugMode => 
      _getOptional('DEBUG_MODE', 'false').toLowerCase() == 'true';
  
  /// Log level
  static String get logLevel => 
      _getOptional('LOG_LEVEL', 'info');
  
  // ============ SECURITY CONFIGURATION ============
  
  /// Encryption key for local storage
  static String? get encryptionKey => 
      _getOptional('ENCRYPTION_KEY');
  
  /// Hash salt for sensitive data
  static String? get hashSalt => 
      _getOptional('HASH_SALT');
  
  // ============ NOTIFICATION CONFIGURATION ============
  
  /// OneSignal app ID
  static String? get oneSignalAppId => 
      _getOptional('ONESIGNAL_APP_ID');
  
  /// FCM server key
  static String? get fcmServerKey => 
      _getOptional('FCM_SERVER_KEY');
  
  // ============ ANALYTICS ============
  
  /// Google Analytics tracking ID
  static String? get googleAnalyticsTrackingId => 
      _getOptional('GOOGLE_ANALYTICS_TRACKING_ID');
  
  /// Mixpanel token
  static String? get mixpanelToken => 
      _getOptional('MIXPANEL_TOKEN');
  
  /// Sentry DSN for error tracking
  static String? get sentryDsn => 
      _getOptional('SENTRY_DSN');
  
  // ============ HELPER METHODS ============
  
  /// Get required environment variable or throw exception
  static String _getRequired(String key, String errorMessage) {
    final value = dotenv.env[key];
    if (value == null || value.isEmpty) {
      throw Exception(errorMessage);
    }
    return value;
  }
  
  /// Get optional environment variable with fallback
  static String _getOptional(String key, [String? fallback]) {
    return dotenv.env[key] ?? fallback ?? '';
  }
  
  /// Check if a configuration key exists and is not empty
  static bool hasConfig(String key) {
    final value = dotenv.env[key];
    return value != null && value.isNotEmpty;
  }
  
  /// Get all environment variables (for debugging - remove in production)
  static Map<String, String> getAllConfig() {
    if (!debugMode) {
      throw Exception('Config dump only available in debug mode');
    }
    return Map.from(dotenv.env)
      ..removeWhere((key, value) => 
          key.toUpperCase().contains('KEY') || 
          key.toUpperCase().contains('SECRET') ||
          key.toUpperCase().contains('TOKEN'));
  }
  
  /// Validate required configurations
  static List<String> validateConfig() {
    final errors = <String>[];
    
    // Check required configurations
    try {
      weatherApiKey;
    } catch (e) {
      errors.add('Weather API key is missing');
    }
    
    // Add more validation as needed
    if (appEnvironment == 'production' && debugMode) {
      errors.add('Debug mode should be disabled in production');
    }
    
    return errors;
  }
}

/// Configuration validation result
class ConfigValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  
  const ConfigValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
  
  @override
  String toString() {
    if (isValid) {
      return 'Configuration is valid';
    } else {
      return 'Configuration errors:\n${errors.join('\n')}';
    }
  }
}