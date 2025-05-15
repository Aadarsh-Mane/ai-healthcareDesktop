import 'package:doctordesktop/pharmacy/InventoryListScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pharmatheme.dart'; // Import the existing PharmaTheme

class InventoryDashboard extends ConsumerStatefulWidget {
  const InventoryDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<InventoryDashboard> createState() => _InventoryDashboardState();
}

class _InventoryDashboardState extends ConsumerState<InventoryDashboard> {
  int _selectedIndex = 0;
  final FocusNode _keyboardFocusNode = FocusNode();

  final List<Widget> _screens = [
    const InventoryListScreen(),
    // Add other screens like reports or analytics as needed
  ];

  @override
  void initState() {
    super.initState();
    _registerKeyboardShortcuts();
  }

  @override
  void dispose() {
    _keyboardFocusNode.dispose();
    super.dispose();
  }

  void _registerKeyboardShortcuts() {
    // Here we can add app-level keyboard shortcuts
    // These will be available throughout the app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Handle keyboard shortcuts at the app level
    return KeyboardListener(
      focusNode: _keyboardFocusNode,
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.keyI &&
              HardwareKeyboard.instance.isControlPressed) {
            // Ctrl+I - Go to inventory (first screen)
            _onItemTapped(0);
          } else if (event.logicalKey == LogicalKeyboardKey.keyN &&
              HardwareKeyboard.instance.isControlPressed) {
            // Ctrl+N - Add new inventory item
            // Navigator.of(context)
            //     .push(
            //       MaterialPageRoute(
            //         builder: (_) => const AddInventoryScreen(),
            //       ),
            //     )
            //     .then((_) => _onItemTapped(0));
          }
        }
      },
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    final theme = PharmaTheme.lightTheme;

    return Theme(
      data: theme,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Decide layout based on screen width
          final isDesktop =
              constraints.maxWidth >= PharmaTheme.desktopBreakpoint;
          final isTablet =
              constraints.maxWidth >= PharmaTheme.tabletBreakpoint &&
                  constraints.maxWidth < PharmaTheme.desktopBreakpoint;

          if (isDesktop) {
            return _buildDesktopLayout();
          } else if (isTablet) {
            return _buildTabletLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildNavigationRail(extended: false),
          Expanded(
            child: _screens[_selectedIndex],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildNavigationRail({bool extended = true}) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      labelType: extended
          ? NavigationRailLabelType.none
          : NavigationRailLabelType.selected,
      extended: extended,
      minWidth: 56,
      minExtendedWidth: 220,
      backgroundColor: PharmaTheme.primary,
      selectedIconTheme: const IconThemeData(color: PharmaTheme.textLight),
      unselectedIconTheme:
          IconThemeData(color: PharmaTheme.textLight.withOpacity(0.7)),
      selectedLabelTextStyle: const TextStyle(color: PharmaTheme.textLight),
      unselectedLabelTextStyle:
          TextStyle(color: PharmaTheme.textLight.withOpacity(0.7)),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('Inventory'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: Text('Analytics'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
      leading: extended
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    backgroundColor: PharmaTheme.textLight,
                    radius: 28,
                    child: Icon(
                      Icons.local_pharmacy,
                      color: PharmaTheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pharma Admin',
                    style: TextStyle(
                      color: PharmaTheme.textLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: FilledButton.icon(
                      onPressed: () {
                        // Navigator.of(context)
                        //     .push(
                        //       MaterialPageRoute(
                        //         builder: (_) => const AddInventoryScreen(),
                        //       ),
                        //     )
                        //     .then((_) => _onItemTapped(0));
                      },
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Inventory'),
                      style: FilledButton.styleFrom(
                        backgroundColor: PharmaTheme.textLight,
                        foregroundColor: PharmaTheme.primary,
                        minimumSize: const Size.fromHeight(40),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox(
              height: 80,
              child: Icon(Icons.local_pharmacy,
                  color: PharmaTheme.textLight, size: 28)),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      backgroundColor: PharmaTheme.primary,
      selectedItemColor: PharmaTheme.textLight,
      unselectedItemColor: PharmaTheme.textLight.withOpacity(0.7),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2_outlined),
          activeIcon: Icon(Icons.inventory_2),
          label: 'Inventory',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          activeIcon: Icon(Icons.settings),
          label: 'Settings',
        ),
      ],
    );
  }
}

// Main screen
class InventoryApp extends ConsumerWidget {
  const InventoryApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Pharmacy Inventory',
      theme: PharmaTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      home: const InventoryDashboard(),
    );
  }
}

// Optional: For testing and running just the inventory module
void main() {
  runApp(const ProviderScope(child: InventoryApp()));
}
