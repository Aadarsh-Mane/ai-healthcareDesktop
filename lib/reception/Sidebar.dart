import 'package:doctordesktop/constants/HospitalTheme.dart';
import 'package:flutter/material.dart';

class ImprovedSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const ImprovedSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  }) : super(key: key);

  @override
  State<ImprovedSidebar> createState() => _ImprovedSidebarState();
}

class _ImprovedSidebarState extends State<ImprovedSidebar> {
  bool _isExpanded = false;

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
                          'MedCare',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: HospitalTheme.textOnPrimary,
                          ),
                        ),
                        Text(
                          'Hospital Management',
                          style: TextStyle(
                            fontSize: 12,
                            color: HospitalTheme.textOnPrimary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // IconButton(
                //   onPressed: () {
                //     setState(() {
                //       _isExpanded = !_isExpanded;
                //     });
                //   },
                //   icon: Icon(
                //     _isExpanded
                //         ? Icons.keyboard_double_arrow_left
                //         : Icons.keyboard_double_arrow_right,
                //     color: HospitalTheme.textOnPrimary.withOpacity(0.7),
                //   ),
                // ),
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
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: _isExpanded ? 18 : 8),
              children: [
                _buildNavItem(
                  0,
                  Icons.dashboard_rounded,
                  'Dashboard',
                  widget.selectedIndex == 0,
                ),
                _buildNavItem(
                  1,
                  Icons.calendar_month_rounded,
                  'Appointments',
                  widget.selectedIndex == 1,
                ),
                _buildNavItem(
                  2,
                  Icons.people_alt_rounded,
                  'Patients',
                  widget.selectedIndex == 2,
                ),
                _buildNavItem(
                  3,
                  Icons.medical_services_rounded,
                  'Doctors',
                  widget.selectedIndex == 3,
                ),
                _buildNavItem(
                  4,
                  Icons.medication_rounded,
                  'Pharmacy',
                  widget.selectedIndex == 4,
                ),
                _buildNavItem(
                  5,
                  Icons.analytics_rounded,
                  'Reports',
                  widget.selectedIndex == 5,
                ),
                _buildNavItem(
                  6,
                  Icons.payments_rounded,
                  'Billing',
                  widget.selectedIndex == 6,
                ),
                const SizedBox(height: 16),
                if (_isExpanded)
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(
                      'SETTINGS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: HospitalTheme.textOnPrimary.withOpacity(0.5),
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                _buildNavItem(
                  7,
                  Icons.settings_rounded,
                  'Settings',
                  widget.selectedIndex == 7,
                ),
                _buildNavItem(
                  8,
                  Icons.help_outline_rounded,
                  'Help & Support',
                  widget.selectedIndex == 8,
                ),
              ],
            ),
          ),

          // User profile section
          Container(
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
                        backgroundColor:
                            HospitalTheme.textOnPrimary.withOpacity(0.2),
                        child: Icon(
                          Icons.person,
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
                              'Reception Staff',
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
                                  'Online',
                                  style: TextStyle(
                                    color: HospitalTheme.textOnPrimary
                                        .withOpacity(0.8),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: HospitalTheme.textOnPrimary,
                        ),
                        color: HospitalTheme.cardBackground,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person_outline,
                                    color: HospitalTheme.primary, size: 20),
                                const SizedBox(width: 8),
                                Text('My Profile'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout,
                                    color: HospitalTheme.error, size: 20),
                                const SizedBox(width: 8),
                                Text('Logout'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Center(
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          HospitalTheme.textOnPrimary.withOpacity(0.2),
                      child: Icon(
                        Icons.person,
                        color: HospitalTheme.textOnPrimary,
                        size: 28,
                      ),
                    ),
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
