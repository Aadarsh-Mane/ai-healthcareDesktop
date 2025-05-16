import 'package:flutter/material.dart';

class GradientBoxBorder extends BoxBorder {
  final Gradient gradient;
  final double width;

  const GradientBoxBorder({
    required this.gradient,
    this.width = 1.0,
  });

  @override
  BorderSide get top => BorderSide(width: width, color: Colors.transparent);
  @override
  BorderSide get bottom => BorderSide(width: width, color: Colors.transparent);
  @override
  BorderSide get left => BorderSide(width: width, color: Colors.transparent);
  @override
  BorderSide get right => BorderSide(width: width, color: Colors.transparent);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    if (width <= 0) return;

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;

    if (shape == BoxShape.rectangle) {
      if (borderRadius != null) {
        final RRect rrect = RRect.fromRectAndCorners(
          rect.deflate(width / 2),
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        );

        // Create a path for the rounded rectangle
        final Path path = Path()..addRRect(rrect);

        // Apply the gradient to the paint
        paint.shader = gradient.createShader(rect);

        // Draw the border
        canvas.drawPath(path, paint);
      } else {
        final Rect borderRect = rect.deflate(width / 2);

        // Create a path for the rectangle
        final Path path = Path()..addRect(borderRect);

        // Apply the gradient to the paint
        paint.shader = gradient.createShader(rect);

        // Draw the border
        canvas.drawPath(path, paint);
      }
    } else if (shape == BoxShape.circle) {
      // Calculate the radius and center of the circle
      final double radius = (rect.width / 2) - (width / 2);
      final Offset center = rect.center;

      // Apply the gradient to the paint
      paint.shader = gradient.createShader(rect);

      // Draw the circle border
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is GradientBoxBorder &&
        other.gradient == gradient &&
        other.width == width;
  }

  @override
  int get hashCode => Object.hash(gradient, width);

  @override
  ShapeBorder scale(double t) {
    // TODO: implement scale
    throw UnimplementedError();
  }
}
