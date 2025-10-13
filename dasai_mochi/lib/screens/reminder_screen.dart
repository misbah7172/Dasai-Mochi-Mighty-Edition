import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../models/reminder.dart';
import '../services/local_storage_service.dart';
import '../utils/theme.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({Key? key}) : super(key: key);

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen>
    with TickerProviderStateMixin {
  late AnimationController _fabController;
  late AnimationController _listController;
  List<Reminder> _reminders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _listController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadReminders();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _listController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    try {
      final storageService = Provider.of<LocalStorageService>(context, listen: false);
      final reminders = storageService.getAllReminders();
      
      if (mounted) {
        setState(() {
          _reminders = reminders;
          _isLoading = false;
        });
        _listController.forward();
        _fabController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load reminders: $e');
      }
    }
  }

  Future<void> _addReminder() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditReminderScreen(),
      ),
    );

    if (result == true) {
      _loadReminders();
    }
  }

  Future<void> _editReminder(Reminder reminder) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditReminderScreen(reminder: reminder),
      ),
    );

    if (result == true) {
      _loadReminders();
    }
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder'),
        content: Text('Are you sure you want to delete "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final storageService = Provider.of<LocalStorageService>(context, listen: false);
        await storageService.deleteReminder(reminder.id);
        
        // Cancel notification if it exists
        await AwesomeNotifications().cancel(reminder.id.hashCode);
        
        _loadReminders();
        _showSuccessSnackBar('Reminder deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete reminder: $e');
      }
    }
  }

  Future<void> _toggleReminder(Reminder reminder) async {
    try {
      final storageService = Provider.of<LocalStorageService>(context, listen: false);
      final updatedReminder = reminder.copyWith(isActive: !reminder.isActive);
      await storageService.saveReminder(updatedReminder);
      
      if (updatedReminder.isActive) {
        await _scheduleNotification(updatedReminder);
      } else {
        await AwesomeNotifications().cancel(reminder.id.hashCode);
      }
      
      _loadReminders();
    } catch (e) {
      _showErrorSnackBar('Failed to update reminder: $e');
    }
  }

  Future<void> _scheduleNotification(Reminder reminder) async {
    if (!reminder.isActive) return;

    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: reminder.id.hashCode,
          channelKey: 'mochi_reminders',
          title: 'Mochi Reminder 🍡',
          body: reminder.title,
          bigPicture: 'asset://assets/images/mochi_reminder.png',
          notificationLayout: NotificationLayout.BigPicture,
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar.fromDate(date: reminder.scheduledTime),
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
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
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: theme['primary'],
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
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
                    'Loading reminders...',
                    style: TextStyle(
                      color: theme['textSecondary'],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : _reminders.isEmpty
              ? _buildEmptyState(theme)
              : _buildReminderList(theme),
      floatingActionButton: FloatingActionButton(
        onPressed: _addReminder,
        backgroundColor: theme['accent'],
        child: const Icon(Icons.add, color: Colors.white),
      )
          .animate(controller: _fabController)
          .scale(begin: const Offset(0, 0), end: const Offset(1, 1))
          .fade(),
    );
  }

  Widget _buildEmptyState(Map<String, Color> theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            size: 120,
            color: theme['textSecondary']?.withOpacity(0.3),
          )
              .animate()
              .scale(duration: 800.ms)
              .then()
              .shimmer(duration: 2000.ms),
          const SizedBox(height: 32),
          Text(
            'No reminders yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: theme['textPrimary'],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first reminder',
            style: TextStyle(
              fontSize: 16,
              color: theme['textSecondary'],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(
              color: theme['surface'],
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: theme['accent'],
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Mochi will remind you about important tasks and events!',
                  style: TextStyle(
                    color: theme['textSecondary'],
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
        ],
      ),
    );
  }

  Widget _buildReminderList(Map<String, Color> theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reminders.length,
      itemBuilder: (context, index) {
        final reminder = _reminders[index];
        return _buildReminderCard(reminder, theme, index);
      },
    );
  }

  Widget _buildReminderCard(Reminder reminder, Map<String, Color> theme, int index) {
    final isOverdue = reminder.scheduledTime.isBefore(DateTime.now()) && reminder.isActive;
    final isToday = _isSameDay(reminder.scheduledTime, DateTime.now());
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: theme['surface'],
        borderRadius: BorderRadius.circular(16),
        border: isOverdue
            ? Border.all(color: Colors.red.withOpacity(0.5), width: 2)
            : isToday
                ? Border.all(color: theme['accent']!.withOpacity(0.5), width: 2)
                : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editReminder(reminder),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(reminder.priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reminder.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme['textPrimary'],
                          decoration: reminder.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    Switch(
                      value: reminder.isActive,
                      onChanged: (value) => _toggleReminder(reminder),
                      activeColor: theme['accent'],
                    ),
                    PopupMenuButton(
                      icon: Icon(Icons.more_vert, color: theme['textSecondary']),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: const Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: const Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _editReminder(reminder);
                            break;
                          case 'delete':
                            _deleteReminder(reminder);
                            break;
                        }
                      },
                    ),
                  ],
                ),
                if (reminder.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 8),
                  Text(
                    reminder.description!,
                    style: TextStyle(
                      color: theme['textSecondary'],
                      fontSize: 14,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isOverdue ? Colors.red : theme['textSecondary'],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDateTime(reminder.scheduledTime),
                      style: TextStyle(
                        color: isOverdue ? Colors.red : theme['textSecondary'],
                        fontSize: 12,
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.priority_high,
                      size: 16,
                      color: theme['textSecondary'],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      reminder.priority,
                      style: TextStyle(
                        color: theme['textSecondary'],
                        fontSize: 12,
                      ),
                    ),
                    if (isOverdue) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'OVERDUE',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ] else if (isToday) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme['accent']!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'TODAY',
                          style: TextStyle(
                            color: theme['accent'],
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate(controller: _listController)
        .slideY(begin: 0.3, delay: (index * 100).ms)
        .fadeIn(delay: (index * 100).ms);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      case 'work':
        return Colors.blue;
      case 'personal':
        return Colors.green;
      case 'health':
        return Colors.red;
      case 'shopping':
        return Colors.orange;
      case 'entertainment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final reminderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (reminderDate == today) {
      dateStr = 'Today';
    } else if (reminderDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }
}

