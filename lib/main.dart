import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

void main() {
  runApp(const CropSensePro());
}

class CropSensePro extends StatelessWidget {
  const CropSensePro({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CropSense Pro',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0F4C3A),
          secondary: Color(0xFFFF8C42),
          tertiary: Color(0xFF6A4E3A),
          surface: Color(0xFFFFFFFF),
          background: Color(0xFFF5F5F0),
          error: Color(0xFFE57373),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Color(0xFF1A2E20),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F0),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          clipBehavior: Clip.antiAlias,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF0F4C3A),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

// --- DATA MODELS ---
class ZoneData {
  final String id;
  final String name;
  final double healthScore;
  final double moisture;
  final double nitrogen;
  final double potassium;
  final double phosphorus;
  final double temperature;
  final double ph;
  final List<String> crops;
  final List<Map<String, dynamic>> alerts;
  final Map<String, double> weeklyMoisture;

  ZoneData({
    required this.id,
    required this.name,
    required this.healthScore,
    required this.moisture,
    required this.nitrogen,
    required this.potassium,
    required this.phosphorus,
    required this.temperature,
    required this.ph,
    required this.crops,
    required this.alerts,
    required this.weeklyMoisture,
  });

  Color get healthColor {
    if (healthScore >= 80) return const Color(0xFF4CAF50);
    if (healthScore >= 60) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  String get healthStatus {
    if (healthScore >= 80) return "Excellent";
    if (healthScore >= 60) return "Good";
    if (healthScore >= 40) return "Fair";
    return "Critical";
  }
}

class SensorReading {
  final String sensorId;
  final String type;
  final double value;
  final String unit;
  final DateTime timestamp;
  final String zoneId;

  SensorReading({
    required this.sensorId,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.zoneId,
  });
}

// --- MAIN NAVIGATION ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _floatController;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ZoneMonitoringScreen(),
    const AIScanScreen(),
    const IrrigationAnalyticsScreen(),
    const MarketplaceScreen(),
    const WeatherForecastScreen(),
    const SustainabilityScreen(),
  ];

