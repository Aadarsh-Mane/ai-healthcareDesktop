import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NavigationItem {
  final int index;
  final IconData icon;
  final String label;
  final bool isSection;
  final String? sectionTitle;
  final List<Color>? gradientColors;
  final Color? iconColor;
  final String? keyboardShortcut;

  NavigationItem({
    required this.index,
    required this.icon,
    required this.label,
    this.isSection = false,
    this.sectionTitle,
    this.gradientColors,
    this.iconColor,
    this.keyboardShortcut,
  });
}

class ImprovedSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;
  final List<NavigationItem> navigationItems;
  final String? title;
  final String? subtitle;
  final Widget? userProfile;

  const ImprovedSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.navigationItems,
    this.title,
    this.subtitle,
    this.userProfile,
  }) : super(key: key);

  @override
  State<ImprovedSidebar> createState() => _ImprovedSidebarState();
}

class _ImprovedSidebarState extends State<ImprovedSidebar>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _sidebarAnimationController;
  late AnimationController _glowAnimationController;
  late Animation<double> _sidebarAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _sidebarAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _glowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _sidebarAnimation = CurvedAnimation(
      parent: _sidebarAnimationController,
      curve: Curves.easeInOutCubic,
    );

    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));

    if (_isExpanded) {
      _sidebarAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _sidebarAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  void _toggleSidebar() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _sidebarAnimationController.forward();
    } else {
      _sidebarAnimationController.reverse();
    }

    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_sidebarAnimation, _glowAnimation]),
      builder: (context, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
          width: _isExpanded ? 320 : 80,
          child: _PremiumSidebarContainer(
            isExpanded: _isExpanded,
            glowIntensity: _glowAnimation.value,
            child: Column(
              children: [
                // Enhanced Header
                _PremiumSidebarHeader(
                  isExpanded: _isExpanded,
                  onToggle: _toggleSidebar,
                  glowIntensity: _glowAnimation.value,
                  title: widget.title,
                  subtitle: widget.subtitle,
                ),

                // Navigation Items
                Expanded(
                  child: _PremiumNavigationList(
                    selectedIndex: widget.selectedIndex,
                    navigationItems: widget.navigationItems,
                    isExpanded: _isExpanded,
                    onDestinationSelected: widget.onDestinationSelected,
                    glowIntensity: _glowAnimation.value,
                  ),
                ),

                // Enhanced User Profile
                widget.userProfile ??
                    _PremiumUserProfile(
                      isExpanded: _isExpanded,
                      glowIntensity: _glowAnimation.value,
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PremiumSidebarContainer extends StatelessWidget {
  final bool isExpanded;
  final double glowIntensity;
  final Widget child;

  const _PremiumSidebarContainer({
    required this.isExpanded,
    required this.glowIntensity,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HospitalTheme.primaryDark,
            HospitalTheme.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(2, 0),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: HospitalTheme.accent.withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 0),
            spreadRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PremiumSidebarHeader extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final double glowIntensity;
  final String? title;
  final String? subtitle;

  const _PremiumSidebarHeader({
    required this.isExpanded,
    required this.onToggle,
    required this.glowIntensity,
    this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isExpanded ? 20 : 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isExpanded ? 48 : 40,
              height: isExpanded ? 48 : 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(glowIntensity * 0.9),
                    Colors.white.withOpacity(glowIntensity * 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(isExpanded ? 12 : 10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.local_hospital,
                color: HospitalTheme.primary,
                size: isExpanded ? 28 : 24,
              ),
            ),
          ),
          if (isExpanded) ...[
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, Color(0xFFe0e0e0)],
                    ).createShader(bounds),
                    child: Text(
                      title ?? 'DocNex',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  Text(
                    subtitle ?? 'Hospital Management',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: onToggle,
                icon: const Icon(
                  Icons.keyboard_double_arrow_left,
                  color: Colors.white,
                ),
                tooltip: 'Collapse sidebar',
              ),
            ),
          ] else
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: IconButton(
                onPressed: onToggle,
                icon: const Icon(
                  Icons.keyboard_double_arrow_right,
                  color: Colors.white,
                  size: 18,
                ),
                tooltip: 'Expand sidebar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                visualDensity: VisualDensity.compact,
              ),
            ),
        ],
      ),
    );
  }
}

class _PremiumNavigationList extends StatelessWidget {
  final int selectedIndex;
  final List<NavigationItem> navigationItems;
  final bool isExpanded;
  final Function(int) onDestinationSelected;
  final double glowIntensity;

