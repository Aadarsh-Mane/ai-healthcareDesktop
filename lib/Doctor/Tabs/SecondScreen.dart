import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Second Screen")),
      body: Center(child: Text("This screen falls from the top!")),
    );
  }
}

PageRouteBuilder _createFallingPageRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, -1), // Starts from the top
          end: Offset(0, 0), // Ends at the normal position
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut, // Smooth falling effect
        )),
        child: child,
      );
    },
  );
}
