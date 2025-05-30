// home_screen.dart
import 'package:doctordesktop/Nurse/NurseLoginScreen.dart';
import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Home Screen State Provider
final homeScreenStateProvider =
    StateNotifierProvider<NurseHomeScreenNotifier, NurseHomeScreenState>((ref) {
  return NurseHomeScreenNotifier(ref);
});

class NurseHomeScreenState {
  final String userName;
  final String userEmail;
  final bool isLoading;

  const NurseHomeScreenState({
    this.userName = '',
    this.userEmail = '',
    this.isLoading = false,
  });

  NurseHomeScreenState copyWith({
    String? userName,
    String? userEmail,
    bool? isLoading,
  }) {
    return NurseHomeScreenState(
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NurseHomeScreenNotifier extends StateNotifier<NurseHomeScreenState> {
  final Ref _ref;

  NurseHomeScreenNotifier(this._ref) : super(const NurseHomeScreenState()) {
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    state = state.copyWith(isLoading: true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('user_name') ?? 'User';
      final userEmail = prefs.getString('user_email') ?? '';

      state = state.copyWith(
        userName: userName,
        userEmail: userEmail,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    await _ref.read(authStateProvider.notifier).logout();
    state = state.copyWith(isLoading: false);
  }
}

// Home Screen Widget
class NurseHomeScreen extends ConsumerStatefulWidget {
  const NurseHomeScreen({super.key});

  @override
  ConsumerState<NurseHomeScreen> createState() => _NurseHomeScreenState();
}

class _NurseHomeScreenState extends ConsumerState<NurseHomeScreen> {
  void _handleKeyboardShortcuts(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Ctrl/Cmd + Q to logout
      if ((HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed) &&
          event.logicalKey == LogicalKeyboardKey.keyQ) {
        _showLogoutDialog();
      }
      // F11 for full screen (handled by system but can be customized)
      if (event.logicalKey == LogicalKeyboardKey.f11) {
        // Can add custom full screen handling if needed
      }
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _handleLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HospitalTheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await ref.read(homeScreenStateProvider.notifier).logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const NurseLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width > 768;
    final homeState = ref.watch(homeScreenStateProvider);

    // Listen to auth state changes
    ref.listen(authStateProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user == null) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const NurseHomeScreen()),
              (route) => false,
            );
          }
        },
        loading: () {},
        error: (error, _) {},
      );
    });

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: _handleKeyboardShortcuts,
      child: Scaffold(
        backgroundColor: HospitalTheme.background,
        appBar: HospitalTheme.buildAppBar(
          context: context,
          title: 'Hospital Management System',
          showBackButton: false,
          actions: [
            // User Profile Section
            if (!homeState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Welcome, ${homeState.userName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (homeState.userEmail.isNotEmpty)
                          Text(
                            homeState.userEmail,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    PopupMenuButton<String>(
                      icon: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      onSelected: (value) {
                        switch (value) {
                          case 'profile':
                            // TODO: Navigate to profile
                            break;
                          case 'settings':
                            // TODO: Navigate to settings
                            break;
                          case 'logout':
                            _showLogoutDialog();
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem<String>(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outlined),
                              SizedBox(width: 12),
                              Text('Profile'),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings_outlined),
                              SizedBox(width: 12),
                              Text('Settings'),
                            ],
                          ),
                        ),
                        const PopupMenuDivider(),
                        const PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 12),
                              Text('Sign Out',
                                  style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
        body: homeState.isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _buildHomeContent(context, screenSize, isDesktop),
      ),
    );
  }

  Widget _buildHomeContent(
      BuildContext context, Size screenSize, bool isDesktop) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(context, isDesktop),

            SizedBox(height: isDesktop ? 32.0 : 24.0),

            // Main Content Area - Currently Empty as requested
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: isDesktop ? 150.0 : 120.0,
                      height: isDesktop ? 150.0 : 120.0,
                      decoration: BoxDecoration(
                        color: HospitalTheme.surfaceLight,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: HospitalTheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.dashboard_outlined,
                        size: isDesktop ? 60.0 : 50.0,
                        color: HospitalTheme.primary,
                      ),
                    ),
                    SizedBox(height: isDesktop ? 24.0 : 16.0),
                    Text(
                      'Dashboard Coming Soon',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: HospitalTheme.textMedium,
                                fontWeight: FontWeight.w600,
                              ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'Your hospital management features will be available here',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: HospitalTheme.textLight,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Keyboard Shortcuts Help
            _buildKeyboardShortcuts(context, isDesktop),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context, bool isDesktop) {
    final homeState = ref.watch(homeScreenStateProvider);

    return HospitalTheme.buildCard(
      padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
      child: Row(
        children: [
          Container(
            width: isDesktop ? 60.0 : 50.0,
            height: isDesktop ? 60.0 : 50.0,
            decoration: BoxDecoration(
              color: HospitalTheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.waving_hand,
              color: HospitalTheme.primary,
              size: isDesktop ? 30.0 : 25.0,
            ),
          ),
          SizedBox(width: isDesktop ? 16.0 : 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${homeState.userName}!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: HospitalTheme.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  'Ready to manage your hospital tasks efficiently',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: HospitalTheme.textMedium,
                      ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: HospitalTheme.success.withOpacity(0.1),
              borderRadius: HospitalTheme.radiusSmall,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8.0,
                  height: 8.0,
                  decoration: const BoxDecoration(
                    color: HospitalTheme.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6.0),
                Text(
                  'Online',
                  style: TextStyle(
                    color: HospitalTheme.success,
                    fontWeight: FontWeight.w600,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyboardShortcuts(BuildContext context, bool isDesktop) {
    if (!isDesktop) return const SizedBox.shrink();

    return HospitalTheme.buildCard(
      padding: const EdgeInsets.all(16.0),
      backgroundColor: HospitalTheme.surfaceLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keyboard Shortcuts',
            style: TextStyle(
              color: HospitalTheme.textDark,
              fontWeight: FontWeight.w600,
              fontSize: 14.0,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            '• Ctrl+Q: Sign out\n• F11: Toggle fullscreen',
            style: TextStyle(
              color: HospitalTheme.textMedium,
              fontSize: 12.0,
            ),
          ),
        ],
      ),
    );
  }
}
