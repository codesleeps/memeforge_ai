import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AchievementBadgeWidget extends StatelessWidget {
  final Map<String, dynamic> achievement;

  const AchievementBadgeWidget({super.key, required this.achievement});

  IconData _getAchievementIcon(String type) {
    switch (type) {
      case 'first_meme':
        return Icons.emoji_emotions;
      case 'viral_creator':
        return Icons.trending_up;
      case 'ai_master':
        return Icons.smart_toy;
      case 'social_butterfly':
        return Icons.people;
      case 'prolific_creator':
        return Icons.auto_awesome;
      default:
        return Icons.emoji_events;
    }
  }

  Color _getAchievementColor(String type) {
    switch (type) {
      case 'first_meme':
        return AppTheme.warningLight;
      case 'viral_creator':
        return AppTheme.secondaryLight;
      case 'ai_master':
        return AppTheme.primaryLight;
      case 'social_butterfly':
        return AppTheme.accentLight;
      case 'prolific_creator':
        return const Color(0xFFFF6B35);
      default:
        return AppTheme.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement['is_unlocked'] ?? false;
    final name = achievement['achievement_name'] ?? 'Achievement';
    final type = achievement['achievement_type'] ?? '';
    final progress = achievement['progress'] ?? 0;
    final required = achievement['required_count'] ?? 100;
    final icon = _getAchievementIcon(type);
    final color = _getAchievementColor(type);
    final progressPercent = required > 0
        ? (progress / required).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(color: color, width: 2.0),
            ),
            title: Row(
              children: [
                Icon(icon, color: color, size: 24.sp),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      color: AppTheme.textPrimaryDark,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement['achievement_description'] ?? '',
                  style: TextStyle(
                    color: AppTheme.textSecondaryDark,
                    fontSize: 12.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Progress: $progress / $required',
                  style: TextStyle(
                    color: AppTheme.textPrimaryDark,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 1.h),
                LinearProgressIndicator(
                  value: progressPercent,
                  backgroundColor: AppTheme.backgroundDark,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Close',
                  style: TextStyle(color: color, fontSize: 13.sp),
                ),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 28.w,
        margin: EdgeInsets.only(right: 3.w),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          gradient: isUnlocked
              ? LinearGradient(
                  colors: [color.withAlpha(51), color.withAlpha(13)],
                )
              : null,
          color: isUnlocked ? null : AppTheme.cardDark.withAlpha(128),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isUnlocked
                ? color
                : AppTheme.textSecondaryDark.withAlpha(77),
            width: 2.0,
          ),
          boxShadow: isUnlocked
              ? [
                  BoxShadow(
                    color: color.withAlpha(77),
                    blurRadius: 15.0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isUnlocked
                  ? color
                  : AppTheme.textSecondaryDark.withAlpha(128),
              size: 28.sp,
            ),
            SizedBox(height: 0.5.h),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isUnlocked
                      ? AppTheme.textPrimaryDark
                      : AppTheme.textSecondaryDark.withAlpha(128),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isUnlocked) ...[
              SizedBox(height: 0.3.h),
              Text(
                '${(progressPercent * 100).toInt()}%',
                style: TextStyle(
                  color: AppTheme.textSecondaryDark.withAlpha(128),
                  fontSize: 9.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
