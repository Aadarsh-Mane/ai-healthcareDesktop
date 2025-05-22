import 'package:flutter/material.dart';

/// Hospital Management System Theme
///
/// A consistent theme for the entire hospital management application
/// with custom colors, text styles, and component designs.
class HospitalTheme {
  // Primary colors
  static const Color primaryDark = Color(0xFF00477A); // Deep blue
  static const Color primary = Color(0xFF005F9E); // Main blue
  static const Color primaryLight = Color(0xFF0288D1); // Light blue
  static const Color accent = Color(0xFF00B8D4); // Accent teal

  // Secondary colors
  static const Color secondary = Color(0xFF00B8D4); // Teal
  static const Color secondaryLight = Color(0xFF4DD0E1); // Light teal

  // Background colors
  static const Color background =
      Color(0xFFF8FBFD); // Very light blue-tinted gray
  static const Color cardBackground = Colors.white;
  static const Color surfaceLight =
      Color(0xFFE1F5FE); // Light blue surface (blue.shade50)
  static const Color navBackground = Color(0xFF005F9E); // Main blue

  // Medical-themed colors
  static const Color medical = Color(0xFF2196F3); // Medical blue
  static const Color pharmacy = Color(0xFF26A69A); // Pharmacy teal
  static const Color laboratory = Color(0xFF7E57C2); // Laboratory purple
  static const Color emergency = Color(0xFFEF5350); // Emergency red

  // Status colors
  static const Color success = Color(0xFF43A047); // Success green
  static const Color warning = Color(0xFFFFA000); // Warning amber
  static const Color error = Color(0xFFE53935); // Error red
  static const Color info = Color(0xFF039BE5); // Info light blue

  // Text colors
  static const Color textDark = Color(0xFF2D3748); // Near black
  static const Color textMedium = Color(0xFF5A6B7F); // Medium blue-gray
  static const Color textLight = Color(0xFF8FA3B8); // Light blue-gray
  static const Color textOnPrimary = Colors.white;
  static const Color textOnSecondary = Colors.white;

  // Border colors
  static const Color border = Color(0xFFDFEAF4); // Light blue-tinted border
  static const Color borderDark =
      Color(0xFFB5C9D8); // Medium blue-tinted border

