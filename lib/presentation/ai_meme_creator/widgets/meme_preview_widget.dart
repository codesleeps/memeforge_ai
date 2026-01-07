import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Widget for displaying generated meme previews with action buttons
/// Includes save, share, regenerate, and edit functionality
class MemePreviewWidget extends StatelessWidget {
  final String memeUrl;
  final String semanticLabel;
  final DateTime timestamp;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onRegenerate;
  final VoidCallback onEdit;

  const MemePreviewWidget({
    Key? key,
    required this.memeUrl,
    required this.semanticLabel,
    required this.timestamp,
    required this.onSave,
    required this.onShare,
    required this.onRegenerate,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: 50.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.primary, width: 2),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showFullScreenPreview(context);
                },
                child: CustomImageWidget(
                  imageUrl: memeUrl,
                  width: double.infinity,
                  height: 50.h,
                  fit: BoxFit.cover,
                  semanticLabel: semanticLabel,
                ),
              ),
            ),
          ),
          SizedBox(height: 1.5.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context: context,
                icon: 'save_alt',
                label: 'Save',
                onTap: onSave,
                theme: theme,
              ),
              _buildActionButton(
                context: context,
                icon: 'share',
                label: 'Share',
                onTap: onShare,
                theme: theme,
              ),
              _buildActionButton(
                context: context,
                icon: 'refresh',
                label: 'Regenerate',
                onTap: onRegenerate,
                theme: theme,
              ),
              _buildActionButton(
                context: context,
                icon: 'edit',
                label: 'Edit',
                onTap: onEdit,
                theme: theme,
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            _formatTimestamp(timestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenPreview(BuildContext context) {
    final theme = Theme.of(context);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: CustomIconWidget(
                iconName: 'close',
                color: Colors.white,
                size: 24,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
            actions: [
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'download',
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onSave();
                },
              ),
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'share',
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  onShare();
                },
              ),
            ],
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: CustomImageWidget(
                imageUrl: memeUrl,
                width: 100.w,
                height: 100.h,
                fit: BoxFit.contain,
                semanticLabel: semanticLabel,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Generated just now';
    } else if (difference.inMinutes < 60) {
      return 'Generated ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Generated ${difference.inHours}h ago';
    } else {
      return 'Generated on ${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }
}
