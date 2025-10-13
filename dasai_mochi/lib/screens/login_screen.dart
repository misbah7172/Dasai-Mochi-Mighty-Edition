import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';
import '../services/user_preferences_service.dart';
import '../models/user.dart';
import '../components/mochi_widgets.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _mochiController;
  
  // Primary color for consistency
  final Color primaryColor = const Color(0xFFB8E6E6);
  final Color secondaryColor = const Color(0xFFF7C6D2);
  final Color backgroundColor = const Color(0xFFFFFBF0);
  
  // Form data
  String _name = '';
  int _age = 18;
  String _gender = 'Other';
  String _mochiNickname = 'Mochi';
  String _favoriteColor = 'pink';
  String _preferredVoice = 'default';
  List<String> _interests = [];
  bool _enableNotifications = true;
  bool _enableVoiceCommands = true;
  bool _enableLocation = false;
  
  int _currentPage = 0;
  final int _totalPages = 4;
  
  final List<String> _availableInterests = [
    'Music', 'Gaming', 'Reading', 'Cooking', 'Sports', 'Movies',
    'Art', 'Technology', 'Travel', 'Photography', 'Fitness', 'Animals'
  ];
  
  final List<String> _availableColors = [
    'pink', 'purple', 'blue', 'green', 'yellow', 'orange'
  ];
  
  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _mochiController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeController.forward();
    _slideController.forward();
    _mochiController.repeat();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _mochiController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              backgroundColor,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildWelcomePage(),
                    _buildPersonalInfoPage(),
                    _buildPreferencesPage(),
                    _buildFinalizePage(),
                  ],
                ),
              ),
              _buildNavigationButtons(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Animated Mochi character
          Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(60),
            ),
            child: Center(
              child: Text(
                '🧸',
                style: const TextStyle(fontSize: 60),
              ).animate(
                controller: _mochiController,
              ).scale(
                begin: const Offset(1.0, 1.0),
                end: const Offset(1.1, 1.1),
                duration: const Duration(seconds: 1),
              ).then().scale(
                begin: const Offset(1.1, 1.1),
                end: const Offset(1.0, 1.0),
                duration: const Duration(seconds: 1),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Meet Your Mochi!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.2),
          const SizedBox(height: 8),
          Text(
            'Let\'s get to know each other',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Text(
            'Welcome to Dasai Mochi!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 800.ms),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildFeatureItem(
                  '🎤', 'Voice Commands', 
                  'Talk to Mochi naturally'
                ),
                _buildFeatureItem(
                  '📱', 'Smart Device Control', 
                  'Control your ESP32 devices'
                ),
                _buildFeatureItem(
                  '🎵', 'Music & Entertainment', 
                  'Play music and have fun'
                ),
                _buildFeatureItem(
                  '⏰', 'Smart Reminders', 
                  'Never forget important tasks'
                ),
                _buildFeatureItem(
                  '💬', 'Cute Conversations', 
                  'Chat with your AI companion'
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideY(begin: 0.2),
        ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tell me about yourself!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ).animate().fadeIn(duration: 600.ms),
              const SizedBox(height: 24),
              
              // Name field
              MochiTextField(
                label: 'Your Name',
                hint: 'What should I call you?',
                prefixIcon: Icons.person,
                onChanged: (value) => _name = value,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideX(begin: -0.2),
              
              const SizedBox(height: 16),
              
              // Age field
              MochiTextField(
                label: 'Your Age',
                hint: 'How old are you?',
                prefixIcon: Icons.cake,
                keyboardType: TextInputType.number,
                onChanged: (value) => _age = int.tryParse(value) ?? 18,
                validator: (value) {
                  final age = int.tryParse(value ?? '');
                  if (age == null || age < 5 || age > 120) {
                    return 'Please enter a valid age (5-120)';
                  }
                  return null;
                },
              ).animate().fadeIn(delay: 400.ms, duration: 600.ms).slideX(begin: -0.2),
              
              const SizedBox(height: 16),
              
              // Gender selection
              Text(
                'Gender',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 8),
              Row(
                children: ['Male', 'Female', 'Other'].map((gender) =>
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: MochiButton(
                        text: gender,
                        isSecondary: _gender != gender,
                        onPressed: () {
                          setState(() {
                            _gender = gender;
                          });
                        },
                      ),
                    ),
                  ),
                ).toList(),
              ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
              
              const SizedBox(height: 16),
              
              // Mochi nickname
              MochiTextField(
                label: 'Mochi\'s Nickname',
                hint: 'What would you like to call me?',
                prefixIcon: Icons.pets,
                initialValue: _mochiNickname,
                onChanged: (value) => _mochiNickname = value.isNotEmpty ? value : 'Mochi',
              ).animate().fadeIn(delay: 1000.ms, duration: 600.ms).slideX(begin: -0.2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreferencesPage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Preferences',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ).animate().fadeIn(duration: 600.ms),
            const SizedBox(height: 24),
            
            // Favorite color
            Text(
              'Favorite Color Theme',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableColors.map((color) => 
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _favoriteColor = color;
                    });
                  },
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getColorFromName(color),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _favoriteColor == color 
                          ? primaryColor 
                          : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: _favoriteColor == color 
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                  ),
                ),
              ).toList(),
            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
            
            const SizedBox(height: 24),
            
            // Interests
            Text(
              'Your Interests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableInterests.map((interest) => 
                FilterChip(
                  label: Text(interest),
                  selected: _interests.contains(interest),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _interests.add(interest);
                      } else {
                        _interests.remove(interest);
                      }
                    });
                  },
                  backgroundColor: Colors.white.withOpacity(0.8),
                  selectedColor: primaryColor.withOpacity(0.3),
                  checkmarkColor: primaryColor,
                ),
              ).toList(),
            ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
            
            const SizedBox(height: 24),
            
            // Voice preference
            Text(
              'Preferred Voice Style',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ).animate().fadeIn(delay: 1000.ms),
            const SizedBox(height: 8),
            Column(
              children: ['default', 'robotic', 'funny', 'baby'].map((voice) =>
                RadioListTile<String>(
                  title: Text(_getVoiceDescription(voice)),
                  value: voice,
                  groupValue: _preferredVoice,
                  onChanged: (value) {
                    setState(() {
                      _preferredVoice = value!;
                    });
                  },
                  activeColor: primaryColor,
                ),
              ).toList(),
            ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalizePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Almost Ready!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(duration: 600.ms),
          
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Get reminders and updates'),
                  value: _enableNotifications,
                  onChanged: (value) {
                    setState(() {
                      _enableNotifications = value;
                    });
                  },
                  activeColor: primaryColor,
                ),
                SwitchListTile(
                  title: const Text('Enable Voice Commands'),
                  subtitle: const Text('Control Mochi with your voice'),
                  value: _enableVoiceCommands,
                  onChanged: (value) {
                    setState(() {
                      _enableVoiceCommands = value;
                    });
                  },
                  activeColor: primaryColor,
                ),
                SwitchListTile(
                  title: const Text('Enable Location Services'),
                  subtitle: const Text('For weather and location-based features'),
                  value: _enableLocation,
                  onChanged: (value) {
                    setState(() {
                      _enableLocation = value;
                    });
                  },
                  activeColor: primaryColor,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms, duration: 800.ms).slideY(begin: 0.2),
          
          const SizedBox(height: 32),
          
          Text(
            'Tap "Start Journey" to begin your adventure with $_mochiNickname!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 800.ms, duration: 600.ms),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Progress indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages, (index) =>
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: index == _currentPage 
                    ? primaryColor 
                    : Colors.grey[300],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Navigation buttons
          Row(
            children: [
              if (_currentPage > 0)
                Expanded(
                  child: MochiButton(
                    text: 'Back',
                    isSecondary: true,
                    onPressed: () {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ),
              if (_currentPage > 0) const SizedBox(width: 16),
              Expanded(
                child: MochiButton(
                  text: _currentPage == _totalPages - 1 ? 'Start Journey!' : 'Next',
                  onPressed: () {
                    if (_currentPage == _totalPages - 1) {
                      _completeSetup();
                    } else {
                      if (_currentPage == 1 && !_formKey.currentState!.validate()) {
                        return;
                      }
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorFromName(String colorName) {
    switch (colorName) {
      case 'pink': return Colors.pink[300]!;
      case 'purple': return Colors.purple[300]!;
      case 'blue': return Colors.blue[300]!;
      case 'green': return Colors.green[300]!;
      case 'yellow': return Colors.yellow[300]!;
      case 'orange': return Colors.orange[300]!;
      default: return Colors.pink[300]!;
    }
  }

  String _getVoiceDescription(String voice) {
    switch (voice) {
      case 'default': return 'Normal friendly voice';
      case 'robotic': return 'Cool robotic voice';
      case 'funny': return 'High-pitched funny voice';
      case 'baby': return 'Cute baby voice';
      default: return 'Normal friendly voice';
    }
  }

  Future<void> _completeSetup() async {
    try {
      final storageService = Provider.of<LocalStorageService>(context, listen: false);
      
      // Create user object using the correct User model constructor
      final user = User(
        fullName: _name,
        nickname: _mochiNickname,
        dateOfBirth: DateTime.now().subtract(Duration(days: _age * 365)),
        profileImage: null,
        preferredLanguage: 'English',
        soundEffectsEnabled: _enableNotifications,
        animationsEnabled: true,
        selectedTheme: _favoriteColor,
        selectedVoice: _preferredVoice,
        festivalModeEnabled: false,
        petModeEnabled: true,
      );
      
      // Save user data
      await storageService.saveUser(user);
      
      // Initialize user preferences service with collected data
      if (!mounted) return;
      final userPrefs = Provider.of<UserPreferencesService>(context, listen: false);
      await userPrefs.saveUserData(
        fullName: _name,
        nickname: _mochiNickname,
        dateOfBirth: DateTime.now().subtract(Duration(days: _age * 365)),
        favoriteColor: _favoriteColor,
        interests: _interests,
        selectedTheme: _favoriteColor,
        selectedVoice: _preferredVoice,
        animationsEnabled: true,
        soundEffectsEnabled: _enableNotifications,
        notificationsEnabled: _enableNotifications,
        voiceCommandsEnabled: _enableVoiceCommands,
        locationEnabled: _enableLocation,
      );
      
      // Mark setup as complete using SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isSetupComplete', true);
      await prefs.setString('userGender', _gender);
      
      // Show success feedback
      HapticFeedback.mediumImpact();
      
      if (!mounted) return;
      
      // Navigate to dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const DashboardScreen(),
        ),
      );
      
    } catch (e) {
      debugPrint('Setup completion error: $e');
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setup failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// Custom text field for Mochi theme
class MochiTextField extends StatelessWidget {
  final String label;
  final String hint;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final Function(String)? onChanged;
  final String? Function(String?)? validator;
  final String? initialValue;

  const MochiTextField({
    super.key,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.keyboardType,
    this.onChanged,
    this.validator,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFB8E6E6);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: primaryColor,
                width: 2,
              ),
            ),
          ),
          keyboardType: keyboardType,
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }
}