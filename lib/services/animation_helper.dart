// lib/utils/animation_helper.dart - Fixed Version
import 'package:flutter/material.dart';

class FadeSlideTransition extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;
  final Offset beginOffset;
  final Curve curve;

  const FadeSlideTransition({
    required this.child,
    required this.animation,
    this.beginOffset = const Offset(0, 0.25),
    this.curve = Curves.easeOutCubic,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: curve,
        );

        return Opacity(
          opacity: curvedAnimation.value,
          child: Transform.translate(
            offset: Offset(
              beginOffset.dx * (1 - curvedAnimation.value),
              beginOffset.dy * (1 - curvedAnimation.value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class StaggeredAnimations extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration staggerDuration;
  final Curve curve;
  final Axis direction;

  const StaggeredAnimations({
    required this.children,
    this.itemDuration = const Duration(milliseconds: 600),
    this.staggerDuration = const Duration(milliseconds: 50),
    this.curve = Curves.easeOutCubic,
    this.direction = Axis.vertical,
    Key? key,
  }) : super(key: key);

  @override
  _StaggeredAnimationsState createState() => _StaggeredAnimationsState();
}

class _StaggeredAnimationsState extends State<StaggeredAnimations>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Create the controller with a duration proportional to the number of children
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: widget.itemDuration.inMilliseconds +
            (widget.staggerDuration.inMilliseconds *
                (widget.children.length - 1)),
      ),
    );

    // Create animations for each child
    _createAnimations();

    // Start the animations
    _controller.forward();
  }

  void _createAnimations() {
    _animations = List.generate(
      widget.children.length,
      (index) {
        final start = index *
            widget.staggerDuration.inMilliseconds /
            _controller.duration!.inMilliseconds;
        final end = start +
            widget.itemDuration.inMilliseconds /
                _controller.duration!.inMilliseconds;

        return Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: widget.curve),
          ),
        );
      },
    );
  }

  @override
  void didUpdateWidget(StaggeredAnimations oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the number of children changed, we need to recreate the animations
    if (widget.children.length != oldWidget.children.length) {
      _controller.dispose();
      _initializeAnimations();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.direction == Axis.vertical
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildAnimatedChildren(),
          )
        : Row(
            children: _buildAnimatedChildren(),
          );
  }

  List<Widget> _buildAnimatedChildren() {
    // Make sure we don't try to access animations that don't exist
    final animationCount = _animations.length;
    final childrenCount = widget.children.length;

    return List.generate(
      childrenCount,
      (index) {
        // Use the corresponding animation if it exists, or the last animation if we're beyond the array
        final animationIndex =
            index < animationCount ? index : animationCount - 1;
        final animation = animationIndex >= 0
            ? _animations[animationIndex]
            : _animations.last;

        return FadeSlideTransition(
          animation: animation,
          child: widget.children[index],
        );
      },
    );
  }
}
