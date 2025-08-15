import 'package:flutter/material.dart';

/// Professional Insurance Panel Theme
///
/// A sophisticated, trustworthy theme for insurance management desktop application
/// featuring corporate colors, subtle animations, and professional aesthetics.
class InsuranceTheme {
  // Professional Corporate Colors
  static const Color primaryNavy = Color(0xFF1E3A8A); // Deep navy blue
  static const Color primaryBlue = Color(0xFF3B82F6); // Professional blue
  static const Color secondaryTeal = Color(0xFF0891B2); // Corporate teal
  static const Color accentGold = Color(0xFFD97706); // Professional gold/amber

  // Neutral Professional Colors
  static const Color darkGray = Color(0xFF374151); // Professional dark gray
  static const Color mediumGray = Color(0xFF6B7280); // Medium gray
  static const Color lightGray = Color(0xFF9CA3AF); // Light gray
  static const Color backgroundGray =
      Color(0xFFF9FAFB); // Very light background

  // Status Colors (Professional)
  static const Color successGreen = Color(0xFF059669); // Professional green
  static const Color warningAmber = Color(0xFFF59E0B); // Professional amber
  static const Color errorRed = Color(0xFFDC2626); // Professional red
  static const Color infoBlue = Color(0xFF2563EB); // Professional info blue

  // Glass Morphism (Subtle)
  static const Color glassBackground = Color(0x08FFFFFF); // Very subtle glass
  static const Color glassBorder = Color(0x20FFFFFF); // Subtle border
  static const Color cardSurface = Color(0xFFFFFFFF); // Clean white cards

  // Background & Surface Colors
  static const Color backgroundStart =
      Color(0xFFF8FAFC); // Very light blue-gray
  static const Color backgroundEnd = Color(0xFFE2E8F0); // Light blue-gray
  static const Color surfaceElevated = Color(0xFFFFFFFF); // Pure white

  // Text Colors (Professional)
  static const Color textPrimary = Color(0xFF1F2937); // Dark gray text
  static const Color textSecondary = Color(0xFF4B5563); // Medium gray text
  static const Color textTertiary = Color(0xFF6B7280); // Light gray text
  static const Color textOnPrimary = Colors.white;
  static const Color textOnAccent = Colors.white;

