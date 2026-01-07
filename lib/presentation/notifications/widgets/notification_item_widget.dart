import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/app_export.dart';

class NotificationItemWidget extends StatelessWidget {
  final Map<String, dynamic> notification;
  final VoidCallback onTap;

  const NotificationItemWidget({
    super.key,
    required this.notification,
    required this.onTap,
  });

  String _getNotificationIcon() {
    final type = notification['notification_type'] ?? '';
    switch (type) {
      case 'like':
        return '❤️';
      case 'comment':
        return '💬';
      case 'remix':
        return '🎨';
      default:
        return '🔔';
    }
  }

  Color _getNotificationColor() {
    final type = notification['notification_type'] ?? '';
    switch (type) {
      case 'like':
        return Colors.red.shade50;
      case 'comment':
        return Colors.blue.shade50;
      case 'remix':
        return Colors.purple.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = notification['actor'] ?? {};
    final meme = notification['meme'] ?? {};
    final actorName = actor['full_name'] ?? actor['username'] ?? 'Someone';
    final actorAvatar = actor['avatar_url'] ?? '';
    final memeTitle = meme['title'] ?? 'your meme';
    final memeThumbnail = meme['thumbnail_url'] ?? meme['image_url'] ?? '';
    final content = notification['content'] ?? '';
    final isRead = notification['is_read'] ?? false;
    final createdAt = notification['created_at'];

    String timeAgo = 'Just now';
    if (createdAt != null) {
      try {
        final dateTime = DateTime.parse(createdAt);
        timeAgo = timeago.format(dateTime, locale: 'en_short');
      } catch (e) {
        debugPrint('Error parsing date: $e');
      }
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 1.h),
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : _getNotificationColor(),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isRead ? Colors.grey.shade200 : Colors.grey.shade300,
            width: 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24.0,
                  backgroundColor: Colors.grey.shade300,
                  child: actorAvatar.isNotEmpty
                      ? ClipOval(
                          child: CustomImageWidget(
                            imageUrl: actorAvatar,
                            height: 48.0,
                            width: 48.0,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 28.0,
                          color: Colors.grey.shade600,
                        ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.0),
                    ),
                    child: Text(
                      _getNotificationIcon(),
                      style: const TextStyle(fontSize: 14.0),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppTheme.textPrimaryDark,
                      ),
                      children: [
                        TextSpan(
                          text: actorName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' $content'),
                      ],
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 2.w),
            if (memeThumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: CustomImageWidget(
                  imageUrl: memeThumbnail,
                  height: 50.0,
                  width: 50.0,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
