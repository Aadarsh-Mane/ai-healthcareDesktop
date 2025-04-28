import 'package:flutter/material.dart';

class SubmenuItem {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  SubmenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
