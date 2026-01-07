import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/trending_meme_card_widget.dart';

class TrendingMemesScreen extends StatefulWidget {
  const TrendingMemesScreen({Key? key}) : super(key: key);

  @override
  State<TrendingMemesScreen> createState() => _TrendingMemesScreenState();
}

class _TrendingMemesScreenState extends State<TrendingMemesScreen> {
  final _supabaseService = SupabaseService.instance;
  final _scrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _error;

  List<Map<String, dynamic>> _trendingMemes = [];
  RealtimeChannel? _realtimeChannel;

  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadTrendingMemes();
    _setupRealtimeSubscription();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _cleanupRealtimeSubscription();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) {
        _loadMoreMemes();
      }
    }
  }

  void _setupRealtimeSubscription() {
    _realtimeChannel = _supabaseService.subscribeTrendingMemes(
      onMemesUpdate: () {
        if (mounted) {
          _loadTrendingMemes();
        }
      },
    );
  }

  Future<void> _cleanupRealtimeSubscription() async {
    if (_realtimeChannel != null) {
      await _supabaseService.unsubscribeChannel(_realtimeChannel!);
    }
  }

  Future<void> _loadTrendingMemes() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
        _currentPage = 0;
      });

      final memes = await _supabaseService.getPublicMemes(
        limit: _pageSize,
        offset: 0,
      );

      // Sort by engagement (likes + comments + remixes)
      memes.sort((a, b) {
        final aScore =
            (a['like_count'] ?? 0) +
            (a['comment_count'] ?? 0) +
            (a['remix_count'] ?? 0);
        final bScore =
            (b['like_count'] ?? 0) +
            (b['comment_count'] ?? 0) +
            (b['remix_count'] ?? 0);
        return bScore.compareTo(aScore);
      });

      setState(() {
        _trendingMemes = memes;
        _hasMore = memes.length == _pageSize;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load trending memes: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreMemes() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final moreMemes = await _supabaseService.getPublicMemes(
        limit: _pageSize,
        offset: nextPage * _pageSize,
      );

      setState(() {
        _trendingMemes.addAll(moreMemes);
        _currentPage = nextPage;
        _hasMore = moreMemes.length == _pageSize;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _handleLike(String memeId) async {
    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) return;

    try {
      await _supabaseService.toggleLike(userId: currentUser.id, memeId: memeId);

      // Update local state
      setState(() {
        final index = _trendingMemes.indexWhere((m) => m['id'] == memeId);
        if (index != -1) {
          final currentLikes = _trendingMemes[index]['like_count'] ?? 0;
          _trendingMemes[index]['like_count'] = currentLikes + 1;
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to like: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const CustomAppBar(title: 'Trending Memes'),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            SizedBox(height: 2.h),
            Text(
              _error!,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _loadTrendingMemes,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_trendingMemes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 80, color: theme.colorScheme.primary),
            SizedBox(height: 3.h),
            Text(
              'No Trending Memes Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Be the first to create viral content!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTrendingMemes,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.all(4.w),
        itemCount: _trendingMemes.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: 2.h),
        itemBuilder: (context, index) {
          if (index == _trendingMemes.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final meme = _trendingMemes[index];
          return TrendingMemeCardWidget(
            meme: meme,
            onEngagementUpdate: _loadTrendingMemes,
          );
        },
      ),
    );
  }
}