import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../routes/app_routes.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// Custom app bar widget for the AI Meme Generator app.
/// Implements cyberpunk minimalism design with clean spatial relationships.
///
/// Supports multiple variants for different screen contexts.
enum CustomAppBarVariant {
  /// Standard app bar with title and optional actions
  standard,

  /// App bar with back button for navigation
  withBack,

  /// App bar with search functionality
  withSearch,

  /// Transparent app bar for overlay contexts
  transparent,
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool showNotificationBadge;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.actions,
    this.showNotificationBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final supabaseService = SupabaseService.instance;

    return AppBar(
      backgroundColor: AppTheme.surfaceLight,
      elevation: 0.0,
      leading: showBackButton
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.primaryLight),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: AppTheme.textPrimaryLight,
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        if (showNotificationBadge && supabaseService.isAuthenticated)
          FutureBuilder<int>(
            future: supabaseService.getUnreadNotificationCount(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;

              return Stack(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.primaryLight,
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.notificationsScreen,
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8.0,
                      top: 8.0,
                      child: Container(
                        padding: const EdgeInsets.all(4.0),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18.0,
                          minHeight: 18.0,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}