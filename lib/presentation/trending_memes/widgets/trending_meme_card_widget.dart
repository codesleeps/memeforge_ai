import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_image_widget.dart';

/// Widget displaying a single trending meme with real-time engagement stats
class TrendingMemeCardWidget extends StatefulWidget {
  final dynamic meme;
  final VoidCallback onEngagementUpdate;

  const TrendingMemeCardWidget({
    super.key,
    required this.meme,
    required this.onEngagementUpdate,
  });

  @override
  State<TrendingMemeCardWidget> createState() => _TrendingMemeCardWidgetState();
}

class _TrendingMemeCardWidgetState extends State<TrendingMemeCardWidget> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  RealtimeChannel? _engagementChannel;

  late int _likeCount;
  late int _commentCount;
  late int _remixCount;
  bool _isLiked = false;
  bool _showComments = false;
  List<dynamic> _comments = [];
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _likeCount = widget.meme['like_count'] ?? 0;
    _commentCount = widget.meme['comment_count'] ?? 0;
    _remixCount = widget.meme['remix_count'] ?? 0;
    _checkIfLiked();
    _setupRealtimeEngagement();
  }

  @override
  void dispose() {
    if (_engagementChannel != null) {
      _supabaseService.unsubscribeChannel(_engagementChannel!);
    }
    _commentController.dispose();
    super.dispose();
  }

  void _setupRealtimeEngagement() {
    _engagementChannel = _supabaseService.subscribeMemeEngagement(
      memeId: widget.meme['id'],
      onLikeChange: (_) {
        if (mounted) {
          _updateEngagementCounts();
        }
      },
      onCommentChange: (_) {
        if (mounted) {
          _updateEngagementCounts();
          if (_showComments) _loadComments();
        }
      },
      onRemixChange: (_) {
        if (mounted) {
          _updateEngagementCounts();
        }
      },
    );
  }

  Future<void> _updateEngagementCounts() async {
    try {
      final response = await _supabaseService.client
          .from('memes')
          .select('like_count, comment_count, remix_count')
          .eq('id', widget.meme['id'])
          .single();

      if (mounted) {
        setState(() {
          _likeCount = response['like_count'] ?? 0;
          _commentCount = response['comment_count'] ?? 0;
          _remixCount = response['remix_count'] ?? 0;
        });
      }
    } catch (e) {
      debugPrint('Failed to update engagement counts: $e');
    }
  }

  Future<void> _checkIfLiked() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabaseService.client
          .from('meme_likes')
          .select()
          .eq('meme_id', widget.meme['id'])
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() => _isLiked = response != null);
      }
    } catch (e) {
      debugPrint('Failed to check like status: $e');
    }
  }

  Future<void> _toggleLike() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.toggleLike(
        userId: userId,
        memeId: widget.meme['id'],
      );

      setState(() => _isLiked = !_isLiked);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update like: $e')));
      }
    }
  }

  Future<void> _loadComments() async {
    try {
      final comments = await _supabaseService.getMemeComments(
        widget.meme['id'],
      );
      if (mounted) {
        setState(() => _comments = comments);
      }
    } catch (e) {
      debugPrint('Failed to load comments: $e');
    }
  }

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await _supabaseService.addComment(
        widget.meme['id'],
        _commentController.text.trim(),
      );
      _commentController.clear();
      await _loadComments();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to add comment: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meme header with user info
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage:
                      widget.meme['user_profiles']?['avatar_url'] != null
                      ? NetworkImage(widget.meme['user_profiles']['avatar_url'])
                      : null,
                  child: widget.meme['user_profiles']?['avatar_url'] == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.meme['user_profiles']?['username'] ??
                            'Unknown User',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.meme['title'] ?? '',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Meme image
          CustomImageWidget(
            imageUrl: widget.meme['image_url'] ?? '',
            height: 40.h,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          // Engagement stats and actions
          Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEngagementButton(
                      icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                      count: _likeCount,
                      color: _isLiked ? Colors.red : Colors.grey,
                      onTap: _toggleLike,
                    ),
                    _buildEngagementButton(
                      icon: Icons.comment_outlined,
                      count: _commentCount,
                      color: Colors.blue,
                      onTap: () {
                        setState(() => _showComments = !_showComments);
                        if (_showComments) _loadComments();
                      },
                    ),
                    _buildEngagementButton(
                      icon: Icons.repeat,
                      count: _remixCount,
                      color: Colors.green,
                      onTap: () {
                        // Navigate to remix creation
                      },
                    ),
                  ],
                ),

                // Comments section
                if (_showComments) ...[
                  SizedBox(height: 2.h),
                  _buildCommentsSection(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 1.w),
          Text(
            count.toString(),
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add comment input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 1.h,
                  ),
                ),
                maxLines: null,
              ),
            ),
            SizedBox(width: 2.w),
            IconButton(
              onPressed: _addComment,
              icon: const Icon(Icons.send, color: Colors.blue),
            ),
          ],
        ),

        SizedBox(height: 2.h),

        // Comments list
        if (_comments.isEmpty)
          Center(
            child: Text(
              'No comments yet',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _comments.length,
            itemBuilder: (context, index) {
              final comment = _comments[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      comment['user_profiles']?['avatar_url'] != null
                      ? NetworkImage(comment['user_profiles']['avatar_url'])
                      : null,
                  child: comment['user_profiles']?['avatar_url'] == null
                      ? const Icon(Icons.person, size: 16)
                      : null,
                ),
                title: Text(
                  comment['user_profiles']?['username'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  comment['content'] ?? '',
                  style: TextStyle(fontSize: 11.sp),
                ),
              );
            },
          ),
      ],
    );
  }
}