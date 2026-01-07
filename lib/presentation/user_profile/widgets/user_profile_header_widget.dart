import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class UserProfileHeaderWidget extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final bool isOwnProfile;
  final bool isFollowing;
  final VoidCallback onFollowToggle;
  final VoidCallback onEditProfile;

  const UserProfileHeaderWidget({
    super.key,
    required this.userProfile,
    required this.isOwnProfile,
    required this.isFollowing,
    required this.onFollowToggle,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final avatarUrl = userProfile['avatar_url'] as String? ?? '';
    final username = userProfile['username'] as String? ?? 'Anonymous';
    final fullName = userProfile['full_name'] as String? ?? 'User';
    final bio = userProfile['bio'] as String? ?? '';

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.cardDark, AppTheme.backgroundDark],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withAlpha(26),
            blurRadius: 20.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 28.w,
                height: 28.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryDark, AppTheme.secondaryDark],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDark.withAlpha(128),
                      blurRadius: 20.0,
                      spreadRadius: 2.0,
                    ),
                  ],
                ),
              ),
              Container(
                width: 26.w,
                height: 26.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardDark,
                ),
                child: ClipOval(
                  child: avatarUrl.isNotEmpty
                      ? CustomImageWidget(
                          imageUrl: avatarUrl,
                          fit: BoxFit.cover,
                        )
                      : Icon(
                          Icons.person,
                          size: 15.w,
                          color: AppTheme.textSecondaryDark,
                        ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            fullName,
            style: TextStyle(
              color: AppTheme.textPrimaryDark,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            '@$username',
            style: TextStyle(
              color: AppTheme.primaryDark,
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (bio.isNotEmpty) ...[
            SizedBox(height: 1.5.h),
            Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondaryDark,
                fontSize: 12.sp,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          SizedBox(height: 2.h),
          if (!isOwnProfile)
            ElevatedButton(
              onPressed: onFollowToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: isFollowing
                    ? AppTheme.cardDark
                    : AppTheme.primaryDark,
                foregroundColor: isFollowing
                    ? AppTheme.primaryDark
                    : AppTheme.backgroundDark,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  side: BorderSide(color: AppTheme.primaryDark, width: 2.0),
                ),
              ),
              child: Text(
                isFollowing ? 'Following' : 'Follow',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: onEditProfile,
              icon: Icon(Icons.edit, size: 16.sp),
              label: Text(
                'Edit Profile',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: AppTheme.backgroundDark,
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}