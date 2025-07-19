import 'package:doctordesktop/Admin/AdminAuthDialod.dart';
import 'package:doctordesktop/Admin/ReceptionAuthDialog.dart';
import 'package:doctordesktop/AuthSplash.dart';
import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
import 'package:doctordesktop/Doctor/fetchDoctor.dart';
import 'package:doctordesktop/External/CommonScreen.dart';
import 'package:doctordesktop/Lab/LabDashBoard.dart';
import 'package:doctordesktop/Lab/LabScreen.dart';
import 'package:doctordesktop/Nurse/NurseAdminDashboardScreen.dart';
import 'package:doctordesktop/Nurse/NurseDashBoardScreen.dart';
import 'package:doctordesktop/Nurse/NurseLoginScreen.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
import 'package:doctordesktop/Provider.dart';
import 'package:doctordesktop/authProvider/auth_provider.dart';
import 'package:doctordesktop/constants/Assets.dart';
import 'package:doctordesktop/constants/Methods.dart';
import 'package:doctordesktop/logoBook.dart';
import 'package:doctordesktop/pharmacy/PharmacyDashboard.dart';
import 'package:doctordesktop/pharmacy/pharmaTheme.dart';
import 'package:doctordesktop/reception/ReceptionDashboard.dart';
import 'package:doctordesktop/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:window_size/window_size.dart' as window_size;
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    window_size.setWindowTitle('DocneX Care Desktop');
    window_size.setWindowMinSize(const Size(1200, 800));
    window_size.setWindowMaxSize(Size.infinite);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DocneX Care Desktop',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF005F9E),
        fontFamily: 'Roboto',
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF005F9E),
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.light,
      home: const HomePage(),
    );
  }
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late DateTime _currentTime;
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  bool _isSidebarExpanded = true;

  final List<Map<String, dynamic>> _todoItems = [
    {'text': 'Track appointments with Docnex Scheduler', 'done': false},
    {'text': 'Access digital prescriptions in one tap', 'done': false},
    {'text': 'Monitor patient vitals with live updates', 'done': false},
    {'text': 'Securely share reports with patients', 'done': false},
    {'text': 'Experience faster billing with Docnex', 'done': false},
  ];

  // Navigation items for the sidebar

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _toggleSidebar() {
    setState(() {
      _isSidebarExpanded = !_isSidebarExpanded;
    });
  }
