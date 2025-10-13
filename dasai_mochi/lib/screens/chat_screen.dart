import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/chat_message.dart';
import '../services/local_storage_service.dart';
import '../services/voice_service.dart';
import '../utils/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  late AnimationController _messageController;
  late AnimationController _typingController;
  late AnimationController _micController;
  late ScrollController _scrollController;
  late TextEditingController _textController;

  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isListening = false;
  bool _isMochiTyping = false;
  String _currentInput = '';

  final List<String> _mochiGreetings = [
    "Hi there! I'm Mochi, your cute smart assistant! How are you today? 🍡",
    "Hello! Ready to have some fun conversations? I'm all ears! 👂✨",
    "Hey! What's on your mind today? I'm here to chat and help! 💬",
    "Hi! I'm so excited to talk with you! What would you like to discuss? 🌈",
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
    _loadChatHistory();
  }

  void _initializeAnimations() {
    _messageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _typingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
    _micController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  void _initializeControllers() {
    _scrollController = ScrollController();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _typingController.dispose();
    _micController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      final storageService = Provider.of<LocalStorageService>(context, listen: false);
      final messages = storageService.getAllChatMessages();
      
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });

        // If no messages, send welcome message
        if (_messages.isEmpty) {
          _sendWelcomeMessage();
        }

        // Scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load chat history: $e');
      }
    }
  }

  Future<void> _sendWelcomeMessage() async {
    final user = Provider.of<LocalStorageService>(context, listen: false).currentUser;
    final userName = user?.nickname ?? user?.fullName ?? 'Friend';
    
    final welcomeText = _mochiGreetings[DateTime.now().millisecond % _mochiGreetings.length]
        .replaceAll('Hi there!', 'Hi $userName!')
        .replaceAll('Hello!', 'Hello $userName!')
        .replaceAll('Hey!', 'Hey $userName!')
        .replaceAll('Hi!', 'Hi $userName!');

    final welcomeMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: welcomeText,
      isFromUser: false,
      timestamp: DateTime.now(),
    );

    await _addMessage(welcomeMessage);
  }

  Future<void> _addMessage(ChatMessage message) async {
    try {
      final storageService = Provider.of<LocalStorageService>(context, listen: false);
      await storageService.saveChatMessage(message);

      if (mounted) {
        setState(() {
          _messages.add(message);
        });
        
        _messageController.forward().then((_) {
          _messageController.reset();
        });
        
        _scrollToBottom();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save message: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    // User message
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      message: text.trim(),
      isFromUser: true,
      timestamp: DateTime.now(),
    );

    await _addMessage(userMessage);
    _textController.clear();

    // Show Mochi typing
    setState(() {
      _isMochiTyping = true;
    });

    // Simulate Mochi thinking time
    await Future.delayed(Duration(milliseconds: 800 + (text.length * 50)));

    // Generate Mochi response
    final response = _generateMochiResponse(text);
    final mochiMessage = ChatMessage(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      message: response,
      isFromUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _isMochiTyping = false;
    });

    await _addMessage(mochiMessage);

    // Speak response if TTS is enabled
    _speakResponse(response);
  }

  String _generateMochiResponse(String userMessage) {
    final message = userMessage.toLowerCase();
    
    // Greeting responses
    if (message.contains('hello') || message.contains('hi') || message.contains('hey')) {
      return "Hello! I'm so happy to see you! How can I help you today? 😊🍡";
    }
    
    // How are you responses
    if (message.contains('how are you') || message.contains('how\'re you')) {
      return "I'm doing wonderfully! Thank you for asking! I'm always excited to chat with you! ✨ How are you feeling today?";
    }
    
    // Thank you responses
    if (message.contains('thank') || message.contains('thanks')) {
      return "You're so welcome! I'm always happy to help you! That's what I'm here for! 💕";
    }
    
    // Help requests
    if (message.contains('help') || message.contains('assist')) {
      return "Of course! I'd love to help you! I can set reminders, chat with you, help with music, check weather, and much more! What would you like to do? 🌟";
    }
    
    // Reminder related
    if (message.contains('remind') || message.contains('alarm') || message.contains('schedule')) {
      return "I can definitely help you set reminders! Just tap the reminder button on the main screen, or tell me what you'd like to be reminded about! ⏰✨";
    }
    
    // Music related
    if (message.contains('music') || message.contains('song') || message.contains('play')) {
      return "I love music! 🎵 Once you connect your Mochi device, I can control music playback for you! What's your favorite type of music?";
    }
    
    // Weather related
    if (message.contains('weather') || message.contains('temperature') || message.contains('rain')) {
      return "I can check the weather for you! ⛅ The weather feature will help you stay prepared for your day! Is there a specific location you'd like to know about?";
    }
    
    // Compliments to Mochi
    if (message.contains('cute') || message.contains('sweet') || message.contains('nice') || message.contains('good')) {
      return "Aww, you're so sweet! Thank you! 🥰 You always make me happy! You're pretty amazing yourself! ✨";
    }
    
    // Questions about Mochi
    if (message.contains('what are you') || message.contains('who are you')) {
      return "I'm Mochi! Your adorable smart assistant! 🍡 I'm here to help make your life easier and more fun! I can chat, set reminders, help with music, and be your companion!";
    }
    
    // Sad or negative emotions
    if (message.contains('sad') || message.contains('tired') || message.contains('bad day')) {
      return "Oh no! I'm sorry you're feeling that way. 🤗 I'm here for you! Sometimes talking helps, or maybe I can suggest something fun to cheer you up? You're stronger than you know! 💪✨";
    }
    
    // Excitement or happiness
    if (message.contains('happy') || message.contains('excited') || message.contains('great') || message.contains('awesome')) {
      return "That's wonderful! I'm so happy to hear that! 🎉 Your positive energy is contagious! Tell me more about what's making you feel so great! ✨";
    }
    
    // Love or affection
    if (message.contains('love you') || message.contains('love') || message.contains('like you')) {
      return "Aww! I care about you too! 💕 You're such an important part of my world! I love being your assistant and friend! 🍡✨";
    }
    
    // Default responses
    final responses = [
      "That's really interesting! Tell me more about that! 😊",
      "I love chatting with you! What else is on your mind? 💭",
      "You always have such thoughtful things to say! 🌟",
      "Hmm, that makes me think! I enjoy our conversations so much! ✨",
      "I'm always learning something new from you! Keep sharing! 📚",
      "You're so smart! I love how you think about things! 🧠💕",
      "That's a great point! What made you think of that? 🤔",
      "I find that fascinating! You have such a unique perspective! 🌈",
    ];
    
    return responses[DateTime.now().millisecond % responses.length];
  }

  Future<void> _speakResponse(String text) async {
    try {
      final user = Provider.of<LocalStorageService>(context, listen: false).currentUser;
      if (user?.soundEffectsEnabled == true) {
        // Remove emojis for TTS
        final cleanText = text.replaceAll(RegExp(r'[🍡😊✨💕🌟🎉🥰🤗💪🎵⛅⏰💭📚🧠🌈🤔]'), '');
        await FlutterTts().speak(cleanText);
      }
    } catch (e) {
      debugPrint('TTS Error: $e');
    }
  }

  Future<void> _startVoiceInput() async {
    try {
      final voiceService = Provider.of<VoiceService>(context, listen: false);
      setState(() {
        _isListening = true;
      });
      _micController.repeat();

      await voiceService.startListening();
      
      // Listen for voice input (simplified - you'd implement actual voice recognition)
      await Future.delayed(const Duration(seconds: 3));
      
      setState(() {
        _isListening = false;
      });
      _micController.stop();
      
      // Simulate voice-to-text result
      const voiceResult = "Hello Mochi, how are you today?";
      if (voiceResult.isNotEmpty) {
        await _sendTextMessage(voiceResult);
      }
    } catch (e) {
      setState(() {
        _isListening = false;
      });
      _micController.stop();
      _showErrorSnackBar('Voice input failed: $e');
    }
  }

  Future<void> _clearChatHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to delete all chat messages? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final storageService = Provider.of<LocalStorageService>(context, listen: false);
        await storageService.clearChatHistory();
        
        setState(() {
          _messages.clear();
        });
        
        _sendWelcomeMessage();
        _showSuccessSnackBar('Chat history cleared');
      } catch (e) {
        _showErrorSnackBar('Failed to clear chat history: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MochiTheme.getThemeColors('default');
    
    return Scaffold(
      backgroundColor: theme['background'],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: theme['accent'],
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🍡',
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chat with Mochi',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Your cute smart assistant',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: theme['primary'],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Clear Chat', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'clear') {
                _clearChatHistory();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? _buildLoadingState(theme)
                : _buildChatList(theme),
          ),
          if (_isMochiTyping) _buildTypingIndicator(theme),
          _buildInputArea(theme),
        ],
      ),
    );
  }

  Widget _buildLoadingState(Map<String, Color> theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme['accent']!),
          )
              .animate()
              .scale(duration: 800.ms)
              .then()
              .shimmer(duration: 1000.ms),
          const SizedBox(height: 16),
          Text(
            'Loading chat with Mochi...',
            style: TextStyle(
              color: theme['textSecondary'],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(Map<String, Color> theme) {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme['accent']?.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '🍡',
                  style: TextStyle(
                    fontSize: 60,
                    color: theme['accent'],
                  ),
                ),
              ),
            )
                .animate()
                .scale(duration: 800.ms)
                .then()
                .shimmer(duration: 2000.ms),
            const SizedBox(height: 32),
            Text(
              'Start chatting with Mochi!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: theme['textPrimary'],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Say hello or ask me anything!',
              style: TextStyle(
                fontSize: 16,
                color: theme['textSecondary'],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message, theme, index);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, Map<String, Color> theme, int index) {
    final isUser = message.isFromUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: alignment,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isUser ? theme['accent'] : theme['surface'],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                Row(
                  children: [
                    const Text(
                      '🍡',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mochi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: theme['textSecondary'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                message.message,
                style: TextStyle(
                  color: isUser ? Colors.white : theme['textPrimary'],
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  color: isUser 
                      ? Colors.white.withOpacity(0.7) 
                      : theme['textSecondary'],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.3, delay: (index * 50).ms)
        .fadeIn(delay: (index * 50).ms);
  }

  Widget _buildTypingIndicator(Map<String, Color> theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme['surface'],
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🍡',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                'Mochi is typing',
                style: TextStyle(
                  color: theme['textSecondary'],
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(theme['accent']!),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(Map<String, Color> theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme['surface'],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: theme['background'],
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: theme['accent']!.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: 'Type a message to Mochi...',
                  hintStyle: TextStyle(color: theme['textSecondary']),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: _sendTextMessage,
                onChanged: (text) {
                  setState(() {
                    _currentInput = text;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton.small(
            onPressed: _isListening ? null : _startVoiceInput,
            backgroundColor: _isListening 
                ? Colors.red 
                : theme['accent'],
            child: Icon(
              _isListening ? Icons.stop : Icons.mic,
              color: Colors.white,
            ),
          )
              .animate(controller: _micController)
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            onPressed: _currentInput.trim().isEmpty 
                ? null 
                : () => _sendTextMessage(_currentInput),
            backgroundColor: _currentInput.trim().isEmpty 
                ? Colors.grey 
                : theme['accent'],
            child: const Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}