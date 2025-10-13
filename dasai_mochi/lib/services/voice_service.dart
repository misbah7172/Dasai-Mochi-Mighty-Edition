import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  
  bool _isListening = false;
  bool _isInitialized = false;
  bool _speechEnabled = false;
  String _recognizedText = '';
  String _currentLocale = 'en_US';
  double _confidence = 0.0;
  
  // Voice settings
  String _selectedVoice = 'default';
  double _speechRate = 0.5;
  double _volume = 0.8;
  double _pitch = 1.0;
  
  // Available voice types for Mochi
  final Map<String, Map<String, dynamic>> _voiceProfiles = {
    'default': {
      'rate': 0.5,
      'pitch': 1.0,
      'volume': 0.8,
      'description': 'Normal friendly voice',
    },
    'robotic': {
      'rate': 0.3,
      'pitch': 0.8,
      'volume': 0.9,
      'description': 'Cool robotic voice',
    },
    'funny': {
      'rate': 0.7,
      'pitch': 1.3,
      'volume': 0.9,
      'description': 'High-pitched funny voice',
    },
    'baby': {
      'rate': 0.4,
      'pitch': 1.5,
      'volume': 0.7,
      'description': 'Cute baby voice',
    },
  };
  
  // Stream controllers
  final _voiceCommandController = StreamController<String>.broadcast();
  final _listeningStateController = StreamController<bool>.broadcast();
  
  // Getters
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  bool get speechEnabled => _speechEnabled;
  String get recognizedText => _recognizedText;
  double get confidence => _confidence;
  String get selectedVoice => _selectedVoice;
  Map<String, Map<String, dynamic>> get voiceProfiles => _voiceProfiles;
  
  Stream<String> get voiceCommandStream => _voiceCommandController.stream;
  Stream<bool> get listeningStateStream => _listeningStateController.stream;

  VoiceService() {
    _initialize();
  }

  /// Initialize speech recognition and TTS
  Future<void> _initialize() async {
    try {
      // Request microphone permission
      final micPermission = await Permission.microphone.request();
      if (micPermission != PermissionStatus.granted) {
        debugPrint("Voice: Microphone permission denied");
        return;
      }

      // Initialize Speech-to-Text
      _speechEnabled = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: _onSpeechError,
      );

      // Initialize Text-to-Speech
      await _initializeTTS();
      
      _isInitialized = true;
      notifyListeners();
      
      debugPrint("Voice: Service initialized successfully");
    } catch (e) {
      debugPrint("Voice: Initialization error: $e");
    }
  }

  /// Initialize TTS settings
  Future<void> _initializeTTS() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(_volume);
      await _tts.setPitch(_pitch);
      
      // Set completion handler
      _tts.setCompletionHandler(() {
        debugPrint("Voice: TTS completed");
      });
      
      _tts.setErrorHandler((msg) {
        debugPrint("Voice: TTS error: $msg");
      });
    } catch (e) {
      debugPrint("Voice: TTS initialization error: $e");
    }
  }

  /// Start listening for voice commands
  Future<void> startListening() async {
    if (!_isInitialized || !_speechEnabled || _isListening) {
      return;
    }

    try {
      _isListening = true;
      _recognizedText = '';
      _listeningStateController.add(true);
      notifyListeners();

      await _speech.listen(
        onResult: _onSpeechResult,
        localeId: _currentLocale,
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        cancelOnError: true,
      );
      
      debugPrint("Voice: Started listening");
    } catch (e) {
      debugPrint("Voice: Start listening error: $e");
      _stopListening();
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _stopListening();
  }

  Future<void> _stopListening() async {
    if (!_isListening) return;
    
    try {
      await _speech.stop();
      _isListening = false;
      _listeningStateController.add(false);
      notifyListeners();
      
      debugPrint("Voice: Stopped listening");
    } catch (e) {
      debugPrint("Voice: Stop listening error: $e");
    }
  }

  /// Handle speech recognition results
  void _onSpeechResult(result) {
    _recognizedText = result.recognizedWords;
    _confidence = result.confidence;
    
    debugPrint("Voice: Recognized: $_recognizedText (${(_confidence * 100).toStringAsFixed(1)}%)");
    
    // If result is final and confidence is good
    if (result.finalResult && _confidence > 0.5) {
      _processVoiceCommand(_recognizedText);
    }
    
    notifyListeners();
  }

  /// Handle speech recognition status changes
  void _onSpeechStatus(String status) {
    debugPrint("Voice: Status: $status");
    
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _listeningStateController.add(false);
      notifyListeners();
    }
  }

  /// Handle speech recognition errors
  void _onSpeechError(error) {
    debugPrint("Voice: Error: $error");
    _stopListening();
  }

  /// Process voice command and extract meaningful actions
  void _processVoiceCommand(String command) {
    final normalizedCommand = command.toLowerCase().trim();
    
    // Emit the command to listeners
    _voiceCommandController.add(normalizedCommand);
    
    // Provide feedback
    _speakMochiResponse(_generateMochiResponse(normalizedCommand));
  }

  /// Generate appropriate Mochi response based on command
  String _generateMochiResponse(String command) {
    if (command.contains('time') || command.contains('clock')) {
      return "Let me show you the time!";
    } else if (command.contains('reminder') || command.contains('remind')) {
      return "I'll help you set a reminder!";
    } else if (command.contains('hello') || command.contains('hi')) {
      return "Hello there! How can I help you today?";
    } else if (command.contains('weather')) {
      return "Let me check the weather for you!";
    } else if (command.contains('battery')) {
      return "Checking my battery level!";
    } else if (command.contains('mood')) {
      return "Let's change my mood!";
    } else if (command.contains('joke') || command.contains('funny')) {
      return "Hehe! I love being funny!";
    } else if (command.contains('sleep') || command.contains('tired')) {
      return "Yawn... I'm getting sleepy too!";
    } else {
      final responses = [
        "That's interesting! Tell me more!",
        "I heard you! What should I do?",
        "Got it! How can I help?",
        "Mochi is listening!",
        "What a great idea!",
      ];
      return responses[DateTime.now().millisecond % responses.length];
    }
  }

  /// Speak Mochi's response
  Future<void> _speakMochiResponse(String text) async {
    try {
      await speak(text);
    } catch (e) {
      debugPrint("Voice: Speak response error: $e");
    }
  }

  /// Speak text using TTS
  Future<void> speak(String text) async {
    if (!_isInitialized || text.isEmpty) return;
    
    try {
      await _tts.speak(text);
      debugPrint("Voice: Speaking: $text");
    } catch (e) {
      debugPrint("Voice: Speak error: $e");
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (e) {
      debugPrint("Voice: Stop speaking error: $e");
    }
  }

  /// Change voice profile
  Future<void> changeVoice(String voiceType) async {
    if (!_voiceProfiles.containsKey(voiceType)) return;
    
    _selectedVoice = voiceType;
    final profile = _voiceProfiles[voiceType]!;
    
    _speechRate = profile['rate'];
    _pitch = profile['pitch'];
    _volume = profile['volume'];
    
    try {
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.setVolume(_volume);
      
      notifyListeners();
      
      // Test the new voice
      await speak("Voice changed to ${profile['description']}!");
    } catch (e) {
      debugPrint("Voice: Change voice error: $e");
    }
  }

  /// Set language locale
  Future<void> setLanguage(String locale) async {
    _currentLocale = locale;
    
    try {
      String ttsLanguage = locale.replaceAll('_', '-');
      await _tts.setLanguage(ttsLanguage);
      notifyListeners();
    } catch (e) {
      debugPrint("Voice: Set language error: $e");
    }
  }

  /// Get available locales for speech recognition
  Future<List<LocaleName>> getAvailableLocales() async {
    try {
      return await _speech.locales();
    } catch (e) {
      debugPrint("Voice: Get locales error: $e");
      return [];
    }
  }

  /// Parse voice command to extract specific actions
  Map<String, dynamic> parseVoiceCommand(String command) {
    final normalized = command.toLowerCase().trim();
    
    // Time-related commands
    if (normalized.contains('time') || normalized.contains('clock')) {
      return {'action': 'show_time', 'type': 'time'};
    }
    
    // Reminder commands
    if (normalized.contains('remind') || normalized.contains('reminder')) {
      String? reminderText;
      if (normalized.contains('to ')) {
        reminderText = normalized.split('to ').last;
      }
      return {
        'action': 'create_reminder',
        'type': 'reminder',
        'text': reminderText,
      };
    }
    
    // Weather commands
    if (normalized.contains('weather')) {
      return {'action': 'show_weather', 'type': 'weather'};
    }
    
    // Mood commands
    if (normalized.contains('mood') || normalized.contains('feeling')) {
      String? mood;
      if (normalized.contains('happy')) mood = 'happy';
      else if (normalized.contains('sad')) mood = 'sad';
      else if (normalized.contains('sleepy') || normalized.contains('tired')) mood = 'sleepy';
      else if (normalized.contains('crazy') || normalized.contains('funny')) mood = 'crazy';
      
      return {
        'action': 'change_mood',
        'type': 'mood',
        'mood': mood ?? 'happy',
      };
    }
    
    // Battery commands
    if (normalized.contains('battery')) {
      return {'action': 'check_battery', 'type': 'battery'};
    }
    
    // General chat
    return {
      'action': 'chat',
      'type': 'chat',
      'text': command,
    };
  }

  @override
  void dispose() {
    _voiceCommandController.close();
    _listeningStateController.close();
    _speech.cancel();
    _tts.stop();
    super.dispose();
  }
}