// This code should be integrated into your _HomePageState class

  void _navigateToDoctorScreen() async {
    // Check token directly from repository
    final authRepository = ref.read(authRepositoryProvider);
    final token = await authRepository.getToken();
    final userType = await authRepository.getUsertype();

    print(
        "Navigation check - Token: ${token != null ? 'exists' : 'null'}, UserType: $userType");

    if (token != null && (userType == 'doctor' || userType == 'external')) {
      // Navigate directly to doctor main screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DoctorMainScreen()),
      );
    } else {
      // Not logged in, go to login
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen1()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Responsive sizing
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isSmallScreen = screenWidth < 1200;

    // Calculate sidebar width based on expansion state and screen size
    final double sidebarWidth =
        _isSidebarExpanded ? (isSmallScreen ? 70 : 250) : 70;
    final isLoggedIn = ref.watch(authControllerProvider);
    final userType = ref.watch(userTypeProvider);

    print("HomePage build - LoggedIn: $isLoggedIn, UserType: $userType");
    // Main theme colors
    final Color primaryColor = const Color(0xFF005F9E);
    final Color backgroundColor =
        _isDarkMode ? Colors.grey[900]! : Colors.white;
    final Color textColor = _isDarkMode ? Colors.white : Colors.black87;
    final Color cardColor = _isDarkMode ? Colors.grey[800]! : Colors.white;
    final Color shadowColor = _isDarkMode ? Colors.black54 : Colors.black12;

    return Scaffold(
      body: Row(
        children: [
          // Fixed Sidebar
          // Fixed Sidebar with modern design and logo area

          // Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top app bar
                // Full-Width Google-style Search Bar for Top App Bar
                Container(
                  height: 64,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        // ADD LARGE LOGO HERE
                        Container(
                          padding: const EdgeInsets.only(right: 18),
                          child: Image.asset(
                            '${AppImages.logo}',
                            height: 48, // Larger logo size
                            fit: BoxFit.contain,
                          ),
                        ),

                        // Google-style Search box - takes maximum available space
                        Expanded(
                          child: Container(
                            height: 44,
                            margin: EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color:
                                  _isDarkMode ? Colors.grey[800] : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: _isDarkMode
                                    ? Colors.grey[700]!
                                    : Colors.grey[300]!,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _isDarkMode
                                      ? Colors.black.withOpacity(0.2)
                                      : Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(
                                      left: 12.0, right: 8.0),
                                  child: Icon(
                                    Icons.search,
                                    color: _isDarkMode
                                        ? Colors.white70
                                        : Colors.grey[600],
                                    size: 20,
                                  ),
                                ),
                                // Text field takes most of the available space
                                Expanded(
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Search or enter website...',
                                      hintStyle: TextStyle(
                                        color: _isDarkMode
                                            ? Colors.white38
                                            : Colors.grey[400],
                                        fontSize: 14,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 12),
                                    ),
                                    style: TextStyle(
                                      color: _isDarkMode
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 14,
                                    ),
                                    textInputAction: TextInputAction.search,
                                    onSubmitted: (value) {
                                      if (value.isNotEmpty) {
                                        // Check if it's a URL or search query
                                        if (value.startsWith('www.') ||
                                            value.startsWith('http')) {
                                          String url = value;
                                          if (value.startsWith('www.')) {
                                            url = 'https://$value';
                                          }
                                          Methods().openUrl(url);
                                        } else {
                                          // Treat as a search query
                                          String searchUrl =
                                              'https://www.google.com/search?q=${Uri.encodeComponent(value)}';
                                          Methods().openUrl(searchUrl);
                                        }
                                      }
                                    },
                                  ),
                                ),
                                // Google website shortcut button
                                InkWell(
                                  onTap: () {
                                    Methods().openUrl('https://www.google.com');
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    margin: EdgeInsets.only(right: 6),
                                    decoration: BoxDecoration(
                                      color: _isDarkMode
                                          ? Colors.grey[700]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Image.network(
                                          'https://www.google.com/favicon.ico',
                                          width: 16,
                                          height: 16,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Icon(
                                              Icons.public,
                                              size: 16,
                                              color: primaryColor,
                                            );
                                          },
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Google',
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Action icons on the right
                        Row(
                          children: [
                            // Rest of your action icons...
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Main content
                Expanded(
                  child: Container(
                    color: _isDarkMode
                        ? const Color(0xFF121212)
                        : const Color(0xFFF5F7FA),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildPageContent(
                          context,
                          screenWidth,
                          screenHeight,
                          cardColor,
                          primaryColor,
                          textColor,
                          shadowColor),
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

  Widget _buildPageContent(
      BuildContext context,
      double screenWidth,
      double screenHeight,
      Color cardColor,
      Color primaryColor,
      Color textColor,
      Color shadowColor) {
    // Enhanced responsive breakpoints
    final bool isExtraLarge = screenWidth >= 1920; // 4K and ultra-wide
    final bool isLarge =
        screenWidth >= 1600 && screenWidth < 1920; // Large desktop
    final bool isMedium =
        screenWidth >= 1400 && screenWidth < 1600; // Medium desktop
    final bool isSmall =
        screenWidth >= 1200 && screenWidth < 1400; // Small desktop
    final bool isCompact =
        screenWidth < 1200; // Compact (fallback to mobile-like)

    if (isCompact) {
      // Stack content for very small screens
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClockWidget(cardColor, primaryColor, textColor, shadowColor),
            const SizedBox(height: 16),
            _buildToDoList(cardColor, primaryColor, textColor),
            const SizedBox(height: 16),
            _buildApplications(
                cardColor, primaryColor, textColor, shadowColor, true),
            const SizedBox(height: 16),
            _buildQuoteWidget(cardColor, textColor),
            const SizedBox(height: 16),
            _buildPhotosSection(cardColor, textColor),
          ],
        ),
      );
    } else {
      // Responsive two-column layout for all desktop sizes
      return LayoutBuilder(
        builder: (context, constraints) {
          // Calculate dynamic spacing based on available width
          final double horizontalSpacing =
              constraints.maxWidth * 0.015; // 1.5% of width
          final double verticalSpacing =
              constraints.maxHeight * 0.02; // 2% of height

          return Column(
            children: [
              // First row with dynamic flex ratios
              Expanded(
                flex: isExtraLarge ? 6 : 5, // More space for larger screens
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo widget - responsive flex
                    Expanded(
                      flex: isExtraLarge ? 6 : (isLarge ? 5 : 5),
                      child: _buildLogoWidget(
                          cardColor, primaryColor, textColor, shadowColor),
                    ),
                    SizedBox(width: horizontalSpacing),

                    // Clock widget - consistent size across screens
                    Expanded(
                      flex: isExtraLarge ? 3 : (isLarge ? 3 : 3),
                      child: _buildClockWidget(
                          cardColor, primaryColor, textColor, shadowColor),
                    ),
                    SizedBox(width: horizontalSpacing),

                    // Applications - adaptive flex
                    Expanded(
                      flex: isExtraLarge ? 5 : (isLarge ? 5 : 5),
                      child: _buildApplications(cardColor, primaryColor,
                          textColor, shadowColor, false),
                    ),
                  ],
                ),
              ),
              SizedBox(height: verticalSpacing),

              // Second row with responsive layout
              Expanded(
                flex: isExtraLarge ? 4 : 4,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Quote widget
                    Expanded(
                      flex: isExtraLarge ? 3 : (isLarge ? 3 : 3),
                      child: _buildQuoteWidget(cardColor, textColor),
                    ),
                    SizedBox(width: horizontalSpacing),

                    // Photos section - takes remaining space
                    Expanded(
                      flex: isExtraLarge ? 8 : (isLarge ? 7 : 7),
                      child: _buildPhotosSection(cardColor, textColor),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildLogoWidget(
      Color cardColor, Color primaryColor, Color textColor, Color shadowColor) {
    // Create a content page widget that will be revealed
    Widget contentPage =
        buildContentPage(cardColor, primaryColor, textColor, shadowColor);

    // Create a front page widget (your existing logo widget)
    Widget frontPage =
        buildLogoFrontPage(cardColor, primaryColor, textColor, shadowColor);

    // Wrap them in the BookOpenAnimation
    return BookOpenAnimation(
      frontPage: frontPage,
      contentPage: contentPage,
    );
  }

// Helper method for the gold-accented stats items
  Widget _buildGoldStatItem(IconData icon, String value, String label,
      Color primaryColor, Color textColor, bool isSmallSpace) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFFEABF56).withOpacity(0.8), // Gold icon
          size: isSmallSpace ? 16 : 18,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallSpace ? 12 : 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallSpace ? 10 : 12,
            color: textColor.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildClockWidget(
      Color cardColor, Color primaryColor, Color textColor, Color shadowColor) {
    String formattedTime =
        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}';
    String weekday = _getWeekday(_currentTime.weekday);
    String formattedDate =
        '$weekday, ${_currentTime.day} ${_getMonth(_currentTime.month)} ${_currentTime.year}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'DocNeX.care',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Clock face
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),

                  // Clock face markers
                  for (int i = 0; i < 12; i++)
                    Positioned.fill(
                      child: Transform.rotate(
                        angle: i * 30 * 3.14 / 180,
                        child: Align(
                          alignment: const Alignment(0, -0.85),
                          child: Container(
                            width: 3,
                            height: i % 3 == 0 ? 12 : 6,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ),

                  // Hour hand
                  Transform.rotate(
                    angle:
                        (_currentTime.hour * 30 + _currentTime.minute * 0.5) *
                            3.14 /
                            180,
                    child: Container(
                      height: 45,
                      width: 4,
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      alignment: Alignment.topCenter,
                    ),
                  ),

                  // Minute hand
                  Transform.rotate(
                    angle: _currentTime.minute * 6 * 3.14 / 180,
                    child: Container(
                      height: 60,
                      width: 3,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00B8D4),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      alignment: Alignment.topCenter,
                    ),
                  ),

                  // Second hand
                  Transform.rotate(
                    angle: _currentTime.second * 6 * 3.14 / 180,
                    child: Container(
                      height: 70,
                      width: 1,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF5350),
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      alignment: Alignment.topCenter,
                    ),
                  ),

                  // Center dot
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            formattedTime,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: primaryColor,
              height: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formattedDate,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: textColor.withOpacity(0.7),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToDoList(Color cardColor, Color primaryColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What Docnex Helps You Achieve Today',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _todoItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildToDoItem(
                  _todoItems[index]['done'],
                  _todoItems[index]['text'],
                  cardColor,
                  textColor,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Add task button
        ],
      ),
    );
  }

  Widget _buildToDoItem(
      bool isChecked, String text, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: _isDarkMode ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isChecked ? const Color(0xFF005F9E) : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF005F9E), width: 2),
            ),
            child: isChecked
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                decoration: isChecked ? TextDecoration.lineThrough : null,
                decorationThickness: 2,
                color: isChecked ? textColor.withOpacity(0.6) : textColor,
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: textColor.withOpacity(0.5),
            ),
            onPressed: () {
              // Show options
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApplications(Color cardColor, Color primaryColor,
      Color textColor, Color shadowColor, bool isSmallScreen) {
    // Application data with premium flag added
    final List<Map<String, dynamic>> apps = [
      {
        'name': 'Hospital',
        'icon': Icons.local_hospital,
        'screen': 'HospitalScreen',
        'color': const Color(0xFF2196F3),
        'isPremium': true, // Premium feature
      },
      {
        'name': 'Reception',
        'icon': Icons.people,
        'screen': 'PatientsScreen',
        'color': const Color(0xFF4CAF50),
        'isPremium': false,
      },
      {
        'name': 'Doctor',
        'icon': Icons.medical_services,
        'screen': 'DoctorsScreen',
        'color': const Color(0xFF9C27B0),
        'isPremium': true, // Premium feature
      },
      {
        'name': 'Nurses',
        'icon': Icons.personal_injury,
        'screen': 'NursesScreen',
        'color': const Color(0xFFFF9800),
        'isPremium': false,
      },
      {
        'name': 'Pharmacy',
        'icon': Icons.local_pharmacy,
        'screen': 'PharmacyScreen',
        'color': const Color(0xFFF44336),
        'isPremium': true, // Premium feature
      },
      {
        'name': 'Laboratory',
        'icon': Icons.biotech,
        'screen': 'LabScreen',
        'color': const Color(0xFF009688),
        'isPremium': true, // Premium feature
      },
      {
        'name': 'Admin',
        'icon': Icons.description,
        'screen': 'Admin',
        'color': const Color(0xFF3F51B5),
        'isPremium': true, // Premium feature
      },
      {
        'name': 'Nurse Admin',
        'icon': Icons.settings,
        'screen': 'NurseAdmin',
        'color': const Color(0xFF607D8B),
        'isPremium': false,
      },
      {
        'name': 'Calendar',
        'icon': Icons.calendar_today,
        'screen': 'CalendarScreen',
        'color': const Color(0xFFE91E63),
        'isPremium': false,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16), // Reduced padding
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4), // Reduced vertical padding
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, primaryColor.withOpacity(0.8)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.apps_rounded,
                      color: Colors.white,
                      size: 18, // Smaller icon
                    ),
                    const SizedBox(width: 6), // Reduced spacing
                    Text(
                      'APPLICATIONS',
                      style: TextStyle(
                        fontSize: 16, // Smaller font
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.8, // Reduced letter spacing
                      ),
                    ),
                  ],
                ),
              ),
              // Premium legend
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFEABF56).withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEABF56).withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      color: Color(0xFFEABF56),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Premium Modules',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Reduced spacing
          Expanded(
            child: GridView.builder(
              physics: const BouncingScrollPhysics(), // Add smooth scrolling
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 2 : 3,
                crossAxisSpacing: 12, // Reduced spacing
                mainAxisSpacing: 12, // Reduced spacing
                childAspectRatio:
                    isSmallScreen ? 1.0 : 1.1, // Adjusted aspect ratio
              ),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                return _buildAppItem(
                  apps[index]['name'],
                  apps[index]['icon'],
                  apps[index]['screen'],
                  apps[index]['color'],
                  textColor,
                  shadowColor,
                  apps[index]['isPremium'], // Pass premium status
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveAppItem(
    String name,
    IconData icon,
    String screenName,
    Color itemColor,
    Color textColor,
    Color shadowColor,
    bool isPremium,
    BoxConstraints constraints,
  ) {
    final List<Color> goldGradientColors = const [
      Color(0xFFF9DB9D),
      Color(0xFFEABF56),
    ];

    // Calculate responsive sizes
    final double iconSize = constraints.maxWidth > 1600 ? 26 : 24;
    final double nameSize = constraints.maxWidth > 1600 ? 17 : 16;
    final double premiumIconSize = constraints.maxWidth > 1600 ? 15 : 14;
    final double premiumTextSize = constraints.maxWidth > 1600 ? 11 : 10;
    final double backgroundIconSize = constraints.maxWidth > 1600 ? 90 : 80;
    final double paddingSize = constraints.maxWidth > 1600 ? 14 : 12;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: itemColor.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: itemColor,
          child: InkWell(
            onTap: () => _handleAppNavigation(screenName),
            child: Stack(
              children: [
                // Background icon
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    icon,
                    size: backgroundIconSize,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),

                // Content
                Padding(
                  padding: EdgeInsets.all(paddingSize),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon container
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: itemColor.withOpacity(0.2),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: itemColor,
                          size: iconSize,
                        ),
                      ),
                      // App name and underline
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: nameSize,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: 3,
                            width: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Premium badge
                if (isPremium)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: constraints.maxWidth > 1600 ? 9 : 8,
                        vertical: constraints.maxWidth > 1600 ? 5 : 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: goldGradientColors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: const Color(0xFF5D4037),
                            size: premiumIconSize,
                          ),
                          SizedBox(width: constraints.maxWidth > 1600 ? 4 : 3),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: const Color(0xFF5D4037),
                              fontWeight: FontWeight.w800,
                              fontSize: premiumTextSize,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAppNavigation(String screenName) {
    // Add your existing navigation logic here
    switch (screenName) {
      case 'HospitalScreen':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SplashScreen1()),
        );
        break;
      case 'PatientsScreen':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReceptionDashBoard()),
        );
        break;
      // Add other cases as needed...
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Opening $screenName')),
        );
    }
  }

// Updated _buildAppItem method with premium badge
  Widget _buildAppItem(String name, IconData icon, String screenName,
      Color itemColor, Color textColor, Color shadowColor, bool isPremium) {
    // Premium gold gradient colors
    final List<Color> goldGradientColors = const [
      Color(0xFFF9DB9D), // Lighter gold
      Color(0xFFEABF56), // Medium gold
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: itemColor.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: itemColor, // SOLID color for the entire card with no gradient
          child: InkWell(
            onTap: () {
              // Navigation based on screen name
              switch (screenName) {
                case 'HospitalScreen':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SplashScreen1()),
                  );
                  break;
                case 'PatientsScreen':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ReceptionDashBoard()),
                  );
                  break;
                case 'DoctorsScreen':
                  // _navigateToDoctorScreen();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AuthSplashScreen()),
                  );
                  break;
                case 'NursesScreen':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => NurseLoginScreen()),
                  );
                  // ScaffoldMessenger.of(context).showSnackBar(
                  //   SnackBar(content: Text('Nurse management coming soon')),
                  // );
                  break;
                case 'PharmacyScreen':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => PharmacyDashBoard()),
                  );
                  break;
                case 'LabScreen':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LabDashBoardScreen()),
                  );
                  break;
                case 'Admin':
                  showDialog(
                    context: context,
                    builder: (context) => AdminAuthDialog(),
                  );
                  break;
                case 'NurseAdmin':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NurseAdminDashBoardScreen()),
                  );
                  break;
                case 'CalendarScreen':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Calendar coming soon')),
                  );
                  break;
                default:
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening $name')),
                  );
              }
            },
            child: Stack(
              children: [
                // Background icon (positioned to avoid overflow)
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    icon,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Icon container
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: itemColor.withOpacity(0.2),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon,
                          color: itemColor,
                          size: 24,
                        ),
                      ),
                      // App name and underline
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            height: 3,
                            width: 30,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Premium badge
                if (isPremium)
                  Positioned(
                    top: 0,
                    left: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: goldGradientColors,
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomRight: Radius.circular(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.workspace_premium,
                            color: Color(0xFF5D4037), // Dark brown
                            size: 14,
                          ),
                          SizedBox(width: 3),
                          Text(
                            'PREMIUM',
                            style: TextStyle(
                              color: Color(0xFF5D4037), // Dark brown
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteWidget(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TODAY'S QUOTE",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF005F9E),
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: const Color(0xFF005F9E),
                ),
                onPressed: () {
                  // Refresh quote
                },
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                const Icon(
                  Icons.format_quote,
                  size: 40,
                  color: Color(0xFF005F9E),
                ),
                const SizedBox(height: 8),
                Text(
                  "\"It's okay to take a break and fueled by happy thoughts.\"",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontStyle: FontStyle.italic,
                    color: textColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "- Wellness Journal",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMusicPlayer(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MUSIC PLAYER',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF005F9E),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: AssetImage('assets/images/album_cover.jpg'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Relaxing Melody',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    'Wellness Music',
                    style: TextStyle(
                      fontSize: 14,
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.favorite_border,
                          color: textColor.withOpacity(0.7),
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_previous,
                          color: textColor,
                          size: 32,
                        ),
                        onPressed: () {},
                      ),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFF005F9E),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () {},
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.skip_next,
                          color: textColor,
                          size: 32,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.playlist_add,
                          color: textColor.withOpacity(0.7),
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosSection(Color cardColor, Color textColor) {
    // Define promotional content items
    final List<Map<String, dynamic>> promoItems = [
      {
        'title': 'AI Diagnostics',
        'subtitle': 'Coming Soon',
        'description': 'Revolutionary AI-powered medical diagnostics',
        'icon': Icons.psychology,
        'gradient': [const Color(0xFF667eea), const Color(0xFF764ba2)],
        'isNew': true,
      },
      {
        'title': 'Mobile App',
        'subtitle': 'On-the-Go',
        'description': 'Access DocNeX from anywhere',
        'icon': Icons.phone_android,
        'gradient': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
        'isNew': true,
      },
      {
        'title': 'Smart Reports',
        'subtitle': 'Analytics+',
        'description': 'Advanced insights & predictive analytics',
        'icon': Icons.trending_up,
        'gradient': [const Color(0xFFfb2b69), const Color(0xFFff5858)],
        'isNew': true,
      },
      {
        'title': 'Cloud Backup',
        'subtitle': 'Secure',
        'description': 'Automatic data backup & recovery',
        'icon': Icons.cloud_done,
        'gradient': [const Color(0xFF4568dc), const Color(0xFFb06ab3)],
        'isNew': false,
      },
      {
        'title': 'Telemedicine',
        'subtitle': 'Go Digital',
        'description': 'Connect with patients remotely',
        'icon': Icons.video_call,
        'gradient': [const Color(0xFF11998e), const Color(0xFF38ef7d)],
        'isNew': false,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Enhanced header section with animation-like effect
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF005F9E),
                  Color(0xFF0288D1),
                  Color(0xFF00B8D4),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF005F9E).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Discover What\'s Inside',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'We Proivde You With The Best',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEABF56),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PREMIUM',
                    style: TextStyle(
                      color: Color(0xFF5D4037),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Promotional cards section
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: promoItems.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildPromoCard(
                    promoItems[index]['title'],
                    promoItems[index]['subtitle'],
                    promoItems[index]['description'],
                    promoItems[index]['icon'],
                    promoItems[index]['gradient'],
                    promoItems[index]['isNew'],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCard(
    String title,
    String subtitle,
    String description,
    IconData icon,
    List<Color> gradientColors,
    bool isNew,
  ) {
    return Container(
      width: 200,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background pattern
            Positioned(
              right: -30,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            Positioned(
              right: -10,
              top: -10,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            // Content with proper overflow protection
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon and badge row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            icon,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        if (isNew)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEABF56),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Text(
                              'NEW',
                              style: TextStyle(
                                color: Color(0xFF5D4037),
                                fontWeight: FontWeight.bold,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Flexible content area to prevent overflow
                    Flexible(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          // Subtitle
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.9),
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Description
                          Flexible(
                            child: Text(
                              description,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(0.8),
                                height: 1.2,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPanelItem(
      String title, IconData icon, String description, Color color) {
    return Container(
      width: 180,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.9),
            color,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Panel action
          },
          child: Stack(
            children: [
              // Background large icon
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  icon,
                  size: 100,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon in circle
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.3),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        icon,
                        color: color,
                        size: 20,
                      ),
                    ),

                    Spacer(),

                    // Title
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    SizedBox(height: 4),

                    // Description instead of count
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoldersSection(Color cardColor, Color textColor) {
    List<Map<String, dynamic>> folders = [
      {'name': 'Work Files', 'color': const Color(0xFF4CAF50)},
      {'name': 'Patient Records', 'color': const Color(0xFF2196F3)},
      {'name': 'Medical Images', 'color': const Color(0xFFF44336)},
      {'name': 'Reports', 'color': const Color(0xFFFF9800)},
      {'name': 'Research', 'color': const Color(0xFF9C27B0)},
      {'name': 'Administrative', 'color': const Color(0xFF795548)},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FOLDERS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF005F9E),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: folders.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildFolder(
                      folders[index]['name'], folders[index]['color']),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolder(String name, Color folderColor) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 70,
          decoration: BoxDecoration(
            color: folderColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
              bottomLeft: Radius.circular(2),
              bottomRight: Radius.circular(2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.folder,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _isDarkMode ? Colors.white : Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _getWeekday(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}
