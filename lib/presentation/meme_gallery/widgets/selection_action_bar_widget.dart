import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Action bar for bulk operations in selection mode
class SelectionActionBarWidget extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onSelectAll;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onExport;
  final VoidCallback onCancel;

  const SelectionActionBarWidget({
    Key? key,
    required this.selectedCount,
    required this.onSelectAll,
    required this.onDelete,
    required this.onShare,
    required this.onExport,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'close',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              onCancel();
            },
          ),
          const SizedBox(width: 8),
          Text(
            '$selectedCount selected',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              onSelectAll();
            },
            child: const Text('Select All'),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'share',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: selectedCount > 0
                ? () {
                    HapticFeedback.lightImpact();
                    onShare();
                  }
                : null,
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'download',
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            onPressed: selectedCount > 0
                ? () {
                    HapticFeedback.lightImpact();
                    onExport();
                  }
                : null,
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'delete',
              color: theme.colorScheme.error,
              size: 24,
            ),
            onPressed: selectedCount > 0
                ? () {
                    HapticFeedback.mediumImpact();
                    onDelete();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
