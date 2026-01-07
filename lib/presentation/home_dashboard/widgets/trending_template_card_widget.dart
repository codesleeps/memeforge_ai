import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';

class TrendingTemplateCardWidget extends StatefulWidget {
  final Map<String, dynamic> templateData;

  const TrendingTemplateCardWidget({Key? key, required this.templateData})
    : super(key: key);

  @override
  State<TrendingTemplateCardWidget> createState() =>
      _TrendingTemplateCardWidgetState();
}

class _TrendingTemplateCardWidgetState
    extends State<TrendingTemplateCardWidget> {
  bool _isLiked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkLikeStatus();
  }

  Future<void> _checkLikeStatus() async {
    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser == null) return;

    final isLiked = await SupabaseService.instance.isMemeLiked(
      userId: currentUser.id,
      memeId: widget.templateData['id'],
    );
    if (mounted) {
      setState(() => _isLiked = isLiked);
    }
  }

  Future<void> _handleLike(ThemeData theme) async {
    if (_isLoading) return;

    final currentUser = SupabaseService.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please log in to like memes'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isLoading = true);

    try {
      await SupabaseService.instance.toggleLike(
        userId: currentUser.id,
        memeId: widget.templateData['id'],
      );
      if (mounted) {
        setState(() {
          _isLiked = !_isLiked;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to like: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleUseTemplate(BuildContext context) {
    HapticFeedback.lightImpact();
    Navigator.of(context, rootNavigator: true).pushNamed(
      AppRoutes.imageUploadEdit,
      arguments: widget.templateData['id'],
    );
  }

  Future<void> _handleShare(BuildContext context) async {
    HapticFeedback.lightImpact();
    try {
      final String memeUrl =
          widget.templateData['image_url'] ??
          widget.templateData['thumbnail'] ??
          '';
      final String memeTitle =
          widget.templateData['title'] ?? 'Check out this trending meme!';

      if (memeUrl.isNotEmpty) {
        await Share.share('$memeTitle\n\n$memeUrl', subject: memeTitle);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleViewDetails(BuildContext context, ThemeData theme) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 12.w,
                  height: 0.5.h,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: 3.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomImageWidget(
                  imageUrl: widget.templateData['thumbnail'] as String,
                  width: double.infinity,
                  height: 50.h,
                  fit: BoxFit.cover,
                  semanticLabel: widget.templateData['semanticLabel'] as String,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                widget.templateData['title'] as String,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                widget.templateData['uses'] as String,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 3.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _handleUseTemplate(context);
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 6.h),
                      ),
                      child: Text('Use Template'),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleShare(context);
                    },
                    icon: CustomIconWidget(
                      iconName: 'share',
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary.withValues(
                        alpha: 0.1,
                      ),
                      minimumSize: Size(6.h, 6.h),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _handleViewDetails(context, theme),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child: CustomImageWidget(
                      imageUrl: widget.templateData['thumbnail'] as String,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                      semanticLabel:
                          widget.templateData['semanticLabel'] as String,
                    ),
                  ),
                  Positioned(
                    top: 2.w,
                    right: 2.w,
                    child: _isLoading
                        ? Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                          )
                        : IconButton(
                            onPressed: () => _handleLike(theme),
                            icon: CustomIconWidget(
                              iconName: _isLiked
                                  ? 'favorite'
                                  : 'favorite_border',
                              color: _isLiked ? Colors.red : Colors.white,
                              size: 20,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black.withValues(
                                alpha: 0.5,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.templateData['title'] as String,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    widget.templateData['uses'] as String,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