  const _PremiumNavigationList({
    required this.selectedIndex,
    required this.navigationItems,
    required this.isExpanded,
    required this.onDestinationSelected,
    required this.glowIntensity,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        vertical: 8,
        horizontal: isExpanded ? 12 : 8,
      ),
      itemCount: navigationItems.length,
      itemBuilder: (context, index) {
        final item = navigationItems[index];

        // Section header (only when expanded)
        if (item.isSection) {
          if (!isExpanded) return const SizedBox.shrink();

          return _PremiumSectionHeader(
            title: item.sectionTitle ?? '',
            isExpanded: isExpanded,
          );
        }

        // Navigation item
        final isSelected = selectedIndex == item.index;
        return _PremiumNavigationTile(
          item: item,
          isSelected: isSelected,
          isExpanded: isExpanded,
          onTap: () => onDestinationSelected(item.index),
          glowIntensity: glowIntensity,
        );
      },
    );
  }
}

class _PremiumSectionHeader extends StatelessWidget {
  final String title;
  final bool isExpanded;

  const _PremiumSectionHeader({
    required this.title,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white.withOpacity(0.6),
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class _PremiumNavigationTile extends StatefulWidget {
  final NavigationItem item;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  final double glowIntensity;

  const _PremiumNavigationTile({
    required this.item,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
    required this.glowIntensity,
  });

  @override
  State<_PremiumNavigationTile> createState() => _PremiumNavigationTileState();
}

class _PremiumNavigationTileState extends State<_PremiumNavigationTile>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnimation;

  // Default gradient colors if not specified
  List<Color> get _gradientColors =>
      widget.item.gradientColors ??
      [
        const Color(0xFF667eea),
        const Color(0xFF764ba2),
      ];

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: EdgeInsets.symmetric(
              vertical: widget.isExpanded ? 6 : 4,
              horizontal: widget.isExpanded ? 0 : 2,
            ),
            child: MouseRegion(
              onEnter: (_) {
                setState(() => _isHovered = true);
                _hoverController.forward();
              },
              onExit: (_) {
                setState(() => _isHovered = false);
                _hoverController.reverse();
              },
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius:
                      BorderRadius.circular(widget.isExpanded ? 16 : 12),
                  splashColor: _gradientColors.first.withOpacity(0.3),
                  highlightColor: _gradientColors.first.withOpacity(0.1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    constraints: BoxConstraints(
                      minHeight: widget.isExpanded ? 56 : 48,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isExpanded ? 16 : 8,
                      vertical: widget.isExpanded ? 16 : 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: widget.isSelected || _isHovered
                          ? LinearGradient(
                              colors: [
                                _gradientColors.first.withOpacity(
                                  widget.isSelected ? 0.8 : 0.4,
                                ),
                                _gradientColors.last.withOpacity(
                                  widget.isSelected ? 0.6 : 0.2,
                                ),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      borderRadius:
                          BorderRadius.circular(widget.isExpanded ? 16 : 12),
                      border: widget.isSelected
                          ? Border.all(
                              color: _gradientColors.first.withOpacity(0.6),
                              width: widget.isExpanded ? 2 : 1,
                            )
                          : null,
                      boxShadow: widget.isSelected
                          ? [
                              BoxShadow(
                                color: _gradientColors.first.withOpacity(0.4),
                                blurRadius: widget.isExpanded ? 15 : 10,
                                offset: const Offset(0, 4),
                                spreadRadius: widget.isExpanded ? 2 : 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: widget.isExpanded
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      mainAxisAlignment: widget.isExpanded
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.all(widget.isExpanded ? 8 : 6),
                          decoration: BoxDecoration(
                            color: widget.isSelected
                                ? Colors.white.withOpacity(0.2)
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(
                                widget.isExpanded ? 10 : 8),
                          ),
                          child: Icon(
                            widget.item.icon,
                            color: widget.isSelected || _isHovered
                                ? Colors.white
                                : Colors.white.withOpacity(0.8),
                            size: widget.isExpanded ? 24 : 20,
                          ),
                        ),
                        if (widget.isExpanded) ...[
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.item.label,
                                  style: TextStyle(
                                    color: widget.isSelected || _isHovered
                                        ? Colors.white
                                        : Colors.white.withOpacity(0.9),
                                    fontWeight: widget.isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                if (widget.item.keyboardShortcut != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    widget.item.keyboardShortcut!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.white.withOpacity(0.6),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (widget.isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios,
                                size: 12,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PremiumUserProfile extends StatelessWidget {
  final bool isExpanded;
  final double glowIntensity;

  const _PremiumUserProfile({
    required this.isExpanded,
    required this.glowIntensity,
  });

  @override
  Widget build(BuildContext context) {
    if (!isExpanded) {
      return Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.person,
            color: Colors.white.withOpacity(0.8),
            size: 20,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(glowIntensity * 0.8),
                  Colors.white.withOpacity(glowIntensity * 0.6),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.local_hospital,
              color: HospitalTheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Colors.white, Color(0xFFe0e0e0)],
                  ).createShader(bounds),
                  child: Text(
                    'DocNex.Care',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF43e97b).withOpacity(0.5),
                            blurRadius: 6,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '20s Developers',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
