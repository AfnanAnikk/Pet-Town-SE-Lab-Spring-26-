import 'package:flutter/material.dart';

class PulsingImage extends StatefulWidget {
  final ImageProvider image;
  final double width;
  final double height;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final Duration duration;
  final Duration delay;
  final double rotation;

  const PulsingImage({
    super.key,
    required this.image,
    required this.width,
    required this.height,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.duration,
    required this.delay,
    this.rotation = 0.0,
  });

  @override
  State<PulsingImage> createState() => _PulsingImageState();
}

class _PulsingImageState extends State<PulsingImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutSine,
      ),
    );

    _startAnimation();
  }

  void _startAnimation() async {
    await Future.delayed(widget.delay);
    if (mounted) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: widget.rotation,
            child: child,
          ),
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          image: DecorationImage(
            image: widget.image,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );

    if (widget.top != null ||
        widget.left != null ||
        widget.right != null ||
        widget.bottom != null) {
      return Positioned(
        top: widget.top,
        left: widget.left,
        right: widget.right,
        bottom: widget.bottom,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}
