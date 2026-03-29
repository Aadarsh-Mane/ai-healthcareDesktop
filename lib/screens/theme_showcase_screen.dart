import 'package:doctordesktop/core/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Theme Showcase Screen - Demonstrates all theme components
/// Visual testing for the new theme files in the files/ folder
class ThemeShowcaseScreen extends ConsumerWidget {
  const ThemeShowcaseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        title: Text(
          'Healthcare Theme Showcase',
          style: AppTypography.headingXl.copyWith(
            color: AppColors.textOnPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.s32,
            children: [
              // ─── Colors Section ───────────────────────────────────────────
              _buildSection(
                title: 'Color Palette',
                child: Column(
                  spacing: AppSpacing.s16,
                  children: [
                    _buildColorRow('Primary', AppColors.primary),
                    _buildColorRow('Primary Light', AppColors.primaryLight),
                    _buildColorRow('Primary Dark', AppColors.primaryDark),
                    _buildColorRow('Success', AppColors.success),
                    _buildColorRow('Danger', AppColors.danger),
                    _buildColorRow('Warning', AppColors.warning),
                    _buildColorRow('Info', AppColors.info),
                  ],
                ),
              ),

              // ─── Status Badges ────────────────────────────────────────────
              _buildSection(
                title: 'Status Badges',
                child: Wrap(
                  spacing: AppSpacing.s12,
                  runSpacing: AppSpacing.s12,
                  children: [
                    _buildStatusBadge('Active', AppColors.success),
                    _buildStatusBadge('Pending', AppColors.warning),
                    _buildStatusBadge('Critical', AppColors.danger),
                    _buildStatusBadge('Info', AppColors.info),
                  ],
                ),
              ),

              // ─── Typography Section ───────────────────────────────────────
              _buildSection(
                title: 'Typography',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.s16,
                  children: [
                    Text('Display 2XL', style: AppTypography.display2xl),
                    Text('Display XL', style: AppTypography.displayXl),
                    Text('Display Lg', style: AppTypography.displayLg),
                    Text('Heading XL', style: AppTypography.headingXl),
                    Text('Heading Lg', style: AppTypography.headingLg),
                    Text('Body text - Regular', style: AppTypography.bodyLg),
                    Text('Body text - Secondary',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.textSecondary,
                        )),
                  ],
                ),
              ),

              // ─── Buttons Section ──────────────────────────────────────────
              _buildSection(
                title: 'Buttons & CTA',
                child: Wrap(
                  spacing: AppSpacing.s12,
                  runSpacing: AppSpacing.s12,
                  children: [
                    _buildButton('Primary', AppColors.primary),
                    _buildButton('Success', AppColors.success),
                    _buildButton('Danger', AppColors.danger),
                    _buildButton('Secondary', AppColors.info),
                    _buildOutlineButton('Outline'),
                  ],
                ),
              ),

              // ─── Patient Card Example ──────────────────────────────────────
              _buildSection(
                title: 'Patient Card Example',
                child: _buildPatientCard(),
              ),

              // ─── Doctor List Item Example ──────────────────────────────────
              _buildSection(
                title: 'Doctor List Item',
                child: _buildDoctorListItem(),
              ),

              // ─── Stats Cards ────────────────────────────────────────────────
              _buildSection(
                title: 'Dashboard Stats',
                child: Row(
                  spacing: AppSpacing.s16,
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Total Patients',
                        value: '245',
                        icon: Icons.people,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Appointments',
                        value: '18',
                        icon: Icons.calendar_today,
                      ),
                    ),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Pending Tests',
                        value: '7',
                        icon: Icons.label,
                      ),
                    ),
                  ],
                ),
              ),

              // ─── Input Fields ──────────────────────────────────────────────
              _buildSection(
                title: 'Input Fields',
                child: Column(
                  spacing: AppSpacing.s16,
                  children: [
                    _buildTextField(
                      label: 'Patient Name',
                      hint: 'Enter patient name',
                    ),
                    _buildTextField(
                      label: 'Email Address',
                      hint: 'patient@example.com',
                    ),
                    _buildTextField(
                      label: 'Medical Notes',
                      hint: 'Enter clinical notes here...',
                      maxLines: 3,
                    ),
                  ],
                ),
              ),

              // ─── Alert Messages ───────────────────────────────────────────
              _buildSection(
                title: 'Alert Messages',
                child: Column(
                  spacing: AppSpacing.s12,
                  children: [
                    _buildAlert('Success!', 'Patient registered successfully.',
                        AppColors.success),
                    _buildAlert('Warning', 'Prescription expires in 2 days.',
                        AppColors.warning),
                    _buildAlert(
                        'Critical',
                        'Lab test requires immediate attention.',
                        AppColors.danger),
                  ],
                ),
              ),

              // ─── Spacing Reference ────────────────────────────────────────
              _buildSection(
                title: 'Spacing Reference',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.s12,
                  children: [
                    _buildSpacingBox('s8', AppSpacing.s8),
                    _buildSpacingBox('s12', AppSpacing.s12),
                    _buildSpacingBox('s16', AppSpacing.s16),
                    _buildSpacingBox('s24', AppSpacing.s24),
                    _buildSpacingBox('s32', AppSpacing.s32),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.s24),
            ],
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────────────────────────
  // Helper Widgets
  // ────────────────────────────────────────────────────────────────────────────

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.s12,
      children: [
        Text(title, style: AppTypography.headingLg),
        Container(
          decoration: BoxDecoration(
            color: AppColors.sectionBg,
            borderRadius: AppRadius.radiusXl,
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(AppSpacing.s20),
          child: child,
        ),
      ],
    );
  }

  Widget _buildColorRow(String label, Color color) {
    return Row(
      spacing: AppSpacing.s12,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.radiusLg,
            border: Border.all(color: AppColors.border),
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.bodyLg),
              Text(
                color.toString(),
                style: AppTypography.bodySm.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: AppRadius.radiusMd,
      ),
      child: Text(
        label,
        style: AppTypography.bodySm.copyWith(color: color),
      ),
    );
  }

  Widget _buildButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.textOnPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.button,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s24,
          vertical: AppSpacing.s12,
        ),
      ),
      child: Text(label, style: AppTypography.bodySm),
    );
  }

  Widget _buildOutlineButton(String label) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primary, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.button,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s24,
          vertical: AppSpacing.s12,
        ),
      ),
      child: Text(
        label,
        style: AppTypography.bodySm.copyWith(color: AppColors.primary),
      ),
    );
  }

  Widget _buildPatientCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s12,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.s4,
                children: [
                  Text(
                    'John Doe',
                    style: AppTypography.bodySm.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Patient ID: #12345',
                    style: AppTypography.bodySm.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s8,
                  vertical: AppSpacing.s4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.successLight,
                  borderRadius: AppRadius.radiusSm,
                ),
                child: Text(
                  'Active',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.success,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          Divider(color: AppColors.divider, height: AppSpacing.s12),
          Row(
            spacing: AppSpacing.s16,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.s4,
                  children: [
                    Text(
                      'Age',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text('35', style: AppTypography.bodySm),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.s4,
                  children: [
                    Text(
                      'Blood Type',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text('O+', style: AppTypography.bodySm),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpacing.s4,
                  children: [
                    Text(
                      'Contact',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text('+1 (555) 123-4567',
                        style: AppTypography.bodySm.copyWith(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDoctorListItem() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Row(
        spacing: AppSpacing.s12,
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.radiusXl,
            ),
            child: Icon(
              Icons.person,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          // Doctor Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s4,
              children: [
                Text(
                  'Dr. Sarah Johnson',
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Cardiologist • Available',
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          // Action Button
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.arrow_forward_ios,
                color: AppColors.primary, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.s12,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: AppRadius.radiusLg,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          Text(
            value,
            style: AppTypography.displayLg.copyWith(fontSize: 28),
          ),
          Text(
            title,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.s6,
      children: [
        Text(label, style: AppTypography.bodySm),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodySm.copyWith(
              color: AppColors.textDisabled,
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.s12),
            border: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.input,
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAlert(String title, String message, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: AppRadius.radiusLg,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      padding: const EdgeInsets.all(AppSpacing.s12),
      child: Row(
        spacing: AppSpacing.s12,
        children: [
          Icon(Icons.info, color: color, size: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.s2,
              children: [
                Text(
                  title,
                  style: AppTypography.bodySm.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  message,
                  style: AppTypography.bodySm.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingBox(String label, double size) {
    return Row(
      spacing: AppSpacing.s12,
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: AppTypography.bodySm),
        ),
        Container(
          width: size * 2,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: AppRadius.radiusXs,
          ),
        ),
        Text('${(size * 2).toStringAsFixed(0)}px',
            style: AppTypography.bodySm.copyWith(
              color: AppColors.textSecondary,
            )),
      ],
    );
  }
}
