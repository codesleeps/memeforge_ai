import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class TextEditorWidget extends StatefulWidget {
  final dynamic data;
  final bool isSelected;
  final VoidCallback onTap;
  final Function(dynamic) onUpdate;

  const TextEditorWidget({
    Key? key,
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.onUpdate,
  }) : super(key: key);

  @override
  State<TextEditorWidget> createState() => _TextEditorWidgetState();
}

class _TextEditorWidgetState extends State<TextEditorWidget> {
  late Offset _position;
  late double _rotation;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _position = widget.data.position;
    _rotation = widget.data.rotation;
  }

  @override
  void didUpdateWidget(TextEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data.position != widget.data.position) {
      _position = widget.data.position;
    }
    if (oldWidget.data.rotation != widget.data.rotation) {
      _rotation = widget.data.rotation;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: (details) {
          if (widget.isSelected) {
            setState(() {
              _position = Offset(
                _position.dx + details.delta.dx,
                _position.dy + details.delta.dy,
              );
            });
          }
        },
        onPanEnd: (details) {
          if (widget.isSelected) {
            widget.onUpdate(widget.data.copyWith(position: _position));
          }
        },
        onScaleStart: (details) {
          _scale = 1.0;
        },
        onScaleUpdate: (details) {
          if (widget.isSelected && details.pointerCount == 2) {
            setState(() {
              _scale = details.scale;
              _rotation = details.rotation;
            });
          }
        },
        onScaleEnd: (details) {
          if (widget.isSelected) {
            final newFontSize = widget.data.fontSize * _scale;
            widget.onUpdate(
              widget.data.copyWith(
                fontSize: newFontSize.clamp(10.sp, 30.sp),
                rotation: _rotation,
              ),
            );
            _scale = 1.0;
          }
        },
        child: Transform.rotate(
          angle: _rotation,
          child: Transform.scale(
            scale: _scale,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
              decoration: widget.isSelected
                  ? BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    )
                  : null,
              child: Stack(
                children: [
                  if (widget.data.hasOutline)
                    Text(
                      widget.data.text,
                      style: TextStyle(
                        fontSize: widget.data.fontSize,
                        fontWeight: widget.data.fontWeight,
                        foreground: Paint()
                          ..style = PaintingStyle.stroke
                          ..strokeWidth = 3
                          ..color = Colors.black,
                      ),
                    ),
                  if (widget.data.hasShadow)
                    Text(
                      widget.data.text,
                      style: TextStyle(
                        fontSize: widget.data.fontSize,
                        fontWeight: widget.data.fontWeight,
                        color: widget.data.color,
                        shadows: [
                          Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Colors.black.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
                    ),
                  if (widget.data.hasGlow)
                    Text(
                      widget.data.text,
                      style: TextStyle(
                        fontSize: widget.data.fontSize,
                        fontWeight: widget.data.fontWeight,
                        color: widget.data.color,
                        shadows: [
                          Shadow(
                            blurRadius: 12,
                            color: widget.data.color.withValues(alpha: 0.8),
                          ),
                          Shadow(
                            blurRadius: 24,
                            color: widget.data.color.withValues(alpha: 0.4),
                          ),
                        ],
                      ),
                    ),
                  if (!widget.data.hasShadow && !widget.data.hasGlow)
                    Text(
                      widget.data.text,
                      style: TextStyle(
                        fontSize: widget.data.fontSize,
                        fontWeight: widget.data.fontWeight,
                        color: widget.data.color,
                      ),
                    ),
                  if (widget.isSelected) ...[
                    Positioned(
                      right: -2.w,
                      top: -2.w,
                      child: Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: CustomIconWidget(
                          iconName: 'open_with',
                          color: theme.colorScheme.onPrimary,
                          size: 12,
                        ),
                      ),
                    ),
                    Positioned(
                      right: -2.w,
                      bottom: -2.w,
                      child: Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.secondary.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: CustomIconWidget(
                          iconName: 'rotate_right',
                          color: theme.colorScheme.onSecondary,
                          size: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}