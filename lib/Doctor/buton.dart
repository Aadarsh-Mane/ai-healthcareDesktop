import 'package:flutter/material.dart';

class CustomActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isLoading;
  final double width;
  final double height;
  final double iconSize;
  final double fontSize;
  final EdgeInsets padding;

  const CustomActionButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isLoading = false,
    this.width = 100, // Increased default width
    this.height = 60, // Increased default height
    this.iconSize = 24, // Slightly larger icon
    this.fontSize = 12, // Adjustable font size
    this.padding = const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: padding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isLoading
                  ? CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : Icon(icon, size: iconSize, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
