import 'package:flutter/material.dart';

class Letreiro extends StatefulWidget {
  final String texto;
  final double blankSpace;
  final int timeStoped;
  final int fullTime;
  final double? fontSize;

  const Letreiro({
    super.key,
    required this.texto,
    required this.blankSpace,
    required this.timeStoped,
    required this.fullTime,
    this.fontSize = 16,
  });

  @override
  State<Letreiro> createState() => _LetreiroState();
}

class _LetreiroState extends State<Letreiro> {
  late final ScrollController _scrollController;
  late GlobalKey _textKey;
  bool _isScrolling = false;
  double _targetScrollOffset = 0;
  bool _centralizar = false;

  @override
  void initState() {
    super.initState();
    _textKey = GlobalKey();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndScroll());
  }

  Future<void> _measureAndScroll() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? textBox =
          _textKey.currentContext?.findRenderObject() as RenderBox?;
      if (textBox != null && mounted) {
        final double textWidth = textBox.size.width;

        _targetScrollOffset = textWidth + widget.blankSpace;

        if (textWidth <= _scrollController.position.maxScrollExtent) {
          if (_centralizar) {
            setState(() {
              _centralizar = false;
            });
          }
          _startScroll();
        } else {
          if (!_centralizar) {
            setState(() {
              _centralizar = true;
            });
          }
        }
      }
    });
  }

  void _startScroll() async {
    if (_isScrolling) return;
    _isScrolling = true;

    while (mounted) {
      await _scrollController.animateTo(
        _targetScrollOffset,
        duration: Duration(seconds: widget.fullTime),
        curve: Curves.linear,
      );
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
      await Future.delayed(Duration(milliseconds: widget.timeStoped));
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double measureTextHeight(String text, double fontSize) {
    final textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return textPainter.size.height;
  }

  @override
  Widget build(BuildContext context) {
    final altura = measureTextHeight(widget.texto, widget.fontSize ?? 16) + 2;

    if (_centralizar) {
      return Center(
        child: Text(widget.texto, style: TextStyle(fontSize: widget.fontSize)),
      );
    }

    return SizedBox(
      height: altura,
      child: ListView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Text(
            widget.texto,
            key: _textKey,
            style: TextStyle(fontSize: widget.fontSize),
          ),
          SizedBox(width: widget.blankSpace),
          Text(widget.texto, style: TextStyle(fontSize: widget.fontSize)),
        ],
      ),
    );
  }
}
