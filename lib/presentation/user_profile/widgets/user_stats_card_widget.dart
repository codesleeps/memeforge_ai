import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class UserStatsCardWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const UserStatsCardWidget({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final memesCount = stats['memes_count'] ?? 0;
    final likesReceived = stats['likes_received'] ?? 0;
    final followersCount = stats['followers_count'] ?? 0;
    final aiGenerations = stats['ai_generations'] ?? 0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.cardDark, AppTheme.backgroundDark],
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withAlpha(26),
            blurRadius: 15.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stats',
            style: TextStyle(
              color: AppTheme.textPrimaryDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.image,
                  label: 'Memes',
                  value: memesCount.toString(),
                  color: AppTheme.accentDark,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _StatItem(
                  icon: Icons.favorite,
                  label: 'Likes',
                  value: likesReceived.toString(),
                  color: AppTheme.secondaryDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.people,
                  label: 'Followers',
                  value: followersCount.toString(),
                  color: AppTheme.primaryDark,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _StatItem(
                  icon: Icons.auto_awesome,
                  label: 'AI Memes',
                  value: aiGenerations.toString(),
                  color: AppTheme.warningDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(77), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withAlpha(51),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryDark,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}