  final List<String> _titles = [
    "Dashboard",
    "Zone Monitor",
    "AI Scan",
    "Irrigation",
    "Marketplace",
    "Weather",
    "Sustainability",
  ];

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C3A),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(35),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, "Home"),
              _buildNavItem(1, Icons.grid_3x3_rounded, "Zones"),
              _buildNavItem(2, Icons.qr_code_scanner_rounded, "Scan"),
              _buildNavItem(3, Icons.water_drop_rounded, "Water"),
              _buildNavItem(4, Icons.store_rounded, "Store"),
              _buildNavItem(5, Icons.wb_sunny_rounded, "Weather"),
              _buildNavItem(6, Icons.eco_rounded, "Eco"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        HapticFeedback.lightImpact();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: isSelected ? 26 : 22,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// --- DASHBOARD SCREEN ---
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _greetingController;
  late Animation<double> _fadeAnimation;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _greetingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _fadeAnimation = CurvedAnimation(
      parent: _greetingController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _greetingController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildHeader(),
            ),
          ),
          SliverToBoxAdapter(
            child: _buildQuickStats(),
          ),
          SliverToBoxAdapter(
            child: _buildWeatherCard(),
          ),
          SliverToBoxAdapter(
            child: _buildHealthOverview(),
          ),
          SliverToBoxAdapter(
            child: _buildYieldPrediction(),
          ),
          SliverToBoxAdapter(
            child: _buildRecentAlerts(),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData greetingIcon;
    
    if (hour < 12) {
      greeting = "Good Morning";
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 17) {
      greeting = "Good Afternoon";
      greetingIcon = Icons.wb_sunny;
    } else {
      greeting = "Good Evening";
      greetingIcon = Icons.nightlight_round;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(greetingIcon, size: 20, color: const Color(0xFFFF8C42)),
                    const SizedBox(width: 8),
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  "Rajesh Kumar",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F4C3A),
                  ),
                ),
                const Text(
                  "Your farm is thriving! 🌾",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F4C3A), Color(0xFF1B5E3F)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F4C3A).withOpacity(0.3 + _pulseController.value * 0.2),
                      blurRadius: 12 + _pulseController.value * 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.notifications_none,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      {"label": "Total Zones", "value": "6", "icon": Icons.grid_view, "color": const Color(0xFF0F4C3A), "trend": "+1"},
      {"label": "Active Sensors", "value": "18", "icon": Icons.sensors, "color": const Color(0xFFFF8C42), "trend": "+3"},
      {"label": "Health Score", "value": "86%", "icon": Icons.favorite, "color": const Color(0xFF4CAF50), "trend": "+5%"},
      {"label": "Carbon Saved", "value": "2.4t", "icon": Icons.eco, "color": const Color(0xFF8BC34A), "trend": "+0.3t"},
    ];

    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            width: MediaQuery.of(context).size.width / 4 - 10,
            margin: const EdgeInsets.symmetric(horizontal: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  (stat["color"] as Color).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(stat["icon"] as IconData, color: stat["color"] as Color, size: 24),
                const SizedBox(height: 8),
                Text(
                  stat["value"] as String,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2E20),
                  ),
                ),
                Text(
                  stat["label"] as String,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                ),
                if (stat["trend"] != null)
                  Text(
                    stat["trend"] as String,
                    style: TextStyle(
                      fontSize: 8,
                      color: (stat["trend"] as String).contains('+') ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeatherCard() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C3A), Color(0xFF1B5E3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C3A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.wb_sunny, color: Colors.amber, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    "32°C",
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Sunny • Clear skies",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.water_drop, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  const Text("42%", style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 16),
                  const Icon(Icons.air, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  const Text("12 km/h", style: TextStyle(color: Colors.white70)),
                  const SizedBox(width: 16),
                  const Icon(Icons.visibility, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  const Text("10 km", style: TextStyle(color: Colors.white70)),
                ],
              ),
            ],
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Text("UV Index", style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text("6", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("Moderate", style: TextStyle(color: Colors.white70, fontSize: 8)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Text("AQI", style: TextStyle(color: Colors.white70, fontSize: 10)),
                    Text("82", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    Text("Moderate", style: TextStyle(color: Colors.white70, fontSize: 8)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthOverview() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety, color: Color(0xFF0F4C3A)),
              SizedBox(width: 8),
              Text(
                "Overall Farm Health",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 100,
                        width: 100,
                        child: CircularProgressIndicator(
                          value: 0.86,
                          strokeWidth: 12,
                          backgroundColor: Colors.grey[200],
                          color: const Color(0xFF4CAF50),
                        ),
                      ),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "86%",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F4C3A),
                            ),
                          ),
                          Text(
                            "Excellent",
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    _buildHealthMetric("Soil Health", 0.78, const Color(0xFF8D6E63)),
                    const SizedBox(height: 12),
                    _buildHealthMetric("Water Availability", 0.65, const Color(0xFF42A5F5)),
                    const SizedBox(height: 12),
                    _buildHealthMetric("Nutrient Level", 0.72, const Color(0xFFFF8C42)),
                    const SizedBox(height: 12),
                    _buildHealthMetric("Biodiversity", 0.82, const Color(0xFF4CAF50)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthMetric(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: Colors.grey[200],
            color: color,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "${(value * 100).toInt()}%",
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildYieldPrediction() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFF3E0), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFF8C42).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: Color(0xFFFF8C42)),
              SizedBox(width: 8),
              Text(
                "Yield Prediction",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildYieldPredictionItem("Wheat", "4.2 t/ha", "+12%", Colors.green),
              _buildYieldPredictionItem("Corn", "3.8 t/ha", "+8%", Colors.orange),
              _buildYieldPredictionItem("Rice", "2.9 t/ha", "+5%", Colors.blue),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C42).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFFFF8C42), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Based on current conditions, harvest is expected 15% above average",
                    style: TextStyle(fontSize: 12, color: const Color(0xFFFF8C42)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYieldPredictionItem(String crop, String yield, String change, Color changeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(crop, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(yield, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(change, style: TextStyle(color: changeColor, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRecentAlerts() {
    final alerts = [
      {"message": "Zone A moisture below threshold", "time": "10 min ago", "severity": "critical"},
      {"message": "Nitrogen deficiency in Zone C", "time": "1 hour ago", "severity": "warning"},
      {"message": "Weather alert: Rain expected", "time": "2 hours ago", "severity": "info"},
      {"message": "Pest detection in Zone B", "time": "3 hours ago", "severity": "warning"},
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              "Recent Alerts",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...alerts.map((alert) => _buildAlertItem(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    Color color;
    IconData icon;
    
    switch (alert["severity"]) {
      case "critical":
        color = const Color(0xFFF44336);
        icon = Icons.error_outline;
        break;
      case "warning":
        color = const Color(0xFFFF9800);
        icon = Icons.warning_amber_rounded;
        break;
      default:
        color = const Color(0xFF2196F3);
        icon = Icons.info_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert["message"],
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert["time"],
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }
}

// --- ZONE MONITORING SCREEN ---
class ZoneMonitoringScreen extends StatefulWidget {
  const ZoneMonitoringScreen({super.key});

  @override
  State<ZoneMonitoringScreen> createState() => _ZoneMonitoringScreenState();
}

class _ZoneMonitoringScreenState extends State<ZoneMonitoringScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedZone = "Zone A";
  
  final List<ZoneData> _zones = [
    ZoneData(
      id: "A",
      name: "North Field",
      healthScore: 92,
      moisture: 68,
      nitrogen: 72,
      potassium: 65,
      phosphorus: 58,
      temperature: 24.5,
      ph: 6.8,
      crops: ["Wheat", "Corn"],
      alerts: [
        {"type": "info", "message": "Optimal growth conditions"},
      ],
      weeklyMoisture: {"Mon": 65, "Tue": 66, "Wed": 68, "Thu": 67, "Fri": 68, "Sat": 69, "Sun": 68},
    ),
    ZoneData(
      id: "B",
      name: "East Field",
      healthScore: 78,
      moisture: 45,
      nitrogen: 58,
      potassium: 70,
      phosphorus: 62,
      temperature: 25.2,
      ph: 6.5,
      crops: ["Rice", "Vegetables"],
      alerts: [
        {"type": "warning", "message": "Low moisture detected"},
        {"type": "warning", "message": "Nitrogen levels decreasing"},
      ],
      weeklyMoisture: {"Mon": 52, "Tue": 50, "Wed": 48, "Thu": 46, "Fri": 45, "Sat": 44, "Sun": 45},
    ),
    ZoneData(
      id: "C",
      name: "South Field",
      healthScore: 65,
      moisture: 52,
      nitrogen: 45,
      potassium: 62,
      phosphorus: 48,
      temperature: 26.1,
      ph: 6.2,
      crops: ["Soybeans"],
      alerts: [
        {"type": "critical", "message": "Nitrogen deficiency"},
        {"type": "warning", "message": "Pest risk detected"},
      ],
      weeklyMoisture: {"Mon": 58, "Tue": 56, "Wed": 55, "Thu": 53, "Fri": 52, "Sat": 51, "Sun": 52},
    ),
    ZoneData(
      id: "D",
      name: "West Field",
      healthScore: 88,
      moisture: 72,
      nitrogen: 82,
      potassium: 78,
      phosphorus: 75,
      temperature: 23.8,
      ph: 7.0,
      crops: ["Barley", "Oats"],
      alerts: [
        {"type": "info", "message": "Excellent conditions"},
      ],
      weeklyMoisture: {"Mon": 70, "Tue": 71, "Wed": 72, "Thu": 71, "Fri": 72, "Sat": 73, "Sun": 72},
    ),
    ZoneData(
      id: "E",
      name: "Organic Plot",
      healthScore: 94,
      moisture: 75,
      nitrogen: 88,
      potassium: 85,
      phosphorus: 82,
      temperature: 24.0,
      ph: 6.9,
      crops: ["Organic Vegetables", "Herbs"],
      alerts: [
        {"type": "info", "message": "Premium organic conditions"},
      ],
      weeklyMoisture: {"Mon": 73, "Tue": 74, "Wed": 75, "Thu": 74, "Fri": 75, "Sat": 76, "Sun": 75},
    ),
    ZoneData(
      id: "F",
      name: "Experimental",
      healthScore: 82,
      moisture: 62,
      nitrogen: 75,
      potassium: 70,
      phosphorus: 68,
      temperature: 25.5,
      ph: 6.6,
      crops: ["New Hybrid", "Test Crops"],
      alerts: [
        {"type": "info", "message": "Monitoring new varieties"},
      ],
      weeklyMoisture: {"Mon": 60, "Tue": 61, "Wed": 62, "Thu": 61, "Fri": 62, "Sat": 63, "Sun": 62},
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _zones.length, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedZone = _zones[_tabController.index].name;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildZoneHeader(),
            _buildZoneTabs(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _zones.map((zone) => _buildZoneDetail(zone)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Zone Monitoring",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F4C3A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Real-time crop health across your ${_zones.length} fields",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: const Color(0xFF0F4C3A),
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[600],
        tabs: _zones.map((zone) => Tab(text: zone.id)).toList(),
      ),
    );
  }

  Widget _buildZoneDetail(ZoneData zone) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildHealthScoreCard(zone),
          const SizedBox(height: 20),
          _buildSensorGrid(zone),
          const SizedBox(height: 20),
          _buildMoistureTrend(zone),
          const SizedBox(height: 20),
          _buildCropInfoCard(zone),
          const SizedBox(height: 20),
          _buildZoneAlerts(zone),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(ZoneData zone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [zone.healthColor.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: zone.healthColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    zone.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Health Score",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: zone.healthColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  zone.healthStatus,
                  style: TextStyle(
                    color: zone.healthColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      "${zone.healthScore}%",
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F4C3A),
                      ),
                    ),
                    const Text(
                      "Overall Health",
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SizedBox(
                  height: 100,
                  child: CircularProgressIndicator(
                    value: zone.healthScore / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.grey[200],
                    color: zone.healthColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorGrid(ZoneData zone) {
    final sensors = [
      {"label": "Soil Moisture", "value": zone.moisture, "unit": "%", "icon": Icons.water_drop, "color": const Color(0xFF42A5F5)},
      {"label": "Nitrogen", "value": zone.nitrogen, "unit": "ppm", "icon": Icons.science, "color": const Color(0xFF8D6E63)},
      {"label": "Potassium", "value": zone.potassium, "unit": "ppm", "icon": Icons.eco, "color": const Color(0xFFFF8C42)},
      {"label": "Phosphorus", "value": zone.phosphorus, "unit": "ppm", "icon": Icons.bubble_chart, "color": const Color(0xFF9C27B0)},
      {"label": "Temperature", "value": zone.temperature, "unit": "°C", "icon": Icons.thermostat, "color": const Color(0xFFE57373)},
      {"label": "pH Level", "value": zone.ph, "unit": "", "icon": Icons.opacity, "color": const Color(0xFF4FC3F7)},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.9,
      ),
      itemCount: sensors.length,
      itemBuilder: (context, index) {
        final sensor = sensors[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(sensor["icon"] as IconData, color: sensor["color"] as Color, size: 32),
              const SizedBox(height: 8),
              Text(
                "${sensor["value"]}${sensor["unit"]}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                sensor["label"] as String,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMoistureTrend(ZoneData zone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: Color(0xFF0F4C3A)),
              SizedBox(width: 8),
              Text(
                "Moisture Trend (7 Days)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text("${value.toInt()}%", style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: zone.weeklyMoisture.entries.map((e) => FlSpot(
                      _getDayIndex(e.key).toDouble(),
                      e.value,
                    )).toList(),
                    isCurved: true,
                    color: const Color(0xFF42A5F5),
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF42A5F5).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _getDayIndex(String day) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days.indexOf(day);
  }

  Widget _buildCropInfoCard(ZoneData zone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.grass, color: Color(0xFF0F4C3A)),
              SizedBox(width: 8),
              Text(
                "Current Crops",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: zone.crops.map((crop) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F4C3A).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  crop,
                  style: const TextStyle(
                    color: Color(0xFF0F4C3A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C42).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFFFF8C42), size: 16),
                const SizedBox(width: 8),
                Text(
                  "Next planting season: ${DateFormat('MMM dd').format(DateTime.now().add(const Duration(days: 45)))}",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneAlerts(ZoneData zone) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFFF8C42)),
              SizedBox(width: 8),
              Text(
                "Zone Alerts",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...zone.alerts.map((alert) {
            Color color;
            IconData icon;
            
            switch (alert["type"]) {
              case "critical":
                color = const Color(0xFFF44336);
                icon = Icons.error_outline;
                break;
              case "warning":
                color = const Color(0xFFFF9800);
                icon = Icons.warning_amber_rounded;
                break;
              default:
                color = const Color(0xFF2196F3);
                icon = Icons.info_outline;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert["message"],
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}

// --- AI SCAN SCREEN ---
class AIScanScreen extends StatefulWidget {
  const AIScanScreen({super.key});

  @override
  State<AIScanScreen> createState() => _AIScanScreenState();
}

class _AIScanScreenState extends State<AIScanScreen>
    with TickerProviderStateMixin {

  Uint8List? _imageBytes;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _scanResult;
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scanAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );
  }

  // ✅ FIXED (no extra bracket)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      setState(() {
        _imageBytes = bytes;
        _scanResult = null;
      });
    }
  }

  // ✅ AI ANALYSIS
  Future<void> _analyzeCrops() async {
  if (_imageBytes == null) return;

  setState(() => _isAnalyzing = true);
  _scanController.repeat(reverse: true);

  try {
    const apiKey = "YOUR_NEW_API_KEY";

    final url = Uri.parse(
      "https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey"
    );

    final base64Image = base64Encode(_imageBytes!);

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "Analyze this plant leaf. If diseased, identify it. Return JSON with name, confidence, solution, severity, prevention."
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": base64Image
                }
              }
            ]
          }
        ]
      }),
    );

    final data = jsonDecode(response.body);

    if (data["candidates"] == null) {
  print("API ERROR: ${response.body}");
  throw Exception("Invalid API response");
}

final text = data["candidates"][0]["content"]["parts"][0]["text"];
    final cleanJson = text
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    setState(() {
      _scanResult = jsonDecode(cleanJson);
    });

  } catch (e) {
    print("ERROR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Analysis failed")),
    );
  } finally {
    setState(() => _isAnalyzing = false);
    _scanController.stop();
  }
}

  Future<void> _launchYouTube(String diseaseName) async {
    final query =
        Uri.encodeComponent("how to treat $diseaseName in plants");
    final url = Uri.parse(
        "https://www.youtube.com/results?search_query=$query");

    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Crop Doctor"),
        backgroundColor: const Color(0xFF0F4C3A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildImageDisplay(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            if (_scanResult != null) _buildResultCard(),
          ],
        ),
      ),
    );
  }

  // ✅ IMAGE DISPLAY (WEB SAFE)
  Widget _buildImageDisplay() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[400]!),
      ),
      child: Stack(
        children: [
          _imageBytes == null
              ? const Center(
                  child: Text("Upload a photo of the leaf"))
              : ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.memory(
                    _imageBytes!,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),

          if (_isAnalyzing)
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) => Positioned(
                top: _scanAnimation.value * 300,
                left: 0,
                right: 0,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Camera"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () =>
                    _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text("Gallery"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_imageBytes != null)
          ElevatedButton(
            onPressed:
                _isAnalyzing ? null : _analyzeCrops,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C3A),
              foregroundColor: Colors.white,
              minimumSize:
                  const Size(double.infinity, 50),
            ),
            child: _isAnalyzing
                ? const CircularProgressIndicator(
                    color: Colors.white)
                : const Text("ANALYZE NOW"),
          ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Card(
      margin: const EdgeInsets.only(top: 20),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              _scanResult!['name'].toString(),
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F4C3A)),
            ),
            const SizedBox(height: 5),
            Text(
              "Severity: ${_scanResult!['severity']}",
              style: TextStyle(
                color: _scanResult!['severity'] ==
                        "High"
                    ? Colors.red
                    : Colors.orange,
              ),
            ),
            const Divider(),
            const Text("Solution:",
                style:
                    TextStyle(fontWeight: FontWeight.bold)),
            Text(_scanResult!['solution'].toString()),
            const SizedBox(height: 10),
            const Text("Prevention:",
                style:
                    TextStyle(fontWeight: FontWeight.bold)),
            Text(
                _scanResult!['prevention'].toString()),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              onPressed: () => _launchYouTube(
                  _scanResult!['name'].toString()),
              icon: const Icon(Icons.play_circle_fill,
                  color: Colors.red),
              label:
                  const Text("Watch Treatment Video"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[50],
                foregroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- IRRIGATION ANALYTICS SCREEN ---
class IrrigationAnalyticsScreen extends StatefulWidget {
  const IrrigationAnalyticsScreen({super.key});

  @override
  State<IrrigationAnalyticsScreen> createState() => _IrrigationAnalyticsScreenState();
}

class _IrrigationAnalyticsScreenState extends State<IrrigationAnalyticsScreen> {
  bool isAutoMode = true;
  String selectedZone = "Zone A";
  final List<String> _zones = ["Zone A", "Zone B", "Zone C", "Zone D", "Zone E", "Zone F"];
  
  final Map<String, Map<String, dynamic>> _zoneData = {
    "Zone A": {"moisture": 68, "schedule": "06:30, 17:30", "status": "optimal", "waterUsage": 320, "efficiency": 85},
    "Zone B": {"moisture": 45, "schedule": "07:00, 18:00", "status": "critical", "waterUsage": 280, "efficiency": 72},
    "Zone C": {"moisture": 52, "schedule": "06:45, 17:45", "status": "warning", "waterUsage": 350, "efficiency": 78},
    "Zone D": {"moisture": 72, "schedule": "06:15, 17:15", "status": "optimal", "waterUsage": 290, "efficiency": 88},
    "Zone E": {"moisture": 75, "schedule": "06:00, 17:00", "status": "optimal", "waterUsage": 310, "efficiency": 90},
    "Zone F": {"moisture": 62, "schedule": "07:15, 18:15", "status": "warning", "waterUsage": 380, "efficiency": 82},
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildZoneSelector(),
              const SizedBox(height: 20),
              _buildMoistureCard(),
              const SizedBox(height: 20),
              _buildModeToggle(),
              const SizedBox(height: 20),
              _buildScheduleCard(),
              const SizedBox(height: 20),
              _buildWaterUsageChart(),
              const SizedBox(height: 20),
              _buildEfficiencyCard(),
              const SizedBox(height: 20),
              _buildRecommendationCard(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.water_drop, size: 28, color: Color(0xFF0F4C3A)),
        SizedBox(width: 12),
        Text(
          "Smart Irrigation",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F4C3A),
          ),
        ),
      ],
    );
  }

  Widget _buildZoneSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(30),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedZone,
          items: _zones.map((zone) {
            return DropdownMenuItem(
              value: zone,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(zone),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              selectedZone = value!;
            });
          },
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildMoistureCard() {
    final data = _zoneData[selectedZone]!;
    final moisture = data["moisture"] as double;
    final status = data["status"] as String;
    
    Color statusColor;
    if (status == "optimal") statusColor = const Color(0xFF4CAF50);
    else if (status == "warning") statusColor = const Color(0xFFFF9800);
    else statusColor = const Color(0xFFF44336);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "Current Soil Moisture",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: CircularProgressIndicator(
                  value: moisture / 100,
                  strokeWidth: 12,
                  backgroundColor: Colors.grey[200],
                  color: statusColor,
                ),
              ),
              Column(
                children: [
                  Text(
                    "${moisture.toInt()}%",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F4C3A),
                    ),
                  ),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            "Target Range: 60-80%",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isAutoMode = true);
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isAutoMode ? const Color(0xFF0F4C3A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: isAutoMode ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Auto Mode",
                      style: TextStyle(
                        color: isAutoMode ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => isAutoMode = false);
                HapticFeedback.lightImpact();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !isAutoMode ? const Color(0xFF0F4C3A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app,
                      color: !isAutoMode ? Colors.white : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Manual",
                      style: TextStyle(
                        color: !isAutoMode ? Colors.white : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    final data = _zoneData[selectedZone]!;
    final schedule = data["schedule"] as String;
    final schedules = schedule.split(", ");
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule, color: Color(0xFF0F4C3A)),
              SizedBox(width: 8),
              Text(
                "Irrigation Schedule",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Morning", style: TextStyle(fontWeight: FontWeight.w500)),
              Text(schedules[0], style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Evening", style: TextStyle(fontWeight: FontWeight.w500)),
              Text(schedules[1], style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF8C42).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(Icons.water_drop, color: Color(0xFFFF8C42), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Smart scheduling based on weather forecast and soil moisture",
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterUsageChart() {
    final data = _zoneData[selectedZone]!;
    final usage = data["waterUsage"] as int;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFF0F4C3A)),
              SizedBox(width: 8),
              Text(
                "Weekly Water Usage",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 500,
                barGroups: _getWeeklyData(),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          "${value.toInt()}L",
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(
                          days[value.toInt()],
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(show: true),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F4C3A).withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total this week:", style: TextStyle(fontSize: 12)),
                Text(
                  "${_getWeeklyTotal()} L",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F4C3A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _getWeeklyTotal() {
    final data = [320, 280, 350, 290, 310, 380, 290];
    return data.reduce((a, b) => a + b);
  }

  List<BarChartGroupData> _getWeeklyData() {
    final data = [320, 280, 350, 290, 310, 380, 290];
    return List.generate(7, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: data[index].toDouble(),
            color: const Color(0xFF0F4C3A),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  Widget _buildEfficiencyCard() {
    final data = _zoneData[selectedZone]!;
    final efficiency = data["efficiency"] as int;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFE8F5E9), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Irrigation Efficiency",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: efficiency / 100,
                  backgroundColor: Colors.grey[200],
                  color: efficiency > 85 ? Colors.green : efficiency > 70 ? Colors.orange : Colors.red,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "$efficiency%",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            efficiency > 85 ? "Excellent water usage efficiency" :
            efficiency > 70 ? "Good efficiency, room for improvement" :
            "Low efficiency, check for leaks or over-irrigation",
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard() {
    final data = _zoneData[selectedZone]!;
    final moisture = data["moisture"] as double;
    String recommendation;
    Color color;
    
    if (moisture < 50) {
      recommendation = "Critical moisture level. Immediate irrigation required for $selectedZone";
      color = const Color(0xFFF44336);
    } else if (moisture < 60) {
      recommendation = "Low moisture. Consider watering in the next 6 hours";
      color = const Color(0xFFFF9800);
    } else if (moisture > 80) {
      recommendation = "High moisture. Skip next irrigation cycle";
      color = const Color(0xFF2196F3);
    } else {
      recommendation = "Optimal moisture levels. Maintain current schedule";
      color = const Color(0xFF4CAF50);
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI Recommendation",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  recommendation,
                  style: TextStyle(color: color, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- MARKETPLACE SCREEN ---
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  String _selectedCategory = "All";
  final List<String> _categories = ["All", "Fertilizers", "Seeds", "Tools", "Sensors", "Irrigation", "Organic"];
  
  final List<Map<String, dynamic>> _products = [
    {"name": "Organic Fertilizer", "price": 450, "oldPrice": 550, "unit": "5kg", "emoji": "🌱", "rating": 4.5, "sold": 234, "category": "Fertilizers", "organic": true},
    {"name": "Neem Oil Spray", "price": 320, "oldPrice": 400, "unit": "1L", "emoji": "🌿", "rating": 4.3, "sold": 189, "category": "Fertilizers", "organic": true},
    {"name": "Premium Wheat Seeds", "price": 280, "oldPrice": 350, "unit": "Pack", "emoji": "🌾", "rating": 4.8, "sold": 567, "category": "Seeds", "organic": false},
    {"name": "Smart Sensor Kit", "price": 2499, "oldPrice": 2999, "unit": "Kit", "emoji": "📡", "rating": 4.7, "sold": 78, "category": "Sensors", "organic": false},
    {"name": "Drip Irrigation Set", "price": 1899, "oldPrice": 2299, "unit": "Set", "emoji": "💧", "rating": 4.6, "sold": 145, "category": "Irrigation", "organic": false},
    {"name": "Compost Maker", "price": 899, "oldPrice": 1099, "unit": "Unit", "emoji": "♻️", "rating": 4.4, "sold": 92, "category": "Tools", "organic": true},
    {"name": "Organic Pesticide", "price": 380, "oldPrice": 480, "unit": "500ml", "emoji": "🪲", "rating": 4.5, "sold": 156, "category": "Fertilizers", "organic": true},
    {"name": "Soil Tester", "price": 1299, "oldPrice": 1599, "unit": "Device", "emoji": "🧪", "rating": 4.6, "sold": 203, "category": "Tools", "organic": false},
    {"name": "Hybrid Corn Seeds", "price": 350, "oldPrice": 420, "unit": "Pack", "emoji": "🌽", "rating": 4.7, "sold": 432, "category": "Seeds", "organic": false},
    {"name": "Smart Water Timer", "price": 1599, "oldPrice": 1999, "unit": "Unit", "emoji": "⏲️", "rating": 4.5, "sold": 67, "category": "Irrigation", "organic": false},
  ];

  List<Map<String, dynamic>> get _filteredProducts {
    if (_selectedCategory == "All") {
      return _products;
    }
    return _products.where((p) => p["category"] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildBanner(),
            ),
            SliverToBoxAdapter(
              child: _buildCategories(),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildProductCard(_filteredProducts[index]),
                  childCount: _filteredProducts.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Row(
        children: [
          Icon(Icons.store, size: 28, color: Color(0xFF0F4C3A)),
          SizedBox(width: 12),
          Text(
            "Agri-Marketplace",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F4C3A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C3A), Color(0xFF1B5E3F)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Special Offer!",
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Get 20% off on all organic products",
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Shop Now →",
                    style: TextStyle(color: Color(0xFF0F4C3A), fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Text("🎉", style: TextStyle(fontSize: 60)),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 45,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F4C3A) : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey[300]!,
                ),
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F0),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Center(
              child: Text(
                product["emoji"],
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product["name"],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      product["rating"].toString(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product["unit"],
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                    if (product["organic"] == true) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Organic",
                          style: TextStyle(fontSize: 8, color: Color(0xFF4CAF50)),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      "₹${product["price"]}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0F4C3A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "₹${product["oldPrice"]}",
                      style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  "${product["sold"]} sold",
                  style: TextStyle(color: Colors.grey[500], fontSize: 10),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C3A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Add to Cart",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- WEATHER FORECAST SCREEN ---
class WeatherForecastScreen extends StatefulWidget {
  const WeatherForecastScreen({super.key});

  @override
  State<WeatherForecastScreen> createState() => _WeatherForecastScreenState();
}

class _WeatherForecastScreenState extends State<WeatherForecastScreen> {
  final List<Map<String, dynamic>> _hourlyForecast = [
    {"time": "Now", "temp": 32, "icon": Icons.wb_sunny, "condition": "Sunny"},
    {"time": "11 AM", "temp": 33, "icon": Icons.wb_sunny, "condition": "Sunny"},
    {"time": "12 PM", "temp": 34, "icon": Icons.wb_sunny, "condition": "Hot"},
    {"time": "1 PM", "temp": 35, "icon": Icons.wb_sunny, "condition": "Very Hot"},
    {"time": "2 PM", "temp": 34, "icon": Icons.cloud, "condition": "Partly Cloudy"},
    {"time": "3 PM", "temp": 33, "icon": Icons.cloud, "condition": "Partly Cloudy"},
    {"time": "4 PM", "temp": 32, "icon": Icons.cloud, "condition": "Cloudy"},
    {"time": "5 PM", "temp": 30, "icon": Icons.cloud, "condition": "Cloudy"},
  ];

  final List<Map<String, dynamic>> _dailyForecast = [
    {"day": "Monday", "high": 32, "low": 24, "icon": Icons.wb_sunny, "rain": 10},
    {"day": "Tuesday", "high": 31, "low": 23, "icon": Icons.cloud, "rain": 20},
    {"day": "Wednesday", "high": 30, "low": 22, "icon": Icons.cloud, "rain": 40},
    {"day": "Thursday", "high": 29, "low": 22, "icon": Icons.grain, "rain": 60},
    {"day": "Friday", "high": 28, "low": 21, "icon": Icons.grain, "rain": 70},
    {"day": "Saturday", "high": 30, "low": 22, "icon": Icons.cloud, "rain": 30},
    {"day": "Sunday", "high": 31, "low": 23, "icon": Icons.wb_sunny, "rain": 10},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildCurrentWeather(),
            ),
            SliverToBoxAdapter(
              child: _buildHourlyForecast(),
            ),
            SliverToBoxAdapter(
              child: _buildDailyForecast(),
            ),
            SliverToBoxAdapter(
              child: _buildWeatherTips(),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Row(
        children: [
          Icon(Icons.wb_sunny, size: 28, color: Color(0xFF0F4C3A)),
          SizedBox(width: 12),
          Text(
            "Weather Forecast",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F4C3A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentWeather() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C3A), Color(0xFF1B5E3F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Nashik, Maharashtra",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Tuesday, 10:30 AM",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.location_on, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  const Text(
                    "32°C",
                    style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Text("Feels like 34°C", style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text("Sunny", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const Icon(Icons.wb_sunny, color: Colors.amber, size: 80),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildWeatherStat(Icons.water_drop, "Humidity", "42%"),
              _buildWeatherStat(Icons.air, "Wind", "12 km/h"),
              _buildWeatherStat(Icons.visibility, "Visibility", "10 km"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherStat(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hourly Forecast",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _hourlyForecast.length,
              separatorBuilder: (_, __) => const SizedBox(width: 16),
              itemBuilder: (context, index) {
                final item = _hourlyForecast[index];
                return Column(
                  children: [
                    Text(item["time"], style: const TextStyle(fontSize: 12)),
                    const SizedBox(height: 8),
                    Icon(item["icon"], color: const Color(0xFFFF8C42), size: 28),
                    const SizedBox(height: 8),
                    Text("${item["temp"]}°C", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyForecast() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "7-Day Forecast",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ..._dailyForecast.map((day) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(
                      day["day"],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(day["icon"], color: const Color(0xFFFF8C42), size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: (day["rain"] as int) / 100,
                      backgroundColor: Colors.blue[100],
                      color: Colors.blue,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 40,
                    child: Text(
                      "${day["rain"]}%",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "${day["high"]}°/${day["low"]}°",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWeatherTips() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFFFF3E0), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFF8C42).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFFFF8C42)),
              SizedBox(width: 8),
              Text(
                "Weather Tips",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            "• Light rain expected on Thursday. Consider postponing irrigation.\n\n• High temperatures today - ensure adequate watering for sensitive crops.\n\n• Good conditions for spraying pesticides tomorrow morning.",
            style: TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// --- SUSTAINABILITY SCREEN ---
class SustainabilityScreen extends StatefulWidget {
  const SustainabilityScreen({super.key});

  @override
  State<SustainabilityScreen> createState() => _SustainabilityScreenState();
}

class _SustainabilityScreenState extends State<SustainabilityScreen> {
  double _carbonSaved = 2.4;
  double _waterSaved = 12500;
  double _energySaved = 850;
  int _treesPlanted = 24;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            SliverToBoxAdapter(
              child: _buildImpactStats(),
            ),
            SliverToBoxAdapter(
              child: _buildCarbonFootprint(),
            ),
            SliverToBoxAdapter(
              child: _buildEcoActions(),
            ),
            SliverToBoxAdapter(
              child: _buildAchievements(),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: const Row(
        children: [
          Icon(Icons.eco, size: 28, color: Color(0xFF0F4C3A)),
          SizedBox(width: 12),
          Text(
            "Sustainability",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F4C3A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactStats() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFE8F5E9), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          const Text(
            "Your Environmental Impact",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImpactCard(Icons.eco, "Carbon Saved", "$_carbonSaved t", "+0.3 this month"),
              _buildImpactCard(Icons.water_drop, "Water Saved", "${(_waterSaved / 1000).toStringAsFixed(1)}k L", "+2.1k L"),
              _buildImpactCard(Icons.electric_bolt, "Energy Saved", "$_energySaved kWh", "+120 kWh"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(IconData icon, String label, String value, String trend) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF0F4C3A), size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[600])),
          Text(trend, style: const TextStyle(fontSize: 8, color: Colors.green)),
        ],
      ),
    );
  }

  Widget _buildCarbonFootprint() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Carbon Footprint Tracker",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Current vs Industry Average"),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: 0.68,
                        backgroundColor: Colors.red[100],
                        color: Colors.green,
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Your Farm: 1.2 t", style: const TextStyle(fontSize: 10)),
                        Text("Industry Avg: 3.8 t", style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Text("68%", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text("Less Carbon", style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEcoActions() {
    final actions = [
      {"icon": Icons.water_drop, "title": "Rainwater Harvesting", "points": 150, "completed": true},
      {"icon": Icons.compost, "title": "Start Composting", "points": 100, "completed": true},
      {"icon": Icons.forest, "title": "Plant 10 Trees", "points": 200, "completed": false},
      {"icon": Icons.solar_power, "title": "Install Solar Panel", "points": 500, "completed": false},
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Eco-Actions",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...actions.map((action) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: action["completed"] == true ? Colors.green.withOpacity(0.05) : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C3A).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action["icon"] as IconData, color: const Color(0xFF0F4C3A)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(action["title"].toString(), style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text("+${action["points"]} Eco Points", style: TextStyle(fontSize: 10, color: Colors.green)),
                      ],
                    ),
                  ),
                  if (action["completed"] == true)
                    const Icon(Icons.check_circle, color: Colors.green)
                  else
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C3A),
                        minimumSize: const Size(60, 30),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      child: const Text("Start", style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    final achievements = [
      {"icon": Icons.emoji_events, "title": "Water Saver", "description": "Saved 10,000L of water", "earned": true},
      {"icon": Icons.forest, "title": "Green Warrior", "description": "Planted 20 trees", "earned": false},
      {"icon": Icons.eco, "title": "Carbon Champion", "description": "Reduced carbon by 2 tons", "earned": true},
      {"icon": Icons.science, "title": "Soil Guardian", "description": "Improved soil health by 30%", "earned": false},
    ];

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Achievements",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((achievement) {
              return Container(
                width: (MediaQuery.of(context).size.width - 64) / 2,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: achievement["earned"] == true ? Colors.green.withOpacity(0.05) : Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: achievement["earned"] == true ? Colors.green.withOpacity(0.3) : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      achievement["icon"] as IconData,
                      color: achievement["earned"] == true ? Colors.amber : Colors.grey[400],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement["title"].toString(),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: achievement["earned"] == true ? Colors.black87 : Colors.grey[600],
                            ),
                          ),
                          Text(
                            achievement["description"].toString(),
                            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    if (achievement["earned"] == true)
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}