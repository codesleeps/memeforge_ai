import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class TopActionBarWidget extends StatelessWidget {
  final bool canUndo;
  final bool canRedo;
  final bool showTemplateOverlay;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onToggleTemplate;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onAIEnhance;

  const TopActionBarWidget({
    Key? key,
    required this.canUndo,
    required this.canRedo,
    required this.showTemplateOverlay,
    required this.onUndo,
    required this.onRedo,
    required this.onToggleTemplate,
    required this.onSave,
    required this.onShare,
    required this.onAIEnhance,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildActionButton(
            icon: 'undo',
            onTap: canUndo ? onUndo : null,
            theme: theme,
            tooltip: 'Undo',
          ),
          SizedBox(width: 2.w),
          _buildActionButton(
            icon: 'redo',
            onTap: canRedo ? onRedo : null,
            theme: theme,
            tooltip: 'Redo',
          ),
          SizedBox(width: 2.w),
          _buildActionButton(
            icon: 'grid_on',
            onTap: onToggleTemplate,
            theme: theme,
            tooltip: 'Template Grid',
            isActive: showTemplateOverlay,
          ),
          Spacer(),
          _buildActionButton(
            icon: 'auto_awesome',
            onTap: onAIEnhance,
            theme: theme,
            tooltip: 'AI Suggestions',
            color: theme.colorScheme.tertiary,
          ),
          SizedBox(width: 2.w),
          _buildActionButton(
            icon: 'save',
            onTap: onSave,
            theme: theme,
            tooltip: 'Save',
          ),
          SizedBox(width: 2.w),
          _buildActionButton(
            icon: 'share',
            onTap: onShare,
            theme: theme,
            tooltip: 'Share',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required VoidCallback? onTap,
    required ThemeData theme,
    required String tooltip,
    bool isActive = false,
    Color? color,
  }) {
    final isEnabled = onTap != null;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: isEnabled
            ? () {
                HapticFeedback.lightImpact();
                onTap();
              }
            : null,
        child: Container(
          padding: EdgeInsets.all(2.w),
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
          child: CustomIconWidget(
            iconName: icon,
            color: !isEnabled
                ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                : color ??
                      (isActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface),
            size: 20,
          ),
        ),
      ),
    );
  }
}
