import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import './widgets/notification_item_widget.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _supabaseService = SupabaseService.instance;
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;
  RealtimeChannel? _notificationChannel;
  bool _showUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _subscribeToNotifications();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (_notificationChannel != null) {
      _supabaseService.unsubscribeChannel(_notificationChannel!);
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _subscribeToNotifications() {
    try {
      _notificationChannel = _supabaseService.subscribeUserNotifications(
        onNewNotification: (notification) {
          setState(() {
            _notifications.insert(0, notification);
          });
        },
      );
    } catch (e) {
      debugPrint('Failed to subscribe to notifications: $e');
    }
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      final newNotifications = await _supabaseService.getUserNotifications(
        limit: _limit,
        offset: _offset,
        unreadOnly: _showUnreadOnly,
      );

      setState(() {
        if (newNotifications.length < _limit) {
          _hasMore = false;
        }
        if (_offset == 0) {
          _notifications = newNotifications;
        } else {
          _notifications.addAll(newNotifications);
        }
        _offset += newNotifications.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Failed to load notifications: $e');
      setState(() {
        _isLoading = false;
        _hasMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadNotifications();
    }
  }

  Future<void> _refreshNotifications() async {
    setState(() {
      _offset = 0;
      _hasMore = true;
      _notifications.clear();
    });
    await _loadNotifications();
  }

  Future<void> _markAllAsRead() async {
    try {
      await _supabaseService.markAllNotificationsAsRead();
      setState(() {
        for (var notification in _notifications) {
          notification['is_read'] = true;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All notifications marked as read')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to mark as read: $e')));
      }
    }
  }

  void _toggleUnreadFilter() {
    setState(() {
      _showUnreadOnly = !_showUnreadOnly;
      _offset = 0;
      _hasMore = true;
      _notifications.clear();
    });
    _loadNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications
        .where((n) => !(n['is_read'] ?? true))
        .length;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceLight,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.onSurfaceLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifications',
              style: TextStyle(
                color: AppTheme.textPrimaryLight,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount unread',
                style: TextStyle(
                  color: AppTheme.textSecondaryLight,
                  fontSize: 12.sp,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showUnreadOnly ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: AppTheme.onSurfaceLight,
            ),
            onPressed: _toggleUnreadFilter,
          ),
          if (unreadCount > 0)
            IconButton(
              icon: Icon(Icons.done_all, color: AppTheme.onSurfaceLight),
              onPressed: _markAllAsRead,
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshNotifications,
        child: _notifications.isEmpty && !_isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80.0,
                      color: AppTheme.textSecondaryLight,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _showUnreadOnly
                          ? 'No unread notifications'
                          : 'No notifications yet',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(2.w),
                itemCount: _notifications.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _notifications.length) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(2.h),
                        child: const CircularProgressIndicator(),
                      ),
                    );
                  }

                  final notification = _notifications[index];
                  return NotificationItemWidget(
                    notification: notification,
                    onTap: () async {
                      if (!(notification['is_read'] ?? true)) {
                        try {
                          await _supabaseService.markNotificationAsRead(
                            notification['id'],
                          );
                          setState(() {
                            notification['is_read'] = true;
                          });
                        } catch (e) {
                          debugPrint('Failed to mark as read: $e');
                        }
                      }
                    },
                  );
                },
              ),
      ),
    );
  }
}
