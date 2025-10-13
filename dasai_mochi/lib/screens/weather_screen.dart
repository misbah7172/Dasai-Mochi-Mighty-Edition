import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../utils/theme.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen>
    with TickerProviderStateMixin {
  late AnimationController _cloudController;
  late AnimationController _rainController;
  late PageController _pageController;
  
  int _currentPageIndex = 0;
  String _selectedLocation = 'Tokyo, Japan';
  
  // Sample weather data
  final Map<String, dynamic> _currentWeather = {
    'temperature': 24,
    'condition': 'sunny',
    'humidity': 65,
    'windSpeed': 12,
    'uvIndex': 6,
    'visibility': 10,
    'pressure': 1013,
    'feelsLike': 26,
    'description': 'Sunny with a gentle breeze',
  };
  
  final List<Map<String, dynamic>> _hourlyForecast = [
    {'time': '12:00', 'temp': 24, 'condition': 'sunny', 'humidity': 65},
    {'time': '13:00', 'temp': 26, 'condition': 'partly_cloudy', 'humidity': 62},
    {'time': '14:00', 'temp': 28, 'condition': 'sunny', 'humidity': 58},
    {'time': '15:00', 'temp': 27, 'condition': 'cloudy', 'humidity': 60},
    {'time': '16:00', 'temp': 25, 'condition': 'rainy', 'humidity': 70},
    {'time': '17:00', 'temp': 23, 'condition': 'rainy', 'humidity': 75},
  ];
  
  final List<Map<String, dynamic>> _weeklyForecast = [
    {'day': 'Today', 'high': 28, 'low': 18, 'condition': 'sunny'},
    {'day': 'Tomorrow', 'high': 26, 'low': 16, 'condition': 'partly_cloudy'},
    {'day': 'Wed', 'high': 22, 'low': 14, 'condition': 'rainy'},
    {'day': 'Thu', 'high': 25, 'low': 17, 'condition': 'cloudy'},
    {'day': 'Fri', 'high': 29, 'low': 20, 'condition': 'sunny'},
    {'day': 'Sat', 'high': 27, 'low': 18, 'condition': 'partly_cloudy'},
    {'day': 'Sun', 'high': 24, 'low': 15, 'condition': 'rainy'},
  ];

  @override
  void initState() {
    super.initState();
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );
    _rainController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pageController = PageController();
    
    _cloudController.repeat();
    if (_currentWeather['condition'] == 'rainy') {
      _rainController.repeat();
    }
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _rainController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _getBackgroundColor(),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildLocationSelector(),
          _buildTabIndicator(),
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPageIndex = index),
              children: [
                _buildCurrentWeatherPage(),
                _buildHourlyForecastPage(),
                _buildWeeklyForecastPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (_currentWeather['condition']) {
      case 'sunny':
        return const Color(0xFFFFF8E1);
      case 'cloudy':
        return const Color(0xFFF5F5F5);
      case 'rainy':
        return const Color(0xFFE3F2FD);
      case 'partly_cloudy':
        return const Color(0xFFF0F4C3);
      default:
        return const Color(0xFFFFFBF0);
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios,
          color: Color(0xFF2D3748),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        '🌤️ Weather',
        style: TextStyle(
          color: Color(0xFF2D3748),
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh,
            color: MochiTheme.pastelColors['blue']!,
          ),
          onPressed: _refreshWeatherData,
        ),
        IconButton(
          icon: Icon(
            Icons.settings,
            color: MochiTheme.pastelColors['blue']!,
          ),
          onPressed: _showWeatherSettings,
        ),
      ],
    );
  }

  Widget _buildLocationSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            color: MochiTheme.pastelColors['purple']!,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedLocation,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: MochiTheme.pastelColors['blue']!,
            ),
            onPressed: _showLocationSearch,
          ),
        ],
      ),
    );
  }

  Widget _buildTabIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildTabItem('Current', 0, Icons.wb_sunny),
          _buildTabItem('Hourly', 1, Icons.schedule),
          _buildTabItem('Weekly', 2, Icons.calendar_today),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index, IconData icon) {
    final isSelected = _currentPageIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? MochiTheme.pastelColors['blue']!.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected 
                    ? MochiTheme.pastelColors['blue']!
                    : const Color(0xFF718096),
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected 
                      ? MochiTheme.pastelColors['blue']!
                      : const Color(0xFF718096),
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentWeatherPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildMainWeatherCard(),
          const SizedBox(height: 20),
          _buildWeatherDetailsGrid(),
          const SizedBox(height: 20),
          _buildWeatherTips(),
        ],
      ),
    );
  }

  Widget _buildMainWeatherCard() {
    return Container(
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            MochiTheme.pastelColors['blue']!.withOpacity(0.8),
            MochiTheme.pastelColors['lavender']!.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildWeatherIcon(_currentWeather['condition'], size: 120),
          const SizedBox(height: 20),
          Text(
            '${_currentWeather['temperature']}°',
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(delay: 200.ms),
          Text(
            _currentWeather['description'],
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Text(
            'Feels like ${_currentWeather['feelsLike']}°',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherIcon(String condition, {double size = 60}) {
    Widget icon;
    switch (condition) {
      case 'sunny':
        icon = Icon(
          Icons.wb_sunny,
          size: size,
          color: Colors.amber,
        )
            .animate(onPlay: (controller) => controller.repeat())
            .rotate(duration: 10.seconds);
        break;
      case 'cloudy':
        icon = Icon(
          Icons.cloud,
          size: size,
          color: Colors.grey[400],
        )
            .animate(onPlay: (controller) => controller.repeat(reverse: true))
            .moveX(duration: 3.seconds, begin: -5, end: 5);
        break;
      case 'partly_cloudy':
        icon = Icon(
          Icons.wb_cloudy,
          size: size,
          color: Colors.blue[300],
        );
        break;
      case 'rainy':
        icon = Icon(
          Icons.grain,
          size: size,
          color: Colors.blue[600],
        )
            .animate(onPlay: (controller) => controller.repeat())
            .shake(duration: 500.ms);
        break;
      default:
        icon = Icon(
          Icons.wb_sunny,
          size: size,
          color: Colors.amber,
        );
    }
    return icon;
  }

  Widget _buildWeatherDetailsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildDetailCard('Humidity', '${_currentWeather['humidity']}%', Icons.water_drop),
        _buildDetailCard('Wind', '${_currentWeather['windSpeed']} km/h', Icons.air),
        _buildDetailCard('UV Index', '${_currentWeather['uvIndex']}', Icons.wb_sunny_outlined),
        _buildDetailCard('Visibility', '${_currentWeather['visibility']} km', Icons.visibility),
        _buildDetailCard('Pressure', '${_currentWeather['pressure']} hPa', Icons.compress),
        _buildDetailCard('Air Quality', 'Good', Icons.eco),
      ],
    );
  }

  Widget _buildDetailCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 32,
            color: MochiTheme.pastelColors['blue']!,
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(delay: 100.ms);
  }

  Widget _buildWeatherTips() {
    String tip = _getWeatherTip(_currentWeather['condition']);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MochiTheme.pastelColors['lemonYellow']!.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: MochiTheme.pastelColors['lemonYellow']!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb,
            color: MochiTheme.pastelColors['peachOrange']!,
            size: 24,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              tip,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF2D3748),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms)
        .slide(begin: const Offset(0, 0.2));
  }

  Widget _buildHourlyForecastPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '24-Hour Forecast',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _hourlyForecast.length,
              itemBuilder: (context, index) {
                return _buildHourlyItem(_hourlyForecast[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyItem(Map<String, dynamic> forecast, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              forecast['time'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          const SizedBox(width: 20),
          _buildWeatherIcon(forecast['condition'], size: 40),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${forecast['temp']}°',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  'Humidity: ${forecast['humidity']}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: MochiTheme.pastelColors['blue']!,
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 500.ms)
        .slide(begin: const Offset(0.2, 0));
  }

  Widget _buildWeeklyForecastPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '7-Day Forecast',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: _weeklyForecast.length,
              itemBuilder: (context, index) {
                return _buildWeeklyItem(_weeklyForecast[index], index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyItem(Map<String, dynamic> forecast, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              forecast['day'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
          ),
          const SizedBox(width: 20),
          _buildWeatherIcon(forecast['condition'], size: 40),
          const Spacer(),
          Text(
            '${forecast['low']}°',
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF718096),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            '${forecast['high']}°',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 100))
        .fadeIn(duration: 500.ms)
        .slide(begin: const Offset(-0.2, 0));
  }

  String _getWeatherTip(String condition) {
    switch (condition) {
      case 'sunny':
        return 'Perfect weather for outdoor activities! Don\'t forget sunscreen.';
      case 'cloudy':
        return 'Great day for a walk. The clouds provide natural shade.';
      case 'rainy':
        return 'Don\'t forget your umbrella! Perfect weather for indoor activities.';
      case 'partly_cloudy':
        return 'Nice mixed weather. Great for both indoor and outdoor plans.';
      default:
        return 'Have a wonderful day with Mochi! 🌸';
    }
  }

  void _refreshWeatherData() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Weather data refreshed! 🌤️'),
        backgroundColor: MochiTheme.pastelColors['blue'],
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showLocationSearch() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Location',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 20),
            ...[
              'Tokyo, Japan',
              'New York, USA',
              'London, UK',
              'Sydney, Australia',
              'Paris, France',
            ].map((location) => ListTile(
              leading: Icon(
                Icons.location_on,
                color: MochiTheme.pastelColors['purple']!,
              ),
              title: Text(location),
              onTap: () {
                setState(() {
                  _selectedLocation = location;
                });
                Navigator.pop(context);
                _refreshWeatherData();
              },
            )).toList(),
          ],
        ),
      ),
    );
  }

  void _showWeatherSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Weather Settings',
          style: TextStyle(color: Color(0xFF2D3748)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Temperature in Celsius'),
              value: true,
              onChanged: (value) {},
              activeColor: MochiTheme.pastelColors['blue'],
            ),
            SwitchListTile(
              title: const Text('Weather Notifications'),
              value: true,
              onChanged: (value) {},
              activeColor: MochiTheme.pastelColors['blue'],
            ),
            SwitchListTile(
              title: const Text('Show Weather Tips'),
              value: true,
              onChanged: (value) {},
              activeColor: MochiTheme.pastelColors['blue'],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: MochiTheme.pastelColors['blue']),
            ),
          ),
        ],
      ),
    );
  }
}
