import 'package:flutter/material.dart';

/// Lays out [left] and [right] side-by-side when there's room,
/// or stacked vertically when the width is tight.
class ResponsiveTwoUp extends StatelessWidget {
  final Widget left;
  final Widget right;

  /// Width at/above which we render a horizontal Row.
  final double breakpoint;

  /// Gap between children (both in Row and Column modes).
  final double gap;

  const ResponsiveTwoUp({
    super.key,
    required this.left,
    required this.right,
    this.breakpoint = 640, // tweak as you like
    this.gap = 12,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= breakpoint;
        if (wide) {
          return Row(
            children: [
              Expanded(child: left),
              SizedBox(width: gap),
              Expanded(child: right),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            left,
            SizedBox(height: gap),
            right,
          ],
        );
      },
    );
  }
}