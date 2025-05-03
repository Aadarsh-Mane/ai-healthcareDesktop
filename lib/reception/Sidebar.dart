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
      width: _isExpanded ? 280 : 90,
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
              horizontal: _isExpanded ? 24 : 10,
              vertical: 24,
            ),
            child: Row(
              mainAxisAlignment: _isExpanded
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: HospitalTheme.radiusMedium,
                  ),
                  child: Icon(
                    Icons.local_hospital,
                    color: HospitalTheme.primary,
                    size: _isExpanded ? 32 : 24,
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
                ],
                IconButton(
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                  icon: Icon(
                    _isExpanded
                        ? Icons.keyboard_double_arrow_left
                        : Icons.keyboard_double_arrow_right,
                    color: HospitalTheme.textOnPrimary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Container(
            margin: EdgeInsets.symmetric(horizontal: _isExpanded ? 24 : 10),
            height: 1,
            color: HospitalTheme.textOnPrimary.withOpacity(0.1),
          ),
          const SizedBox(height: 24),

          // Navigation items
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 18 : 8),
              itemCount: widget.navigationItems.length,
              itemBuilder: (context, index) {
                final item = widget.navigationItems[index];

                // If it's a section title
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
    return Container(
      margin: EdgeInsets.all(_isExpanded ? 16 : 8),
      padding: EdgeInsets.all(_isExpanded ? 16 : 8),
      decoration: BoxDecoration(
        color: HospitalTheme.textOnPrimary.withOpacity(0.1),
        borderRadius: HospitalTheme.radiusMedium,
      ),
      child: _isExpanded
          ? Row(
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
                              color:
                                  HospitalTheme.textOnPrimary.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // PopupMenuButton(
                //   icon: Icon(
                //     Icons.more_vert,
                //     color: HospitalTheme.textOnPrimary,
                //   ),
                //   color: HospitalTheme.cardBackground,
                //   itemBuilder: (context) => [
                //     PopupMenuItem(
                //       value: 'profile',
                //       child: Row(
                //         children: [
                //           Icon(Icons.person_outline,
                //               color: HospitalTheme.primary, size: 20),
                //           const SizedBox(width: 8),
                //           Text('My Profile'),
                //         ],
                //       ),
                //     ),
                //     PopupMenuItem(
                //       value: 'logout',
                //       child: Row(
                //         children: [
                //           Icon(Icons.logout,
                //               color: HospitalTheme.error, size: 20),
                //           const SizedBox(width: 8),
                //           Text('Logout'),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),
              ],
            )
          : Center(
              child: CircleAvatar(
                radius: 24,
                backgroundColor: HospitalTheme.textOnPrimary.withOpacity(0.2),
                child: Icon(
                  Icons.person,
                  color: HospitalTheme.textOnPrimary,
                  size: 28,
                ),
              ),
            ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData icon,
    String label,
    bool isSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => widget.onDestinationSelected(index),
        borderRadius: HospitalTheme.radiusMedium,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
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
              if (_isExpanded) ...[
                const SizedBox(width: 16),
                Text(
                  label,
                  style: TextStyle(
                    color: HospitalTheme.textOnPrimary,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
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
            ],
          ),
        ),
      ),
    );
  }
}
