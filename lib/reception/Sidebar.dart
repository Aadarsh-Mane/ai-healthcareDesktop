import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:flutter/material.dart';

class NavigationItem {
  final int index;
  final IconData icon;
  final String label;
  final bool isSection;
  final String? sectionTitle;

  NavigationItem({
    required this.index,
    required this.icon,
    required this.label,
    this.isSection = false,
    this.sectionTitle,
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

class _ImprovedSidebarState extends State<ImprovedSidebar> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width:
          _isExpanded ? 280 : 70, // Reduced collapsed width to prevent overflow
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            HospitalTheme.primaryDark,
            HospitalTheme.primary,
          ],
        ),
        boxShadow: HospitalTheme.shadow,
      ),
      child: Column(
        children: [
          // Hospital logo and name area
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded
                  ? 24
                  : 8, // Smaller horizontal padding when collapsed
              vertical: _isExpanded
                  ? 24
                  : 16, // Smaller vertical padding when collapsed
            ),
            child: Row(
              mainAxisAlignment: _isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                if (_isExpanded)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: HospitalTheme.radiusMedium,
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      color: HospitalTheme.primary,
                      size: 32,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6), // Smaller padding
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: HospitalTheme.radiusSmall, // Smaller radius
                    ),
                    child: Icon(
                      Icons.local_hospital,
                      color: HospitalTheme.primary,
                      size: 18, // Smaller icon
                    ),
                  ),
                if (_isExpanded) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title ?? 'MedCare',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textOnPrimary,
                          ),
                        ),
                        Text(
                          widget.subtitle ?? 'Hospital Management',
                          style: TextStyle(
                            fontSize: 12,
                            color: HospitalTheme.textOnPrimary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                      Icons.keyboard_double_arrow_left,
                      color: HospitalTheme.textOnPrimary.withOpacity(0.7),
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
                ] else
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    icon: Icon(
                      Icons.keyboard_double_arrow_right,
                      color: HospitalTheme.textOnPrimary.withOpacity(0.7),
                      size: 16, // Smaller icon
                    ),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),

          // Divider
          Container(
            margin: EdgeInsets.symmetric(horizontal: _isExpanded ? 24 : 8),
            height: 1,
            color: HospitalTheme.textOnPrimary.withOpacity(0.1),
          ),
          const SizedBox(height: 12), // Reduced height

          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                  horizontal:
                      _isExpanded ? 18 : 5), // Smaller padding when collapsed
              itemCount: widget.navigationItems.length,
              itemBuilder: (context, index) {
                final item = widget.navigationItems[index];

                // If it's a section title and sidebar is expanded
                if (item.isSection && _isExpanded) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      item.sectionTitle ?? '',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textOnPrimary.withOpacity(0.5),
                        letterSpacing: 1.5,
                      ),
                    ),
                  );
                }

                // Skip section items when collapsed
                if (item.isSection && !_isExpanded) {
                  return SizedBox.shrink();
                }

                return _buildNavItem(
                  item.index,
                  item.icon,
                  item.label,
                  widget.selectedIndex == item.index,
                );
              },
            ),
          ),

          // User profile section
          widget.userProfile ?? _buildDefaultUserProfile(),
        ],
      ),
    );
  }

  Widget _buildDefaultUserProfile() {
    if (!_isExpanded) {
      // Ultra-simplified profile for collapsed state
      return Container(
        margin: EdgeInsets.all(6),
        padding: EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: HospitalTheme.textOnPrimary.withOpacity(0.1),
          borderRadius: HospitalTheme.radiusSmall,
        ),
        child: Center(
          child: Icon(
            Icons.person,
            color: HospitalTheme.textOnPrimary,
            size: 18,
          ),
        ),
      );
    }

    // Full profile for expanded state
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: HospitalTheme.textOnPrimary.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusMedium,
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: HospitalTheme.textOnPrimary.withOpacity(0.2),
            child: Icon(
              Icons.local_hospital,
              color: HospitalTheme.textOnPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DocNex.Care',
                  style: TextStyle(
                    color: HospitalTheme.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: HospitalTheme.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '20s Developers',
                      style: TextStyle(
                        color: HospitalTheme.textOnPrimary.withOpacity(0.8),
                        fontSize: 12,
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

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    // For collapsed sidebar - bare minimum layout
    if (!_isExpanded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: InkWell(
          onTap: () => widget.onDestinationSelected(index),
          borderRadius: BorderRadius.circular(6), // Smaller radius
          child: Container(
            width: 40, // Fixed width to prevent overflow
            height: 40, // Fixed height for consistency
            padding: const EdgeInsets.all(0), // No padding
            decoration: BoxDecoration(
              color: isSelected
                  ? HospitalTheme.textOnPrimary.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6), // Smaller radius
            ),
            child: Center(
              child: Icon(
                icon,
                color: isSelected
                    ? HospitalTheme.textOnPrimary
                    : HospitalTheme.textOnPrimary.withOpacity(0.7),
                size: 16, // Smaller icon size
              ),
            ),
          ),
        ),
      );
    }

    // For expanded sidebar - original version with more details
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => widget.onDestinationSelected(index),
        borderRadius: HospitalTheme.radiusMedium,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? HospitalTheme.textOnPrimary.withOpacity(0.2)
                : Colors.transparent,
            borderRadius: HospitalTheme.radiusMedium,
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      HospitalTheme.textOnPrimary.withOpacity(0.1),
                      HospitalTheme.textOnPrimary.withOpacity(0.2),
                    ],
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? HospitalTheme.textOnPrimary
                      : Colors.transparent,
                  borderRadius: HospitalTheme.radiusSmall,
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? HospitalTheme.primary
                      : HospitalTheme.textOnPrimary.withOpacity(0.8),
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(
                  color: HospitalTheme.textOnPrimary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    color: HospitalTheme.textOnPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
