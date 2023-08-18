import 'package:flutter/material.dart';

class WidgetHelpBounce extends StatefulWidget {
  const WidgetHelpBounce({required this.child, super.key});

  final Widget child;

  @override
  State<WidgetHelpBounce> createState() =>
      _WidgetHelpBounceState();
}

class _WidgetHelpBounceState extends State<WidgetHelpBounce>
    with SingleTickerProviderStateMixin {
      
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(
        milliseconds: 500
      ),
      vsync: this,
      value: 1,
      lowerBound: 0.85,
      upperBound: 1.0
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.bounceIn,

    );
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      alignment: Alignment.center,
      child: widget.child
    );
  }
}
