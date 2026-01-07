import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class QuickStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const QuickStatsWidget({Key? key, this.stats = const {}}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final memesCreated = stats['memes_count'] ?? 0;
    final totalShares = stats['likes_received'] ?? 0;
    final aiGenerations = stats['ai_generations'] ?? 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatCard(
            theme: theme,
            icon: 'collections',
            label: 'Created',
            value: _formatNumber(memesCreated),
            color: theme.colorScheme.primary,
          ),
          _buildStatCard(
            theme: theme,
            icon: 'favorite',
            label: 'Likes',
            value: _formatNumber(totalShares),
            color: theme.colorScheme.secondary,
          ),
          _buildStatCard(
            theme: theme,
            icon: 'auto_awesome',
            label: 'AI Gen',
            value: _formatNumber(aiGenerations),
            color: const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required ThemeData theme,
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 1.5.w),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.15),
              color.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
              ),
              child: CustomIconWidget(iconName: icon, color: color, size: 24),
            ),
            SizedBox(height: 1.h),
            TweenAnimationBuilder<int>(
              tween: IntTween(
                begin: 0,
                end: int.tryParse(value.replaceAll(RegExp(r'[^\d]'), '')) ?? 0,
              ),
              duration: const Duration(milliseconds: 1500),
              builder: (context, animatedValue, child) {
                return Text(
                  _formatNumber(animatedValue),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                );
              },
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
