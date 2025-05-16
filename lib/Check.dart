import 'package:doctordesktop/Admin/AdminAuthDialod.dart';
import 'package:doctordesktop/Admin/ReceptionAuthDialog.dart';
import 'package:doctordesktop/Doctor/DoctorMainScreen.dart';
import 'package:doctordesktop/Doctor/fetchDoctor.dart';
import 'package:doctordesktop/External/CommonScreen.dart';
import 'package:doctordesktop/Lab/LabDashBoard.dart';
import 'package:doctordesktop/Lab/LabScreen.dart';
import 'package:doctordesktop/Patient/fetchPatient.dart';
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

  late VideoPlayerController _videoPlayerController;
  bool _videoInitialized = false;
  final List<Map<String, dynamic>> _todoItems = [
    {'text': 'Track appointments with Docnex Scheduler', 'done': false},
    {'text': 'Access digital prescriptions in one tap', 'done': false},
    {'text': 'Monitor patient vitals with live updates', 'done': false},
    {'text': 'Securely share reports with patients', 'done': false},
    {'text': 'Experience faster billing with Docnex', 'done': false},
  ];

  // Navigation items for the sidebar
  final List<Map<String, dynamic>> _navItems = [
    {'icon': Icons.home, 'title': 'Home', 'screen': 'HomeScreen'},
    {
      'icon': Icons.dashboard,
      'title': 'External Dashboard',
      'screen': 'DashboardScreen'
    },
    {'icon': Icons.people, 'title': 'Patients', 'screen': 'PatientListScreen'},
    {
      'icon': Icons.medical_services,
      'title': 'Doctor Panel',
      'screen': 'DoctorListScreen'
    },
    {'icon': Icons.receipt_long, 'title': 'Reports', 'screen': 'ReportsScreen'},
    {
      'icon': Icons.biotech,
      'title': 'Lab Login',
      'screen': 'LabPatientsScreen'
    },
    {
      'icon': Icons.admin_panel_settings,
      'title': 'Admin',
      'screen': 'AdminScreen'
    },
    {'icon': Icons.settings, 'title': 'Settings', 'screen': 'SettingsScreen'},
  ];

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
    });
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() async {
    // Change this path to your video file
    _videoPlayerController = VideoPlayerController.asset(
      'assets/videos/.mp4',
    );

    await _videoPlayerController.initialize();
    _videoPlayerController.setLooping(true);
    _videoPlayerController.setVolume(0.0); // Mute the video
    _videoPlayerController.play();

    setState(() {
      _videoInitialized = true;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _videoPlayerController.dispose();
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

  void _selectNavItem(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Get the selected screen name
    final screenName = _navItems[index]['screen'];

    // Handle navigation based on screen name
    switch (screenName) {
      case 'HomeScreen':
        // Already on home screen, do nothing or refresh
        break;
      case 'DashboardScreen':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SplashScreen1()),
        );
        break;
      case 'PatientListScreen':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PatientListScreen()),
        );
        break;
      case 'DoctorListScreen':
        _navigateToDoctorScreen();
        break;
      case 'ReportsScreen':
        // Navigate to reports screen when implemented
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reports module coming soon')),
        );
        break;
      case 'LabPatientsScreen':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => LabDashBoardScreen()),
        );
        break;
      case 'AdminScreen':
        showDialog(
          context: context,
          builder: (context) => AdminAuthDialog(),
        );
        break;
      case 'SettingsScreen':
        // Navigate to settings screen when implemented
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settings module coming soon')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Navigating to ${_navItems[index]['title']}')),
        );
    }
  }

  void _navigateToDoctorScreen() {
    // Check if already logged in first
    final isLoggedIn = ref.read(authControllerProvider);
    if (isLoggedIn) {
      // If already logged in, check user type
      ref.read(authControllerProvider.notifier).getUsertype().then((userType) {
        if (userType == 'doctor') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => DoctorMainScreen()),
          );
        } else {
          // Not a doctor, go to login
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen1()),
          );
        }
      });
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
    final bool isSmallScreen = screenWidth < 1200;

    if (isSmallScreen) {
      // Stack content for small screens
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clock widget
            _buildClockWidget(cardColor, primaryColor, textColor, shadowColor),
            const SizedBox(height: 16),
            // To-do list
            _buildToDoList(cardColor, primaryColor, textColor),
            const SizedBox(height: 16),
            // Applications
            _buildApplications(
                cardColor, primaryColor, textColor, shadowColor, isSmallScreen),
            const SizedBox(height: 16),
            // Quote widget
            _buildQuoteWidget(cardColor, textColor),
            const SizedBox(height: 16),
            // Music player
            _buildMusicPlayer(cardColor, textColor),
            const SizedBox(height: 16),
            // Photos
            _buildPhotosSection(cardColor, textColor),
            const SizedBox(height: 16),
            // Folders
            // _buildFoldersSection(cardColor, textColor),
          ],
        ),
      );
    } else {
      // Two-column layout for larger screens
      return Column(
        children: [
          // First row: Clock, To-Do List, Applications
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Clock widget (left)
                Expanded(
                  flex: 5,
                  child: _buildLogoWidget(
                      cardColor, primaryColor, textColor, shadowColor),
                ),
                const SizedBox(
                  height: 16,
                  width: 16,
                ),

                Expanded(
                  flex: 3,
                  child: _buildClockWidget(
                      cardColor, primaryColor, textColor, shadowColor),
                ),
                const SizedBox(width: 16),
                // To-Do List (middle)
                // Expanded(
                //   flex: 3,
                //   child: _buildToDoList(cardColor, primaryColor, textColor),
                // ),
                // const SizedBox(width: 16),
                // Applications (right)
                Expanded(
                  flex: 5,
                  child: _buildApplications(cardColor, primaryColor, textColor,
                      shadowColor, isSmallScreen),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Second row: Quote, Music, Photos and Folders
          Expanded(
            flex: 4,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quote widget (left)
                Expanded(
                  flex: 3,
                  child: _buildQuoteWidget(cardColor, textColor),
                ),
                const SizedBox(width: 16),
                // Music player (middle)

                const SizedBox(width: 16),
                // Photos and folders (right)
                Expanded(
                  flex: 7,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Photos - No fixed height constraint
                      Flexible(
                        flex: 1,
                        child: _buildPhotosSection(cardColor, textColor),
                      ),
                      const SizedBox(height: 16),
                      // Folders - If you had this section
                      // Flexible(
                      //   child: _buildFoldersSection(cardColor, textColor),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
        'name': 'Reports',
        'icon': Icons.description,
        'screen': 'ReportsScreen',
        'color': const Color(0xFF3F51B5),
        'isPremium': true, // Premium feature
      },
      {
        'name': 'Settings',
        'icon': Icons.settings,
        'screen': 'SettingsScreen',
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
                  _navigateToDoctorScreen();
                  break;
                case 'NursesScreen':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nurse management coming soon')),
                  );
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
                case 'ReportsScreen':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Reports module coming soon')),
                  );
                  break;
                case 'SettingsScreen':
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Settings coming soon')),
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
    // Define panel items with image, title, and description
    final List<Map<String, dynamic>> panels = [
      {
        'title': 'Doctors',
        'icon': Icons.medical_services,
        'description': 'Manage specialist profiles',
        'color': const Color(0xFF2196F3)
      },
      {
        'title': 'Nurses',
        'icon': Icons.health_and_safety,
        'description': 'Staff scheduling & care',
        'color': const Color(0xFF4CAF50)
      },
      {
        'title': 'Patients',
        'icon': Icons.people_alt,
        'description': 'Records & appointments',
        'color': const Color(0xFFF44336)
      },
      {
        'title': 'Lab Tests',
        'icon': Icons.biotech,
        'description': 'Results & diagnostics',
        'color': const Color(0xFFFF9800)
      },
      {
        'title': 'Appointments',
        'icon': Icons.calendar_today,
        'description': 'Schedule management',
        'color': const Color(0xFF9C27B0)
      },
      {
        'title': 'Reports',
        'icon': Icons.analytics,
        'description': 'Analytics & insights',
        'color': const Color(0xFF795548)
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
          // Modern header section
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF005F9E),
                  const Color(0xFF0288D1),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.dashboard,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'DocNex Panels ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),

          // Action buttons row
          Row(
            children: [
              Spacer(),
            ],
          ),

          SizedBox(height: 16),

          // Panels section with fixed height
          SizedBox(
            height: 140, // Further reduced height
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: panels.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildPanelItem(
                    panels[index]['title'],
                    panels[index]['icon'],
                    panels[index]['description'],
                    panels[index]['color'],
                  ),
                );
              },
            ),
          ),
        ],
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
