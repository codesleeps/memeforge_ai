import 'package:flutter/material.dart';
import '../presentation/home_dashboard/home_dashboard.dart';
import '../presentation/meme_gallery/meme_gallery.dart';
import '../presentation/ai_meme_creator/ai_meme_creator.dart';
import '../presentation/image_upload_edit/image_upload_edit.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/signup_screen.dart';
import '../presentation/auth/forgot_password_screen.dart';
import '../presentation/trending_memes/trending_memes_screen.dart';
import '../presentation/notifications/notifications_screen.dart';
import '../presentation/user_profile/user_profile.dart';

class AppRoutes {
  static const String root = '/';
  static const String homeDashboard = '/home_dashboard';
  static const String memeGallery = '/meme_gallery';
  static const String aiMemeCreator = '/ai_meme_creator';
  static const String imageUploadEdit = '/image_upload_edit';
  static const String trendingMemes = '/trending_memes';
  static const String loginScreen = '/login';
  static const String signupScreen = '/signup';
  static const String forgotPasswordScreen = '/forgot_password';
  static const String notificationsScreen = '/notifications';
  static const String userProfile = '/user-profile';

  static Map<String, WidgetBuilder> get routes {
    return {
      root: (context) => const LoginScreen(),
      homeDashboard: (context) => const HomeDashboard(),
      memeGallery: (context) => const MemeGallery(),
      aiMemeCreator: (context) => const AiMemeCreator(),
      imageUploadEdit: (context) => const ImageUploadEdit(),
      trendingMemes: (context) => const TrendingMemesScreen(),
      loginScreen: (context) => const LoginScreen(),
      signupScreen: (context) => const SignUpScreen(),
      forgotPasswordScreen: (context) => const ForgotPasswordScreen(),
      notificationsScreen: (context) => const NotificationsScreen(),
      userProfile: (context) => const UserProfile(),
    };
  }
}
