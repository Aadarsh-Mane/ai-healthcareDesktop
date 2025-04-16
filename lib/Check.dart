import 'package:doctordesktop/constants/Methods.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:window_size/window_size.dart' as window_size;
import 'dart:io';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    window_size.setWindowTitle('Custom Desktop Homepage');
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
      title: 'Desktop Homepage',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        fontFamily: 'Roboto',
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Timer _timer;
  late DateTime _currentTime;

  late VideoPlayerController _videoPlayerController;
  bool _videoInitialized = false;
  final List<Map<String, dynamic>> _todoItems = [
    {'text': 'Complete project proposal', 'done': true},
    {'text': 'Schedule team meeting', 'done': false},
    {'text': 'Prepare presentation slides', 'done': false},
  ];

  @override
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
  @override
  void dispose() {
    _timer.cancel();
    _videoPlayerController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Video Background with brightness adjustment
          _videoInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoPlayerController.value.size.width,
                      height: _videoPlayerController.value.size.height,
                      child: ColorFiltered(
                        // Increase brightness with color matrix
                        colorFilter: ColorFilter.matrix([
                          1.3, 0, 0, 0, 0.1, // Increase red and add offset
                          0, 1.3, 0, 0, 0.1, // Increase green and add offset
                          0, 0, 1.3, 0, 0.1, // Increase blue and add offset
                          0, 0, 0, 1, 0, // Keep alpha unchanged
                        ]),
                        child: VideoPlayer(_videoPlayerController),
                      ),
                    ),
                  ),
                )
              : Container(
                  color: Colors.black,
                  child: const Center(
                      // child: CircularProgressIndicator(),
                      ),
                ),

          // Subtle overlay to improve content visibility without making the video too dark
          Container(
            color: Colors.black.withOpacity(0.25),
          ),

          // Gradient overlay focused at the edges, keeping center clearer
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.black.withOpacity(0.0), // Transparent at center
                  Colors.black.withOpacity(0.5), // Darker at edges
                ],
              ),
            ),
          ),

          // Main content
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              children: [
                _buildTopBar(),
                const SizedBox(height: 24),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return _buildResponsiveContent(constraints);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    // URL for the address bar - set your default URL here
    final urlText = 'www.docnex.care';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          _buildCircularButton(Icons.arrow_back),
          const SizedBox(width: 8),
          _buildCircularButton(Icons.arrow_forward),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () {
                // When the address bar is tapped, open the URL
                final url = 'https://$urlText';
                Methods().openUrl(url);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    const Text(
                      'aA',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.lock, color: Colors.black, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      urlText,
                      style: TextStyle(color: Colors.black),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh,
                          color: Colors.black, size: 20),
                      onPressed: () {
                        // Refresh action - you could re-open the URL
                        final url = 'https://$urlText';
                        Methods().openUrl(url);
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.search,
                          color: Colors.black, size: 20),
                      onPressed: () {
                        // Open a search engine
                        Methods().openUrl('https://www.google.com');
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          _buildCircularButton(
            Icons.ios_share,
            onPressed: () {
              // Share the current URL
              final url = 'https://$urlText';
              // You could implement share functionality here or just open the URL
              Methods().openUrl(url);
            },
          ),
          const SizedBox(width: 8),
          _buildCircularButton(
            Icons.add,
            onPressed: () {
              // Add new tab or bookmark functionality
            },
          ),
          const SizedBox(width: 8),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade400,
              image: const DecorationImage(
                image: AssetImage('assets/images/profile.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton(IconData icon, {VoidCallback? onPressed}) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade400,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.black),
        onPressed: onPressed ?? () {},
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildResponsiveContent(BoxConstraints constraints) {
    return Column(
      children: [
        // First row: Clock, To-Do List, Applications
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Clock widget (left)
              // Container(
              //   width: constraints.maxWidth * 0.25,
              //   child: _buildClockWidget(),
              // ),
              Expanded(
                flex: 2,
                child: _buildClockWidget(),
              ),
              const SizedBox(width: 24),
              // // To-Do List (middle)
              Expanded(
                flex: 4,
                child: _buildToDoList(),
              ),
              const SizedBox(width: 24),
              // // // Applications (right)
              Expanded(
                flex: 4,
                child: _buildApplications(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Second row: Quote, Music, Photos and Folders
        Expanded(
          flex: 5,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Quote widget (left)
              Expanded(
                flex: 3,
                child: _buildQuoteWidget(),
              ),
              const SizedBox(width: 24),
              // Music player (middle)
              Expanded(
                flex: 3,
                child: _buildMusicPlayer(),
              ),
              const SizedBox(width: 24),
              // Folders (right)
              Expanded(
                flex: 4,
                child: Column(
                  children: [
                    // Photos
                    Expanded(
                      flex: 1,
                      child: _buildPhotos(),
                    ),
                    const SizedBox(height: 24),
                    // Folders
                    Expanded(
                      flex: 1,
                      child: _buildFolders(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClockWidget() {
    String formattedTime =
        '${_currentTime.hour.toString().padLeft(2, '0')}:${_currentTime.minute.toString().padLeft(2, '0')}';
    String weekday = _getWeekday(_currentTime.weekday);
    String formattedDate =
        '$weekday, ${_currentTime.day} ${_getMonth(_currentTime.month)} ${_currentTime.year}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'DocneX.care',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005F9E),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF005F9E),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF005F9E).withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Clock face
                  Container(
                    decoration: BoxDecoration(
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
                            color: Color(0xFF005F9E),
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
                        color: Color(0xFF005F9E),
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
                      decoration: BoxDecoration(
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
                      decoration: BoxDecoration(
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
                      color: Color(0xFF005F9E),
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
              color: Color(0xFF005F9E),
              height: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formattedDate,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.2,
            ),
          ),
        ],
      ),
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

  Widget _buildToDoList() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TO-DO LIST',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: _todoItems.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildToDoItem(
                  _todoItems[index]['done'],
                  _todoItems[index]['text'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotos() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPhotoItem('assets/images/vitals.png'),
          _buildPhotoItem('assets/images/photo2.jpg'),
          _buildPhotoItem('assets/images/photo3.jpg'),
          _buildPhotoItem('assets/images/photo4.jpg'),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(String imagePath) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildToDoItem(bool isChecked, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isChecked ? Colors.black : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black, width: 2),
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
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplications() {
    // List of application data with icon paths
    final List<Map<String, dynamic>> apps = [
      {
        'name': 'Hospital',
        'icon': 'assets/images/www.webp',
      },
      {
        'name': 'Patients',
        'icon': 'assets/images/pric.png',
      },
      {
        'name': 'Doctors',
        'icon': 'assets/images/p2.png',
      },
      {
        'name': 'Nurses',
        'icon': 'assets/images/nurse_icon.png',
      },
      {
        'name': 'Pharmacy',
        'icon': 'assets/images/pharmacy_icon.png',
      },
      {
        'name': 'Laboratory',
        'icon': 'assets/images/lab_icon.png',
      },
      {
        'name': 'Reports',
        'icon': 'assets/images/report_icon.png',
      },
      {
        'name': 'Settings',
        'icon': 'assets/images/settings_icon.png',
      },
      {
        'name': 'Calendar',
        'icon': 'assets/images/calendar_icon.png',
      },
      {
        'name': 'Emergency',
        'icon': 'assets/images/emergency_icon.png',
      },
      {
        'name': 'Staff',
        'icon': 'assets/images/staff_icon.png',
      },
      {
        'name': 'Billing',
        'icon': 'assets/images/billing_icon.png',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.white,

            // Colors.grey.shade800.withOpacity(0.8),
            // Colors.grey.shade900.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'APPLICATIONS',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF005F9E),
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    Icon(Icons.apps, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85, // Adjust for the text below
              ),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                return _buildAppItem(
                  apps[index]['name'],
                  apps[index]['icon'],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppItem(String name, String iconPath) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF005F9E),
                  Color(0xFF338886),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFF2ecac8).withOpacity(0.3),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {},
                splashColor: Colors.white.withOpacity(0.2),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.asset(
                      iconPath,
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF005F9E),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteWidget() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "TODAY'S QUOTE",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          const Center(
            child: Text(
              "\"It's okay to take a break and fueled by happy thoughts.\"",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontStyle: FontStyle.italic,
                color: Colors.black,
                height: 1.4,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildMusicPlayer() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MUSIC PLAYLIST',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.favorite_border, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.skip_previous, color: Colors.black),
                onPressed: () {},
              ),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 30),
                  onPressed: () {},
                ),
              ),
              IconButton(
                icon: const Icon(Icons.skip_next, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.playlist_add, color: Colors.black),
                onPressed: () {},
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildFolders() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'FOLDERS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFolder('Work Files'),
                _buildFolder('Movies'),
                _buildFolder('Albums'),
                _buildFolder('Projects'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFolder(String name) {
    return Column(
      children: [
        Container(
          width: 70,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.folder, color: Colors.white, size: 40),
        ),
        const SizedBox(height: 5),
        Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