class AddEditReminderScreen extends StatefulWidget {
  final Reminder? reminder;

  const AddEditReminderScreen({Key? key, this.reminder}) : super(key: key);

  @override
  State<AddEditReminderScreen> createState() => _AddEditReminderScreenState();
}

class _AddEditReminderScreenState extends State<AddEditReminderScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDateTime;
  late String _selectedCategory;
  late bool _isActive;
  late AnimationController _animationController;

  final List<String> _categories = [
    'Personal',
    'Work',
    'Health',
    'Shopping',
    'Entertainment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    final isEditing = widget.reminder != null;
    _titleController = TextEditingController(
      text: isEditing ? widget.reminder!.title : '',
    );
    _descriptionController = TextEditingController(
      text: isEditing ? widget.reminder!.description ?? '' : '',
    );
    _selectedDateTime = isEditing 
        ? widget.reminder!.scheduledTime 
        : DateTime.now().add(const Duration(hours: 1));
    _selectedCategory = isEditing ? widget.reminder!.priority : _categories[0];
    _isActive = isEditing ? widget.reminder!.isActive : true;

    _animationController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final storageService = Provider.of<LocalStorageService>(context, listen: false);
      
      final reminder = Reminder(
        id: widget.reminder?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        scheduledTime: _selectedDateTime,
        priority: _selectedCategory,
        isActive: _isActive,
        createdAt: widget.reminder?.createdAt ?? DateTime.now(),
      );

      await storageService.saveReminder(reminder);

      // Schedule notification if active
      if (reminder.isActive) {
        await _scheduleNotification(reminder);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save reminder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _scheduleNotification(Reminder reminder) async {
    try {
      await AwesomeNotifications().createNotification(
        content: NotificationContent(
          id: reminder.id.hashCode,
          channelKey: 'mochi_reminders',
          title: 'Mochi Reminder 🍡',
          body: reminder.title,
          bigPicture: 'asset://assets/images/mochi_reminder.png',
          notificationLayout: NotificationLayout.BigPicture,
          wakeUpScreen: true,
          category: NotificationCategory.Reminder,
        ),
        schedule: NotificationCalendar.fromDate(date: reminder.scheduledTime),
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = MochiTheme.getThemeColors('default');
    final isEditing = widget.reminder != null;

    return Scaffold(
      backgroundColor: theme['background'],
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Reminder' : 'New Reminder',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: theme['primary'],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _saveReminder,
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTitleField(theme),
            const SizedBox(height: 16),
            _buildDescriptionField(theme),
            const SizedBox(height: 16),
            _buildDateTimeSelector(theme),
            const SizedBox(height: 16),
            _buildCategorySelector(theme),
            const SizedBox(height: 16),
            _buildActiveToggle(theme),
            const SizedBox(height: 32),
            _buildSaveButton(theme),
          ]
              .animate()
              .slideY(begin: 0.3)
              .fadeIn(),
        ),
      ),
    );
  }

  Widget _buildTitleField(Map<String, Color> theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme['surface'],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: 'Reminder Title',
          prefixIcon: Icon(Icons.title, color: theme['accent']),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Please enter a title';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDescriptionField(Map<String, Color> theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme['surface'],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'Description (Optional)',
          prefixIcon: Icon(Icons.description, color: theme['accent']),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildDateTimeSelector(Map<String, Color> theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme['surface'],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(Icons.schedule, color: theme['accent']),
        title: const Text('Date & Time'),
        subtitle: Text(_formatDateTime(_selectedDateTime)),
        trailing: Icon(Icons.arrow_forward_ios, color: theme['textSecondary']),
        onTap: _selectDateTime,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildCategorySelector(Map<String, Color> theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme['surface'],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: _selectedCategory,
        decoration: InputDecoration(
          labelText: 'Priority',
          prefixIcon: Icon(Icons.priority_high, color: theme['accent']),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
        ),
        items: _categories.map((category) {
          return DropdownMenuItem(
            value: category,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(category),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedCategory = value!;
          });
        },
      ),
    );
  }

  Widget _buildActiveToggle(Map<String, Color> theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme['surface'],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        title: const Text('Active'),
        subtitle: Text(_isActive ? 'Reminder is enabled' : 'Reminder is disabled'),
        secondary: Icon(
          _isActive ? Icons.notifications_active : Icons.notifications_off,
          color: theme['accent'],
        ),
        value: _isActive,
        activeColor: theme['accent'],
        onChanged: (value) {
          setState(() {
            _isActive = value;
          });
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildSaveButton(Map<String, Color> theme) {
    return ElevatedButton(
      onPressed: _saveReminder,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme['accent'],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 4,
      ),
      child: Text(
        widget.reminder != null ? 'Update Reminder' : 'Create Reminder',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      case 'work':
        return Colors.blue;
      case 'personal':
        return Colors.green;
      case 'health':
        return Colors.red;
      case 'shopping':
        return Colors.orange;
      case 'entertainment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final reminderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (reminderDate == today) {
      dateStr = 'Today';
    } else if (reminderDate == tomorrow) {
      dateStr = 'Tomorrow';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }
}