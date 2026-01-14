import 'dart:async';
import 'package:flutter/material.dart';

class StreamedText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final int typingSpeed;

  const StreamedText({
    super.key,
    required this.text,
    this.style,
    this.typingSpeed = 50,
  });

  @override
  State<StreamedText> createState() => _StreamedTextState();
}

class _StreamedTextState extends State<StreamedText> {
  String _displayText = '';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant StreamedText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _timer?.cancel();
      _displayText = '';
      _startTyping();
    }
  }

  void _startTyping() {
    if (widget.text.isEmpty) return;

    int currentIndex = 0;
    _timer = Timer.periodic(Duration(milliseconds: widget.typingSpeed), (
      timer,
    ) {
      if (currentIndex < widget.text.length) {
        setState(() {
          _displayText = widget.text.substring(0, currentIndex + 1);
        });
        currentIndex++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(_displayText, style: widget.style);
  }
}
