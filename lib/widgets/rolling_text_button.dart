import 'dart:async';
import 'package:flutter/material.dart';

class RollingTextButton extends StatefulWidget {
  final List<String> texts;
  final VoidCallback onPressed;

  const RollingTextButton({
    super.key,
    required this.texts,
    required this.onPressed,
  });

  @override
  State<RollingTextButton> createState() => _RollingTextButtonState();
}

class _RollingTextButtonState extends State<RollingTextButton> {
  int _currentIndex = 0;
  Timer? _timer;

  // Colors to cycle through for the last word
  final List<Color> _highlightColors = [
    const Color(0xFF047200), // Green
    const Color(0xFFFF0004), // Red
    const Color(0xFF550089), // Purple
    const Color(0xFF65C8FF), // Blue
    const Color.fromARGB(255, 20, 1, 234), // Brandish
    const Color.fromARGB(255, 255, 255, 255), // White
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.texts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildRichText(String text, Color highlightColor) {
    List<String> words = text.split(' ');
    if (words.isEmpty) return const SizedBox.shrink();
    if (words.length == 1) {
      return Text(
        text,
        style: TextStyle(
          color: highlightColor,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    String startText = words.sublist(0, words.length - 1).join(' ');
    String endText;
    if(text == "Get Your Next Vet Visit"){
      startText = words.sublist(0, words.length - 2).join(' ');
      endText = words.sublist(words.length - 2).join(' ');
    }
    else{
      endText = words.last;
    }

    return RichText(
      key: ValueKey<String>(text),
      text: TextSpan(
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'Outfit',
        ),
        children: [
          TextSpan(
            text: '$startText ',
            style: const TextStyle(color: Colors.white),
          ),
          TextSpan(
            text: endText,
            style: TextStyle(color: highlightColor),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (Widget child, Animation<double> animation) {
            final inAnimation = Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: const Offset(0.0, 0.0),
            ).animate(animation);
            final outAnimation = Tween<Offset>(
              begin: const Offset(0.0, -1.0),
              end: const Offset(0.0, 0.0),
            ).animate(animation);

            if (child.key == ValueKey<String>(widget.texts[_currentIndex])) {
              return ClipRect(
                child: SlideTransition(
                  position: inAnimation,
                  child: child,
                ),
              );
            } else {
              return ClipRect(
                child: SlideTransition(
                  position: outAnimation,
                  child: child,
                ),
              );
            }
          },
          child: _buildRichText(
            widget.texts[_currentIndex],
            _highlightColors[_currentIndex % _highlightColors.length],
          ),
        ),
      ),
    );
  }
}