  // Animation Durations (Subtle)
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 250);
  static const Duration slowAnimation = Duration(milliseconds: 400);

  // Professional Shadows
  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 10,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  // Professional Border Radius
  static BorderRadius get radiusSmall => BorderRadius.circular(8);
  static BorderRadius get radiusMedium => BorderRadius.circular(12);
  static BorderRadius get radiusLarge => BorderRadius.circular(16);
  static BorderRadius get radiusXLarge => BorderRadius.circular(24);

  // Professional Gradients (Subtle)
  static LinearGradient get primaryGradient => LinearGradient(
        colors: [primaryNavy, primaryBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get secondaryGradient => LinearGradient(
        colors: [secondaryTeal, primaryBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get accentGradient => LinearGradient(
        colors: [accentGold, Color(0xFFEAB308)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get successGradient => LinearGradient(
        colors: [successGreen, Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get backgroundGradient => LinearGradient(
        colors: [backgroundStart, backgroundEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // Professional Theme Data
  static ThemeData get themeData => ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(
          primary: primaryBlue,
          secondary: secondaryTeal,
          surface: surfaceElevated,
          background: backgroundStart,
          onPrimary: textOnPrimary,
          onSecondary: textOnAccent,
          onSurface: textPrimary,
          onBackground: textPrimary,
        ),
        scaffoldBackgroundColor: backgroundStart,
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'Inter', // Professional font
            ),
        appBarTheme: AppBarTheme(
          backgroundColor: surfaceElevated,
          elevation: 1,
          shadowColor: Colors.black.withOpacity(0.1),
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceElevated,
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.08),
          shape: RoundedRectangleBorder(
            borderRadius: radiusMedium,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: textOnPrimary,
            elevation: 2,
            shadowColor: primaryBlue.withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: radiusSmall,
            ),
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.3,
            ),
          ),
        ),
      );

  // PROFESSIONAL COMPONENTS

  /// Creates a professional card with subtle styling
  static Widget buildProfessionalCard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    bool isHoverable = false,
    VoidCallback? onTap,
    BorderRadius? borderRadius,
    Color? backgroundColor,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: isHoverable ? (_) => setState(() => isHovered = true) : null,
          onExit: isHoverable ? (_) => setState(() => isHovered = false) : null,
          child: AnimatedContainer(
            duration: normalAnimation,
            transform: (isHoverable && isHovered)
                ? (Matrix4.identity()..translate(0.0, -2.0))
                : Matrix4.identity(),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding: padding ?? const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: backgroundColor ?? surfaceElevated,
                  borderRadius: borderRadius ?? radiusMedium,
                  border: Border.all(
                    color: Color(0xFFE5E7EB),
                    width: 1,
                  ),
                  boxShadow: isHovered ? elevatedShadow : cardShadow,
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Creates a professional button with corporate styling
  static Widget buildProfessionalButton({
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    bool isOutlined = false,
    bool isLoading = false,
    double? width,
    double? height,
  }) {
    final bgColor = backgroundColor ?? primaryBlue;
    final fgColor = textColor ?? textOnPrimary;

    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;

        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: normalAnimation,
            width: width,
            height: height ?? 44,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isOutlined ? Colors.transparent : bgColor,
                foregroundColor: isOutlined ? bgColor : fgColor,
                side:
                    isOutlined ? BorderSide(color: bgColor, width: 1.5) : null,
                elevation: isHovered && !isOutlined ? 4 : (isOutlined ? 0 : 2),
                shadowColor: bgColor.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: radiusSmall,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(
                          isOutlined ? bgColor : fgColor,
                        ),
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, size: 18),
                  if (icon != null && !isLoading) const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Creates a professional status badge
  static Widget buildStatusBadge(
    String text, {
    Color? color,
    bool isOutlined = false,
  }) {
    final badgeColor = color ?? successGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
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
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Creates a professional app bar
  static PreferredSizeWidget buildProfessionalAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    bool showBackButton = true,
    VoidCallback? onBackPressed,
    String? subtitle,
  }) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: TextStyle(
                color: textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
      backgroundColor: surfaceElevated,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      actions: actions,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_rounded,
                color: textPrimary,
                size: 20,
              ),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
    );
  }

  /// Creates a professional metric card
  static Widget buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
    String? subtitle,
    String? trend,
    bool showTrend = false,
  }) {
    final color = iconColor ?? primaryBlue;

    return buildProfessionalCard(
      isHoverable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: radiusSmall,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              if (trend != null && showTrend)
                buildStatusBadge(
                  trend,
                  color: trend.startsWith('+') ? successGreen : errorRed,
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: textTertiary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Creates a professional client card
  static Widget buildClientCard({
    required String clientName,
    required String clientId,
    required String policyType,
    required String status,
    String? premiumAmount,
    String? nextDue,
    VoidCallback? onView,
    VoidCallback? onEdit,
    bool isPriority = false,
  }) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'active':
        statusColor = successGreen;
        break;
      case 'expired':
        statusColor = errorRed;
        break;
      case 'pending':
        statusColor = warningAmber;
        break;
      default:
        statusColor = infoBlue;
    }

    return buildProfessionalCard(
      isHoverable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: radiusSmall,
                ),
                child: Icon(
                  isPriority ? Icons.star_rounded : Icons.person_rounded,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clientName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: $clientId',
                      style: TextStyle(
                        fontSize: 13,
                        color: textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              buildStatusBadge(status, color: statusColor),
            ],
          ),

          const SizedBox(height: 16),

          // Policy Info
          _buildInfoRow('Policy Type', policyType, Icons.policy_rounded),
          if (premiumAmount != null)
            _buildInfoRow('Premium', premiumAmount, Icons.payments_rounded),
          if (nextDue != null)
            _buildInfoRow('Next Due', nextDue, Icons.schedule_rounded),

          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              if (onView != null)
                Expanded(
                  child: buildProfessionalButton(
                    label: 'View',
                    icon: Icons.visibility_rounded,
                    onPressed: onView,
                    isOutlined: true,
                  ),
                ),
              if (onEdit != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: buildProfessionalButton(
                    label: 'Edit',
                    icon: Icons.edit_rounded,
                    onPressed: onEdit,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Helper for info rows
  static Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: textTertiary,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Creates a professional dashboard layout
  static Widget buildDashboardSection({
    required String title,
    required Widget child,
    List<Widget>? actions,
    IconData? titleIcon,
  }) {
    return buildProfessionalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (titleIcon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: radiusSmall,
                  ),
                  child: Icon(
                    titleIcon,
                    color: primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              if (actions != null) ...actions,
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  /// Creates a professional floating action button
  static Widget buildProfessionalFAB({
    required IconData icon,
    required VoidCallback onPressed,
    String? tooltip,
    Color? backgroundColor,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      tooltip: tooltip,
      backgroundColor: backgroundColor ?? primaryBlue,
      foregroundColor: textOnPrimary,
      elevation: 4,
      child: Icon(icon, size: 24),
    );
  }

  /// Creates a professional background
  static Widget buildProfessionalBackground({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: backgroundGradient,
      ),
      child: child,
    );
  }
}
