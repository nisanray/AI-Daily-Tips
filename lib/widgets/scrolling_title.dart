import 'package:flutter/cupertino.dart';

/// A widget that creates a scrolling text effect in the navigation bar
/// Perfect for long titles that don't fit in the available space
class ScrollingTitle extends StatefulWidget {
  /// The text to display and scroll
  final String text;

  /// Text style to apply to the scrolling text
  final TextStyle? style;

  /// Speed of the scrolling animation (higher = faster)
  final double scrollSpeed;

  /// Whether to pause scrolling when text fits in available space
  final bool pauseWhenFits;

  const ScrollingTitle({
    super.key,
    required this.text,
    this.style,
    this.scrollSpeed = 50.0, // pixels per second
    this.pauseWhenFits = true,
  });

  @override
  State<ScrollingTitle> createState() => _ScrollingTitleState();
}

class _ScrollingTitleState extends State<ScrollingTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scrollAnimation;
  final GlobalKey _textKey = GlobalKey();
  double _textWidth = 0;
  double _containerWidth = 0;
  bool _needsScrolling = false;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller for continuous scrolling
    _animationController = AnimationController(
      duration:
          const Duration(seconds: 10), // Will be adjusted based on text length
      vsync: this,
    );

    // Create scrolling animation that goes from 0 to full text width
    _scrollAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear, // Linear for smooth continuous scrolling
    ));

    // Measure text after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureText();
    });
  }

  @override
  void didUpdateWidget(ScrollingTitle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-measure if text changed
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureText();
      });
    }
  }

  /// Measures the text width and container width to determine if scrolling is needed
  void _measureText() {
    final RenderBox? textRenderBox =
        _textKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? containerRenderBox =
        context.findRenderObject() as RenderBox?;

    if (textRenderBox != null && containerRenderBox != null) {
      setState(() {
        _textWidth = textRenderBox.size.width;
        _containerWidth = containerRenderBox.size.width;
        _needsScrolling = _textWidth > _containerWidth;
      });

      if (_needsScrolling && !widget.pauseWhenFits) {
        _startScrolling();
      } else if (_needsScrolling) {
        // Add delay before starting scroll for better UX
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _needsScrolling) {
            _startScrolling();
          }
        });
      }
    }
  }

  /// Starts the scrolling animation with calculated duration based on text length
  void _startScrolling() {
    if (!_needsScrolling) return;

    // Calculate duration based on text width and scroll speed
    final scrollDistance = _textWidth + _containerWidth;
    final duration = Duration(
      milliseconds: (scrollDistance / widget.scrollSpeed * 1000).round(),
    );

    _animationController.duration = duration;
    _animationController.repeat(); // Repeat indefinitely for continuous scroll
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Default style matching CupertinoNavigationBar
    final defaultStyle = CupertinoTheme.of(context).textTheme.navTitleTextStyle;
    final effectiveStyle = widget.style ?? defaultStyle;

    return LayoutBuilder(
      builder: (context, constraints) {
        _containerWidth = constraints.maxWidth;

        return SizedBox(
          width: constraints.maxWidth,
          child: ClipRect(
            child: _needsScrolling
                ? AnimatedBuilder(
                    animation: _scrollAnimation,
                    builder: (context, child) {
                      // Calculate horizontal offset for scrolling effect
                      final scrollOffset = (_textWidth + _containerWidth) *
                          _scrollAnimation.value;
                      return Transform.translate(
                        offset: Offset(_containerWidth - scrollOffset, 0),
                        child: Text(
                          widget.text,
                          key: _textKey,
                          style: effectiveStyle,
                          overflow: TextOverflow.visible,
                          maxLines: 1,
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      widget.text,
                      key: _textKey,
                      style: effectiveStyle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
