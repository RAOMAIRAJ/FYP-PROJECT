import 'package:flutter/material.dart';

class HoverButton extends StatefulWidget {
  final Widget? child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final HitTestBehavior? behavior;
  final GestureDragUpdateCallback? onPanUpdate;
  final GestureLongPressStartCallback? onLongPressStart;
  final GestureLongPressEndCallback? onLongPressEnd;

  const HoverButton({
    super.key,
    this.child,
    this.onTap,
    this.onLongPress,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.behavior,
    this.onPanUpdate,
    this.onLongPressStart,
    this.onLongPressEnd,
  });

  @override
  State<HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<HoverButton> {
  bool _isHovering = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.onLongPress == null && widget.onPanUpdate == null && widget.onLongPressStart == null) {
      return GestureDetector(
        behavior: widget.behavior,
        child: widget.child,
      );
    }
    
    return MouseRegion(
      cursor: (widget.onTap != null || widget.onLongPress != null) ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) { if (mounted) setState(() => _isHovering = true); },
      onExit: (_) { if (mounted) setState(() => _isHovering = false); },
      child: Listener(
        onPointerDown: (_) {
          if (mounted) setState(() => _isPressed = true);
        },
        onPointerUp: (_) {
          if (mounted) setState(() => _isPressed = false);
        },
        onPointerCancel: (_) {
          if (mounted) setState(() => _isPressed = false);
        },
        child: GestureDetector(
          behavior: widget.behavior ?? HitTestBehavior.opaque,
          onTapDown: widget.onTapDown,
          onTapUp: widget.onTapUp,
          onTapCancel: widget.onTapCancel,
          onTap: () {
            debugPrint('🔘 HoverButton: onTap triggered');
            if (widget.onTap != null) widget.onTap!();
          },
          onLongPress: () {
            debugPrint('🔘 HoverButton: onLongPress triggered');
            if (widget.onLongPress != null) widget.onLongPress!();
          },
          onPanUpdate: widget.onPanUpdate,
          onLongPressStart: widget.onLongPressStart,
          onLongPressEnd: widget.onLongPressEnd,
          child: AnimatedScale(
            scale: _isPressed ? 0.95 : (_isHovering ? 1.02 : 1.0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

