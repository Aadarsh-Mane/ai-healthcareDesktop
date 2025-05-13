import 'package:flutter/material.dart';
import 'dart:ui';

class EnhancedSearchBar extends StatefulWidget {
  final bool isDarkMode;
  final Color primaryColor;
  final Function(String) onSearch;
  final List<String> quickAccessSites;
  final double maxWidth;

  const EnhancedSearchBar({
    Key? key,
    required this.isDarkMode,
    required this.primaryColor,
    required this.onSearch,
    this.quickAccessSites = const ['Google', 'DocNeX.care', 'Portal'],
    this.maxWidth = 800,
  }) : super(key: key);

  @override
  _EnhancedSearchBarState createState() => _EnhancedSearchBarState();
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar>
    with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();
  bool _isFocused = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  List<String> _recentSearches = [
    'Patient records',
    'Medical procedures',
    'Appointment schedule',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
      if (_isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Get icon for different websites
  Widget _getWebsiteIcon(String site) {
    final Map<String, IconData> icons = {
      'Google': Icons.search,
      'DocNeX.care': Icons.medical_services,
      'Portal': Icons.dashboard,
      'Lab': Icons.science,
      'Pharmacy': Icons.medication,
    };

    final Map<String, Color> colors = {
      'Google': Colors.blue,
      'DocNeX.care': widget.primaryColor,
      'Portal': Colors.green,
      'Lab': Colors.purple,
      'Pharmacy': Colors.orange,
    };

    return Icon(
      icons[site] ?? Icons.public,
      size: 16,
      color: colors[site] ?? widget.primaryColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen size to ensure responsiveness
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;
    final double searchBarWidth =
        screenWidth < widget.maxWidth ? screenWidth * 0.95 : widget.maxWidth;

    // Colors based on theme
    final Color backgroundColor =
        widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final Color hintColor =
        widget.isDarkMode ? Colors.white38 : Colors.grey[400]!;
    final Color textColor = widget.isDarkMode ? Colors.white : Colors.black87;
    final Color borderColor =
        widget.isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[200]!;
    final Color shadowColor = widget.isDarkMode
        ? Colors.black.withOpacity(0.3)
        : Colors.black.withOpacity(0.1);
    final Color iconColor =
        widget.isDarkMode ? Colors.white70 : Colors.grey[600]!;
    final Color buttonHoverColor =
        widget.isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey[100]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.scale(
                scale: _isFocused ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: searchBarWidth,
                  constraints: BoxConstraints(
                    maxWidth: widget.maxWidth,
                  ),
                  height: 54,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    children: [
                      // Blurred background effect
                      ClipRRect(
                        borderRadius: BorderRadius.circular(27),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            decoration: BoxDecoration(
                              color: backgroundColor.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(27),
                              border: Border.all(
                                color: _isFocused
                                    ? widget.primaryColor.withOpacity(0.5)
                                    : borderColor,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: shadowColor,
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                                if (_isFocused)
                                  BoxShadow(
                                    color: widget.primaryColor.withOpacity(0.2),
                                    blurRadius: 20,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 2),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Search bar content
                      Row(
                        children: [
                          // Animated search icon
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.only(
                                left: _isFocused ? 20.0 : 16.0, right: 8.0),
                            child: Icon(
                              Icons.search,
                              color:
                                  _isFocused ? widget.primaryColor : iconColor,
                              size: 22,
                            ),
                          ),

                          // Text field takes most of the available space
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              focusNode: _focusNode,
                              decoration: InputDecoration(
                                hintText: 'Search DocNeX or enter website...',
                                hintStyle: TextStyle(
                                  color: hintColor,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w400,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                              ),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w400,
                              ),
                              textInputAction: TextInputAction.search,
                              onSubmitted: (value) {
                                if (value.isNotEmpty) {
                                  widget.onSearch(value);

                                  // Add to recent searches if not already there
                                  if (!_recentSearches.contains(value)) {
                                    setState(() {
                                      _recentSearches.insert(0, value);
                                      if (_recentSearches.length > 5) {
                                        _recentSearches.removeLast();
                                      }
                                    });
                                  }
                                }
                              },
                            ),
                          ),

                          // Clear button (visible when text is entered)
                          if (_controller.text.isNotEmpty)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: iconColor,
                                size: 18,
                              ),
                              onPressed: () {
                                _controller.clear();
                                setState(() {});
                              },
                            ),

                          // Voice search button
                          if (!isSmallScreen)
                            Padding(
                              padding: const EdgeInsets.only(right: 4.0),
                              child: IconButton(
                                icon: Icon(
                                  Icons.mic,
                                  color: widget.primaryColor,
                                  size: 20,
                                ),
                                onPressed: () {
                                  // Voice search functionality
                                },
                                tooltip: 'Voice Search',
                              ),
                            ),

                          // Quick access buttons - responsive
                          if (!isSmallScreen || _controller.text.isEmpty)
                            Container(
                              height: 36,
                              margin: const EdgeInsets.only(right: 10),
                              child: ListView.builder(
                                shrinkWrap: true,
                                scrollDirection: Axis.horizontal,
                                itemCount: isSmallScreen
                                    ? 1 // Show only first item on small screens
                                    : widget.quickAccessSites.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          widget.onSearch(
                                              widget.quickAccessSites[index]);
                                        },
                                        borderRadius: BorderRadius.circular(18),
                                        hoverColor: buttonHoverColor,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: widget.isDarkMode
                                                ? Colors.grey[850]
                                                : Colors.grey[50],
                                            borderRadius:
                                                BorderRadius.circular(18),
                                            border: Border.all(
                                              color: widget.isDarkMode
                                                  ? Colors.grey[800]!
                                                  : Colors.grey[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              _getWebsiteIcon(widget
                                                  .quickAccessSites[index]),
                                              const SizedBox(width: 6),
                                              Text(
                                                widget.quickAccessSites[index],
                                                style: TextStyle(
                                                  color: widget.isDarkMode
                                                      ? Colors.white
                                                      : Colors.grey[800],
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),

                      // Dropdown for search suggestions and history
                      if (_isFocused)
                        Positioned(
                          top: 54,
                          left: 0,
                          right: 0,
                          child: Container(
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: borderColor,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: shadowColor,
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_recentSearches.isNotEmpty) ...[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 16, top: 12, bottom: 4),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Recent Searches',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: widget.isDarkMode
                                                ? Colors.white60
                                                : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                    ...List.generate(
                                      _recentSearches.length,
                                      (index) => Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            _controller.text =
                                                _recentSearches[index];
                                            widget.onSearch(
                                                _recentSearches[index]);
                                            _focusNode.unfocus();
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 10),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.history,
                                                  size: 16,
                                                  color: iconColor,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    _recentSearches[index],
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      color: textColor,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: Icon(
                                                    Icons.north_west,
                                                    size: 14,
                                                    color: iconColor,
                                                  ),
                                                  onPressed: () {
                                                    _controller.text =
                                                        _recentSearches[index];
                                                    setState(() {});
                                                  },
                                                  tooltip: 'Use this search',
                                                  padding: EdgeInsets.zero,
                                                  constraints:
                                                      const BoxConstraints(),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const Divider(),
                                  ],

                                  // Quick links section
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: List.generate(
                                        isSmallScreen
                                            ? 3 // Fewer icons on small screens
                                            : 5,
                                        (index) {
                                          final List<Map<String, dynamic>>
                                              quickLinks = [
                                            {
                                              'icon': Icons.medical_services,
                                              'label': 'Patient Records',
                                              'color': Colors.blue,
                                            },
                                            {
                                              'icon': Icons.calendar_today,
                                              'label': 'Appointments',
                                              'color': Colors.green,
                                            },
                                            {
                                              'icon': Icons.science,
                                              'label': 'Lab Results',
                                              'color': Colors.purple,
                                            },
                                            {
                                              'icon': Icons.medication,
                                              'label': 'Prescriptions',
                                              'color': Colors.orange,
                                            },
                                            {
                                              'icon': Icons.help_outline,
                                              'label': 'Help',
                                              'color': Colors.red,
                                            },
                                          ];

                                          return Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () {
                                                widget.onSearch(
                                                    quickLinks[index]['label']);
                                                _focusNode.unfocus();
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              10),
                                                      decoration: BoxDecoration(
                                                        color: quickLinks[index]
                                                                ['color']
                                                            .withOpacity(0.1),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        quickLinks[index]
                                                            ['icon'],
                                                        color: quickLinks[index]
                                                            ['color'],
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      quickLinks[index]
                                                          ['label'],
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: textColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// Example usage class
class SearchBarImplementation extends StatefulWidget {
  const SearchBarImplementation({Key? key}) : super(key: key);

  @override
  _SearchBarImplementationState createState() =>
      _SearchBarImplementationState();
}

class _SearchBarImplementationState extends State<SearchBarImplementation> {
  bool _isDarkMode = false;
  final Color primaryColor = const Color(0xFF0069B4); // DocNeX blue

  void _handleSearch(String query) {
    // Handle search logic
    if (query.startsWith('www.') || query.startsWith('http')) {
      String url = query;
      if (query.startsWith('www.')) {
        url = 'https://$query';
      }
      // Open URL method
      print('Opening URL: $url');
    } else {
      // Handle as search query
      print('Searching for: $query');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: EnhancedSearchBar(
          isDarkMode: _isDarkMode,
          primaryColor: primaryColor,
          onSearch: _handleSearch,
          quickAccessSites: [
            'Google',
            'DocNeX.care',
            'Portal',
            'Lab',
            'Pharmacy'
          ],
        ),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),

          // Notifications
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),

          // User profile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CircleAvatar(
              backgroundColor: primaryColor,
              radius: 16,
              child: const Text(
                'DR',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: _isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
        child: const Center(
          child: Text('DocNeX Healthcare Dashboard'),
        ),
      ),
    );
  }
}
