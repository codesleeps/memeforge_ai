import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/achievement_badge_widget.dart';
import './widgets/edit_profile_modal_widget.dart';
import './widgets/meme_portfolio_grid_widget.dart';
import './widgets/user_profile_header_widget.dart';
import './widgets/user_stats_card_widget.dart';

class UserProfile extends StatefulWidget {
  final String? userId;

  const UserProfile({super.key, this.userId});

  @override
  State<UserProfile> createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  final _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  bool _isRefreshing = false;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic> _userStats = {};
  List<dynamic> _userMemes = [];
  List<dynamic> _achievements = [];
  bool _isFollowing = false;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  String get _targetUserId =>
      widget.userId ?? _supabaseService.currentUser?.id ?? '';

  Future<void> _loadUserProfile() async {
    if (_targetUserId.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final currentUserId = _supabaseService.currentUser?.id;
      _isOwnProfile = currentUserId == _targetUserId;

      final results = await Future.wait([
        _supabaseService.getUserProfile(_targetUserId),
        _supabaseService.getUserStats(_targetUserId),
        _supabaseService.getUserMemes(userId: _targetUserId, limit: 20),
        _supabaseService.getUserAchievements(_targetUserId),
        if (!_isOwnProfile && currentUserId != null)
          _supabaseService.isFollowing(currentUserId, _targetUserId)
        else
          Future.value(false),
      ]);

      setState(() {
        _userProfile = results[0] as Map<String, dynamic>?;
        _userStats = results[1] as Map<String, dynamic>;
        _userMemes = results[2] as List<dynamic>;
        _achievements = results[3] as List<dynamic>;

        // Add mock achievements if none exist
        if (_achievements.isEmpty) {
          _achievements = _getMockAchievements();
        }

        _isFollowing = results[4] as bool;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshProfile() async {
    setState(() => _isRefreshing = true);
    await _loadUserProfile();
    setState(() => _isRefreshing = false);
  }

  Future<void> _toggleFollow() async {
    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId == null || _isOwnProfile) return;

    setState(() => _isFollowing = !_isFollowing);

    final success = await _supabaseService.toggleFollow(
      currentUserId,
      _targetUserId,
    );

    if (success != _isFollowing) {
      setState(() => _isFollowing = success);
    }

    await _loadUserProfile();
  }

  void _showEditProfileModal() {
    if (!_isOwnProfile || _userProfile == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditProfileModalWidget(
        currentProfile: _userProfile!,
        onProfileUpdated: _refreshProfile,
      ),
    );
  }

  List<Map<String, dynamic>> _getMockAchievements() {
    final memesCount = _userStats['memes_count'] ?? 0;
    final aiCount = _userStats['ai_generations'] ?? 0;
    final likesCount = _userStats['likes_received'] ?? 0;

    return [
      {
        'achievement_name': 'First Meme',
        'achievement_type': 'first_meme',
        'achievement_description': 'Created your first meme',
        'is_unlocked': memesCount >= 1,
        'progress': memesCount >= 1 ? 1 : 0,
        'required_count': 1,
      },
      {
        'achievement_name': 'AI Master',
        'achievement_type': 'ai_master',
        'achievement_description': 'Generated 10 AI memes',
        'is_unlocked': aiCount >= 10,
        'progress': aiCount,
        'required_count': 10,
      },
      {
        'achievement_name': 'Viral Creator',
        'achievement_type': 'viral_creator',
        'achievement_description': 'Received 100 likes',
        'is_unlocked': likesCount >= 100,
        'progress': likesCount,
        'required_count': 100,
      },
      {
        'achievement_name': 'Prolific Creator',
        'achievement_type': 'prolific_creator',
        'achievement_description': 'Created 50 memes',
        'is_unlocked': memesCount >= 50,
        'progress': memesCount,
        'required_count': 50,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: CustomAppBar(
        title: 'Profile',
        showBackButton: widget.userId != null,
        actions: [
          if (_isOwnProfile)
            IconButton(
              icon: Icon(
                Icons.settings,
                color: AppTheme.textPrimaryDark,
                size: 20.sp,
              ),
              onPressed: _showEditProfileModal,
            ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryDark),
              ),
            )
          : RefreshIndicator(
              onRefresh: _refreshProfile,
              color: AppTheme.primaryDark,
              backgroundColor: AppTheme.cardDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserProfileHeaderWidget(
                      userProfile: _userProfile ?? {},
                      isOwnProfile: _isOwnProfile,
                      isFollowing: _isFollowing,
                      onFollowToggle: _toggleFollow,
                      onEditProfile: _showEditProfileModal,
                    ),
                    SizedBox(height: 2.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: UserStatsCardWidget(stats: _userStats),
                    ),
                    SizedBox(height: 3.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Achievements',
                        style: TextStyle(
                          color: AppTheme.textPrimaryDark,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _achievements.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4.w,
                              vertical: 2.h,
                            ),
                            child: Text(
                              'No achievements yet. Start creating memes!',
                              style: TextStyle(
                                color: AppTheme.textSecondaryDark,
                                fontSize: 12.sp,
                              ),
                            ),
                          )
                        : SizedBox(
                            height: 14.h,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: EdgeInsets.symmetric(horizontal: 4.w),
                              itemCount: _achievements.length,
                              itemBuilder: (context, index) {
                                return AchievementBadgeWidget(
                                  achievement: _achievements[index],
                                );
                              },
                            ),
                          ),
                    SizedBox(height: 3.h),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.w),
                      child: Text(
                        'Created Memes',
                        style: TextStyle(
                          color: AppTheme.textPrimaryDark,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    MemePortfolioGridWidget(memes: _userMemes),
                    SizedBox(height: 2.h),
                  ],
                ),
              ),
            ),
    );
  }
}
