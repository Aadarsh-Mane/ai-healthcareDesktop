import 'dart:async';
import 'dart:math';

import 'package:doctordesktop/services/motion_game_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:doctordesktop/services/motion_control.dart';

// Game state provider
final gameScoreProvider = StateProvider<int>((ref) => 0);
final gameLifeProvider = StateProvider<int>((ref) => 3);

class BirdGameScreen extends ConsumerStatefulWidget {
  const BirdGameScreen({Key? key}) : super(key: key);

  @override
  _BirdGameScreenState createState() => _BirdGameScreenState();
}

class _BirdGameScreenState extends ConsumerState<BirdGameScreen>
    with TickerProviderStateMixin {
  GameMotionControlServer? _motionServer;
  final List<String> _logMessages = [];
  bool _showLogs = false;

  // Game related variables
  Timer? _gameTimer;
  final List<Bird> _birds = [];
  double _crosshairX = 0.0;
  double _crosshairY = 0.0;
  int _score = 0;
  int _lives = 3;
  bool _gameOver = false;
  final Random _random = Random();
  bool _isGameInitialized = false;

  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initMotionServer();

    // Setup animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_fadeController);
    _fadeController.forward();

    // We'll initialize the game in didChangeDependencies instead of initState
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Start the game after MediaQuery is available
    if (!_isGameInitialized) {
      _startGame();
      _isGameInitialized = true;
    }
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _stopMotionServer();
    _fadeController.dispose();
    super.dispose();
  }

  // Initialize the motion control server
  Future<void> _initMotionServer() async {
    _motionServer = GameMotionControlServer(
      ref,
      onLog: (message) {
        setState(() {
          _logMessages.add(message);
          if (_logMessages.length > 20) {
            _logMessages.removeAt(0);
          }
        });
      },
      onSelectCurrentOption: () {
        _fireBullet();
      },
      onMotionUpdate: (x, y, z) {
        _handleMotionData(x, y, z);
      },
    );

    if (!(_motionServer?.isRunning ?? false)) {
      await _motionServer!.startServer();
    }
  }

  // Stop the motion control server
  Future<void> _stopMotionServer() async {
    if (_motionServer != null) {
      await _motionServer!.stopServer();
    }
  }

  void _startGame() {
    // Get screen dimensions from MediaQuery
    final screenSize = MediaQuery.of(context).size;

    // Reset game state
    setState(() {
      _birds.clear();
      _score = 0;
      _lives = 3;
      _gameOver = false;
      ref.read(gameScoreProvider.notifier).state = 0;
      ref.read(gameLifeProvider.notifier).state = 3;

      // Position crosshair in center of screen
      _crosshairX = screenSize.width / 2;
      _crosshairY = screenSize.height / 3; // Position in upper third of screen
    });

    // Start game timer to spawn birds and control game flow
    _gameTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      _spawnBird();
      _updateBirdPositions();

      // Update game state in providers for mobile to display
      ref.read(gameScoreProvider.notifier).state = _score;
      ref.read(gameLifeProvider.notifier).state = _lives;

      // Check for game over condition
      if (_lives <= 0 && !_gameOver) {
        _endGame();
      }
    });
  }

  void _spawnBird() {
    if (_birds.length >= 10) return; // Limit max birds on screen

    final screenSize = MediaQuery.of(context).size;

    // Random bird spawn position and direction
    final startSide = _random.nextBool();
    final birdSize =
        50.0 + _random.nextDouble() * 30.0; // Bird size between 50-80
    final yPosition =
        100.0 + _random.nextDouble() * 300.0; // Y position between 100-400
    final speed = 2.0 + (_score / 100); // Birds get faster as score increases

    final bird = Bird(
      x: startSide ? -birdSize : screenSize.width + birdSize,
      y: yPosition,
      size: birdSize,
      direction: startSide ? 1 : -1,
      speed: speed,
      color: Color.fromRGBO(_random.nextInt(255), _random.nextInt(255),
          _random.nextInt(255), 1.0),
    );

    setState(() {
      _birds.add(bird);
    });
  }

  void _updateBirdPositions() {
    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      // Update each bird position
      for (int i = _birds.length - 1; i >= 0; i--) {
        final bird = _birds[i];
        bird.x += bird.speed * bird.direction;

        // Remove birds that fly off screen (player missed these birds)
        if ((bird.direction > 0 && bird.x > screenWidth + bird.size) ||
            (bird.direction < 0 && bird.x < -bird.size)) {
          _birds.removeAt(i);

          // Player loses a life when a bird escapes
          _lives--;
          ref.read(gameLifeProvider.notifier).state = _lives;
        }
      }
    });
  }

  void _fireBullet() {
    if (_gameOver) return;

    // Bullet hit detection for birds near the crosshair
    bool hit = false;

    setState(() {
      // Check if any bird was hit
      for (int i = _birds.length - 1; i >= 0; i--) {
        final bird = _birds[i];

        // Calculate distance from crosshair to bird center
        final dx = (_crosshairX - bird.x).abs();
        final dy = (_crosshairY - bird.y).abs();

        // If crosshair is close enough to bird, count as hit
        if (dx < bird.size / 2 && dy < bird.size / 2) {
          _birds.removeAt(i);
          _score += 10;
          ref.read(gameScoreProvider.notifier).state = _score;
          hit = true;
          break; // Only hit one bird per shot
        }
      }
    });

    // Visual feedback for shooting
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        content: Text(hit ? 'Hit! +10 points' : 'Missed!'),
        duration: Duration(milliseconds: 500),
        backgroundColor: hit ? Colors.green : Colors.red,
      ));
  }

  void _updateCrosshairPosition(double x, double y) {
    setState(() {
      _crosshairX = x;
      _crosshairY = y;
    });
  }

  void _handleMotionData(double x, double y, double z) {
    // Map phone tilt to crosshair movement
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adjust crosshair position based on phone tilt
    // z tilt controls Y position (tilting forward/backward)
    // x tilt controls X position (tilting left/right)

    // Note: The multiplier controls sensitivity - adjust as needed
    double newX = _crosshairX - (x * 10); // More negative for left movement
    double newY = _crosshairY + (z * 5); // More negative for upward movement

    // Keep crosshair within screen bounds
    newX = newX.clamp(0.0, screenWidth);
    newY = newY.clamp(0.0, screenHeight);

    _updateCrosshairPosition(newX, newY);
  }

  void _endGame() {
    setState(() {
      _gameOver = true;
    });

    _gameTimer?.cancel();

    // Show game over dialog after a brief delay
    Future.delayed(Duration(seconds: 1), () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Game Over!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your score: $_score'),
              SizedBox(height: 20),
              Text('Would you like to play again?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context); // Return to previous screen
              },
              child: Text('Exit'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startGame();
              },
              child: Text('Play Again'),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = ref.watch(connectionStatusProvider);
    final connectedDevice = ref.watch(connectedDeviceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Bird Shooter Game'),
        backgroundColor: Colors.green[700],
        actions: [
          if (isConnected && connectedDevice != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Icon(Icons.phone_android, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    "Mobile Connected",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          IconButton(
            icon: Icon(_showLogs ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showLogs = !_showLogs;
              });
            },
            tooltip: _showLogs ? "Hide Logs" : "Show Logs",
          ),
        ],
      ),
      body: GestureDetector(
        onPanUpdate: (details) {
          // Allow manual aiming with touch/mouse
          _updateCrosshairPosition(
            details.globalPosition.dx,
            details.globalPosition.dy -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
          );
        },
        onTap: () {
          // Allow manual firing with tap
          _fireBullet();
        },
        child: Stack(
          children: [
            // Game background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.lightBlue[300]!, Colors.blue[600]!],
                ),
              ),
            ),

            // Ground
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.green[400]!, Colors.green[800]!],
                  ),
                ),
              ),
            ),

            // Birds
            ..._birds.map((bird) => Positioned(
                  left: bird.x - bird.size / 2,
                  top: bird.y - bird.size / 2,
                  width: bird.size,
                  height: bird.size,
                  child: Transform.scale(
                    scaleX: bird.direction.toDouble(),
                    child: Icon(
                      Icons.flutter_dash,
                      color: bird.color,
                      size: bird.size,
                    ),
                  ),
                )),

            // Crosshair
            Positioned(
              left: _crosshairX - 25,
              top: _crosshairY - 25,
              width: 50,
              height: 50,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red, width: 2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: Colors.red,
                    size: 30,
                  ),
                ),
              ),
            ),

            // Score and lives display
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Score: $_score',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    children: List.generate(
                        _lives,
                        (index) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: Icon(Icons.favorite,
                                  color: Colors.red, size: 30),
                            )),
                  ),
                ],
              ),
            ),

            // Game controls hint
            if (isConnected && connectedDevice != null)
              Positioned(
                bottom: 120,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.symmetric(horizontal: 40),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.phone_android, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "Tilt phone to aim, tap to shoot!",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Connection logs overlay
            if (_showLogs)
              Positioned(
                right: 20,
                bottom: 20,
                width: 300,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Connection Logs",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                _showLogs = false;
                              });
                            },
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                        ],
                      ),
                      Divider(color: Colors.white30),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _logMessages.length,
                          reverse: true,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                _logMessages[_logMessages.length - 1 - index],
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Game over overlay
            if (_gameOver)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  color: Colors.black54,
                  child: Center(
                    child: Text(
                      'GAME OVER',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fireBullet,
        child: Icon(Icons.movie_filter),
        backgroundColor: Colors.red,
      ),
    );
  }
}

class Bird {
  double x;
  double y;
  final double size;
  final int direction; // 1 for right, -1 for left
  final double speed;
  final Color color;

  Bird({
    required this.x,
    required this.y,
    required this.size,
    required this.direction,
    required this.speed,
    required this.color,
  });
}
