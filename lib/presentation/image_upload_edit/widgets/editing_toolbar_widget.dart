import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EditingToolbarWidget extends StatefulWidget {
  final VoidCallback onAddText;
  final VoidCallback onTogglePreview;
  final int? selectedOverlayIndex;
  final VoidCallback? onDeleteOverlay;

  const EditingToolbarWidget({
    Key? key,
    required this.onAddText,
    required this.onTogglePreview,
    this.selectedOverlayIndex,
    this.onDeleteOverlay,
  }) : super(key: key);

  @override
  State<EditingToolbarWidget> createState() => _EditingToolbarWidgetState();
}

class _EditingToolbarWidgetState extends State<EditingToolbarWidget> {
  final TextEditingController _textController = TextEditingController();
  bool _showTextEditor = false;
  bool _showColorPicker = false;
  bool _showFontPicker = false;

  final List<Color> _neonColors = [
    Colors.white,
    Color(0xFF00D4FF),
    Color(0xFFFF0080),
    Color(0xFF39FF14),
    Color(0xFFFFB800),
    Color(0xFFFF3366),
    Colors.yellow,
    Colors.cyan,
  ];

  final List<FontWeight> _fontWeights = [
    FontWeight.w400,
    FontWeight.w500,
    FontWeight.w600,
    FontWeight.w700,
    FontWeight.w900,
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(EditingToolbarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showTextEditor) _buildTextEditor(theme),
            if (_showColorPicker) _buildColorPicker(theme),
            if (_showFontPicker) _buildFontPicker(theme),
            _buildMainToolbar(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildMainToolbar(ThemeData theme) {
    final hasSelection = widget.selectedOverlayIndex != null;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          _buildToolButton(
            icon: 'add_circle_outline',
            label: 'Add Text',
            onTap: widget.onAddText,
            theme: theme,
          ),
          if (hasSelection) ...[
            SizedBox(width: 2.w),
            _buildToolButton(
              icon: 'edit',
              label: 'Edit',
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _showTextEditor = !_showTextEditor);
              },
              theme: theme,
              isActive: _showTextEditor,
            ),
            SizedBox(width: 2.w),
            _buildToolButton(
              icon: 'palette',
              label: 'Color',
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _showColorPicker = !_showColorPicker;
                  _showFontPicker = false;
                  _showTextEditor = false;
                });
              },
              theme: theme,
              isActive: _showColorPicker,
            ),
            SizedBox(width: 2.w),
            _buildToolButton(
              icon: 'format_size',
              label: 'Font',
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _showFontPicker = !_showFontPicker;
                  _showColorPicker = false;
                  _showTextEditor = false;
                });
              },
              theme: theme,
              isActive: _showFontPicker,
            ),
            SizedBox(width: 2.w),
            _buildToolButton(
              icon: 'delete_outline',
              label: 'Delete',
              onTap: widget.onDeleteOverlay,
              theme: theme,
              color: theme.colorScheme.error,
            ),
          ],
          Spacer(),
          _buildToolButton(
            icon: 'visibility',
            label: 'Preview',
            onTap: widget.onTogglePreview,
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton({
    required String icon,
    required String label,
    required VoidCallback? onTap,
    required ThemeData theme,
    bool isActive = false,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color:
                  color ??
                  (isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface),
              size: 20,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color:
                    color ??
                    (isActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextEditor(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Edit Text', style: theme.textTheme.titleMedium),
              Spacer(),
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _showTextEditor = false);
                },
              ),
            ],
          ),
          SizedBox(height: 2.h),
          TextField(
            controller: _textController,
            decoration: InputDecoration(
              hintText: 'Enter text...',
              suffixIcon: IconButton(
                icon: CustomIconWidget(
                  iconName: 'check',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _showTextEditor = false);
                },
              ),
            ),
            maxLines: 3,
            onSubmitted: (value) {
              setState(() => _showTextEditor = false);
            },
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              _buildStyleToggle(
                icon: 'format_bold',
                label: 'Outline',
                isActive: false,
                onTap: () {},
                theme: theme,
              ),
              SizedBox(width: 2.w),
              _buildStyleToggle(
                icon: 'shadow',
                label: 'Shadow',
                isActive: false,
                onTap: () {},
                theme: theme,
              ),
              SizedBox(width: 2.w),
              _buildStyleToggle(
                icon: 'wb_sunny',
                label: 'Glow',
                isActive: false,
                onTap: () {},
                theme: theme,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStyleToggle({
    required String icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              CustomIconWidget(
                iconName: icon,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface,
                size: 20,
              ),
              SizedBox(height: 0.5.h),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Text Color', style: theme.textTheme.titleMedium),
              Spacer(),
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _showColorPicker = false);
                },
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Wrap(
            spacing: 3.w,
            runSpacing: 2.h,
            children: _neonColors.map((color) {
              final isSelected = false;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFontPicker(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Font Weight', style: theme.textTheme.titleMedium),
              Spacer(),
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
                onPressed: () {
                  setState(() => _showFontPicker = false);
                },
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _fontWeights.map((weight) {
              final isSelected = false;
              final label = weight == FontWeight.w400
                  ? 'Regular'
                  : weight == FontWeight.w500
                  ? 'Medium'
                  : weight == FontWeight.w600
                  ? 'SemiBold'
                  : weight == FontWeight.w700
                  ? 'Bold'
                  : 'Black';

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 1.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary.withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: weight,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}