  // Shadow
  static List<BoxShadow> get shadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get shadowSmall => [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  // Border radius
  static BorderRadius get radiusSmall => BorderRadius.circular(8);
  static BorderRadius get radiusMedium => BorderRadius.circular(12);
  static BorderRadius get radiusLarge => BorderRadius.circular(16);
  static BorderRadius get radiusXLarge => BorderRadius.circular(24);

  // Custom theme data
  static ThemeData get themeData => ThemeData(
        colorScheme: ColorScheme.light(
          primary: primary,
          primaryContainer: primaryLight,
          secondary: secondary,
          secondaryContainer: secondaryLight,
          surface: cardBackground,
          background: background,
          error: error,
        ),
        scaffoldBackgroundColor: background,
        fontFamily: 'Poppins',
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: textDark,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: primary),
        ),
        // Fixed: Use CardThemeData instead of CardTheme
        cardTheme: CardThemeData(
          color: cardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: radiusMedium,
            side: BorderSide(color: border),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: textOnPrimary,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 12,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: radiusSmall,
            ),
            elevation: 2,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          fillColor: Colors.white,
          filled: true,
          border: OutlineInputBorder(
            borderRadius: radiusSmall,
            borderSide: BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radiusSmall,
            borderSide: BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radiusSmall,
            borderSide: BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: radiusSmall,
            borderSide: BorderSide(color: error, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: TextStyle(
            color: textLight,
            fontSize: 14,
          ),
          labelStyle: TextStyle(
            color: textMedium,
            fontSize: 14,
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return primary;
              }
              return Colors.white;
            },
          ),
          side: BorderSide(color: borderDark),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        radioTheme: RadioThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return primary;
              }
              return textMedium;
            },
          ),
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: radiusSmall,
          ),
          textStyle: TextStyle(
            color: textDark,
            fontSize: 14,
          ),
        ),
        // Fixed: Use TabBarThemeData instead of TabBarTheme
        tabBarTheme: TabBarThemeData(
          labelColor: primary,
          unselectedLabelColor: textMedium,
          indicator: UnderlineTabIndicator(
            borderSide: BorderSide(
              color: primary,
              width: 2,
            ),
          ),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 16,
          ),
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            color: textDark,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: textDark,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          headlineSmall: TextStyle(
            color: textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            color: textDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: textDark,
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          bodyMedium: TextStyle(
            color: textDark,
            fontSize: 14,
            fontWeight: FontWeight.normal,
          ),
          bodySmall: TextStyle(
            color: textMedium,
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
        ),
        iconTheme: IconThemeData(
          color: textDark,
          size: 24,
        ),
        dividerTheme: DividerThemeData(
          color: border,
          thickness: 1,
          space: 24,
        ),
      );

  // Custom widgets and components

  /// Creates a styled card for the application
  static Widget buildCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    bool hasShadow = true,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? cardBackground,
        borderRadius: borderRadius ?? radiusMedium,
        border: Border.all(color: border),
        boxShadow: hasShadow ? shadowSmall : null,
      ),
      child: child,
    );
  }

  /// Creates a styled header for sections
  static Widget buildSectionHeader(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textDark,
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  /// Creates a styled gradient button
  static Widget buildGradientButton({
    required String label,
    required VoidCallback onPressed,
    required IconData icon,
    Color startColor = primary,
    Color endColor = secondary,
    double width = 160,
    double height = 38,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radiusMedium,
          boxShadow: shadowSmall,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textOnPrimary,
                    ),
                  )
                : Icon(icon, color: textOnPrimary, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: textOnPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a styled status badge
  static Widget buildStatusBadge(
    String text, {
    Color? color,
    bool outline = false,
  }) {
    final badgeColor = color ?? info;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: outline ? Colors.transparent : badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: badgeColor,
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Creates a consistent app bar for the application
  static PreferredSizeWidget buildAppBar({
    required BuildContext context, // Pass context
    required String title,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    bool centerTitle = false,
    bool showBackButton = true,
    VoidCallback? onBackPressed,
  }) {
    return AppBar(
      title: Text(title),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      centerTitle: centerTitle,
      actions: actions,
      bottom: bottom,
      backgroundColor: Color(0xFF1E2843),
      foregroundColor: textDark,
      elevation: 0,
      shadowColor: Colors.transparent,
      automaticallyImplyLeading: showBackButton,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back_ios_new, size: 20),
              onPressed:
                  onBackPressed ?? () => Navigator.pop(context), // Use context
            )
          : null,
    );
  }

  /// Creates a styled floating action button
  static Widget buildFloatingActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? backgroundColor,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? primary,
      foregroundColor: textOnPrimary,
      elevation: 4,
      child: Icon(icon),
    );
  }

  /// Creates a styled list tile
  static Widget buildListTile({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool showBorder = true,
    bool isSelected = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? surfaceLight : null,
        border: showBorder
            ? Border(bottom: BorderSide(color: border, width: 1))
            : null,
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: TextStyle(
                  color: textMedium,
                  fontSize: 13,
                ),
              )
            : null,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
      ),
    );
  }

  /// Creates a styled divider with optional label
  static Widget buildDividerWithLabel(String label) {
    return Row(
      children: [
        Expanded(
          child: Divider(color: border),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: TextStyle(
              color: textMedium,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: border),
        ),
      ],
    );
  }

  /// Creates a medical specialization chip
  static Widget buildSpecialtyChip({
    required String label,
    required IconData icon,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? primary : border,
            width: 1.5,
          ),
          boxShadow: isSelected ? null : shadowSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? primary : textMedium,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primary : textDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a styled appointment card
  static Widget buildAppointmentCard({
    required String patientName,
    required String doctorName,
    required String date,
    required String time,
    required String appointmentType,
    String? symptoms,
    bool isReadmission = false,
    VoidCallback? onView,
    VoidCallback? onEdit,
    VoidCallback? onCancel,
    String status = 'Scheduled',
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
        statusColor = success;
        break;
      case 'cancelled':
        statusColor = error;
        break;
      case 'pending':
        statusColor = warning;
        break;
      default:
        statusColor = info;
    }

    return buildCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceLight,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    patientName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ),
                buildStatusBadge(status, color: statusColor),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.medical_services_outlined,
                        size: 16, color: textMedium),
                    const SizedBox(width: 8),
                    Text(
                      'Dr. $doctorName',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.event, size: 16, color: textMedium),
                    const SizedBox(width: 8),
                    Text(
                      '$date at $time',
                      style: TextStyle(color: textMedium),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      appointmentType.toLowerCase() == 'online'
                          ? Icons.videocam_outlined
                          : Icons.person_outlined,
                      size: 16,
                      color: textMedium,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appointmentType == 'online'
                          ? 'Tele-consultation'
                          : 'In-person',
                      style: TextStyle(color: textMedium),
                    ),
                    if (isReadmission) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Readmission',
                          style: TextStyle(
                            color: warning,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (symptoms != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Symptoms:',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textDark,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    symptoms,
                    style: TextStyle(
                      color: textMedium,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (onView != null)
                      TextButton.icon(
                        onPressed: onView,
                        icon: Icon(Icons.visibility_outlined, size: 18),
                        label: Text('View'),
                        style: TextButton.styleFrom(
                          foregroundColor: primary,
                        ),
                      ),
                    if (onEdit != null)
                      TextButton.icon(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit_outlined, size: 18),
                        label: Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: info,
                        ),
                      ),
                    if (onCancel != null)
                      TextButton.icon(
                        onPressed: onCancel,
                        icon: Icon(Icons.cancel_outlined, size: 18),
                        label: Text('Cancel'),
                        style: TextButton.styleFrom(
                          foregroundColor: error,
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

  /// Creates a styled dashboard stat card
  static Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
    String? subtitle,
    bool showIncrease = false,
    String? percentageChange,
  }) {
    final iconBgColor = (iconColor ?? primary).withOpacity(0.1);
    final isPositiveChange = percentageChange != null &&
        (double.tryParse(percentageChange.replaceAll('%', '')) ?? 0) > 0;

    return buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? primary,
                  size: 24,
                ),
              ),
              const Spacer(),
              if (percentageChange != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (showIncrease && isPositiveChange ||
                            !showIncrease && !isPositiveChange)
                        ? success.withOpacity(0.1)
                        : error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (showIncrease && isPositiveChange ||
                                !showIncrease && !isPositiveChange)
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        color: (showIncrease && isPositiveChange ||
                                !showIncrease && !isPositiveChange)
                            ? success
                            : error,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        percentageChange,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: (showIncrease && isPositiveChange ||
                                  !showIncrease && !isPositiveChange)
                              ? success
                              : error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: textMedium,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: textLight,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Creates a styled patient info card
  static Widget buildPatientInfoCard({
    required String name,
    required String patientId,
    String? age,
    String? gender,
    String? bloodGroup,
    String? phoneNumber,
    String? lastVisit,
    VoidCallback? onTap,
    VoidCallback? onEditPressed,
    String? imageUrl,
  }) {
    return buildCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: radiusMedium,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: surfaceLight,
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: imageUrl == null
                        ? Icon(
                            Icons.person,
                            size: 32,
                            color: primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $patientId',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMedium,
                          ),
                        ),
                        if (lastVisit != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Last visit: $lastVisit',
                            style: TextStyle(
                              fontSize: 12,
                              color: textMedium,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onEditPressed != null)
                    IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: primary,
                        size: 20,
                      ),
                      onPressed: onEditPressed,
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (age != null)
                    _buildInfoItem(
                      label: 'Age',
                      value: age,
                      icon: Icons.calendar_today_outlined,
                    ),
                  if (gender != null)
                    _buildInfoItem(
                      label: 'Gender',
                      value: gender,
                      icon: gender.toLowerCase() == 'male'
                          ? Icons.male
                          : gender.toLowerCase() == 'female'
                              ? Icons.female
                              : Icons.people,
                    ),
                  if (bloodGroup != null)
                    _buildInfoItem(
                      label: 'Blood',
                      value: bloodGroup,
                      icon: Icons.bloodtype_outlined,
                      valueColor: medical,
                    ),
                  if (phoneNumber != null)
                    _buildInfoItem(
                      label: 'Phone',
                      value: phoneNumber,
                      icon: Icons.phone_outlined,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to build info items
  static Widget _buildInfoItem({
    required String label,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: textMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? textDark,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textMedium,
          ),
        ),
      ],
    );
  }
}
