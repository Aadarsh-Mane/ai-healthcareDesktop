import 'package:flutter/material.dart';

class HorizontalCenterDrawer extends StatefulWidget {
  final Widget child;
  final double closedWidth;
  final double openWidth;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final Duration animationDuration;

  const HorizontalCenterDrawer({
    Key? key,
    required this.child,
    this.closedWidth = 50.0,
    this.openWidth = 300.0,
    this.backgroundColor = Colors.white,
    this.borderRadius = const BorderRadius.all(Radius.circular(8.0)),
    this.animationDuration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  _HorizontalCenterDrawerState createState() => _HorizontalCenterDrawerState();
}

class _HorizontalCenterDrawerState extends State<HorizontalCenterDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _widthAnimation;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _widthAnimation = Tween<double>(
      begin: widget.closedWidth,
      end: widget.openWidth,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: _widthAnimation.value,
          height: 600, // Explicitly set height to match column heights
          margin: const EdgeInsets.symmetric(horizontal: 8.0),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: _isOpen
              ? Column(
                  children: [
                    // Header with close button
                    Container(
                      height: 40,
                      width: double.infinity, // Ensure width is set
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF005F9E), Color(0xFF00B8D4)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(8),
                          topRight: Radius.circular(8),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Text(
                              "Doctor Notes",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.white),
                            onPressed: _toggleDrawer,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(), // Remove constraints
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Expanded(
                      child: Container(
                        width: double.infinity, // Ensure width is set
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16.0),
                          child: widget.child,
                        ),
                      ),
                    ),
                  ],
                )
              : // Closed state - vertical tab with icon
              InkWell(
                  onTap: _toggleDrawer,
                  child: Container(
                    width: double.infinity, // Ensure width is set
                    height: double.infinity, // Ensure height is set
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF005F9E), Color(0xFF00B8D4)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: widget.borderRadius,
                    ),
                    child: Center(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notes,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 8),
                              Text(
                                "DOCTOR NOTES",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}
