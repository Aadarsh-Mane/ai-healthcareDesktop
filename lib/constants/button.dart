import 'package:flutter/material.dart';

class NeumorphicButton1 extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const NeumorphicButton1(
      {super.key,
      required this.onTap,
      required this.child,
      required this.padding});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 60,
        width: 160,
        padding: padding,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E5EC),
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            // Outer shadow
            const BoxShadow(
              color: Colors.white,
              offset: Offset(-5, -5),
              blurRadius: 15,
            ),
            // Inner shadow
            const BoxShadow(
              color: Color(0xFFB3B9C5),
              offset: Offset(5, 5),
              blurRadius: 15,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
