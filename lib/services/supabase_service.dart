import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://snfzxeapcchyzergbxar.supabase.co',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNuZnp4ZWFwY2NoeXplcmdieGFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc3MjIyMjgsImV4cCI6MjA4MzI5ODIyOH0.48t7-txc-txayMLorKQ3CLpjCtLpD1NXCP6RWGhjaLA',
  );

  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be defined using --dart-define.',
      );
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }

  SupabaseClient get client => Supabase.instance.client;
  SupabaseClient get _client => client;

  // Authentication Methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
    String? username,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName ?? email.split('@')[0],
          'username': username ?? email.split('@')[0],
        },
      );
      return response;
    } catch (error) {
      throw Exception('Sign-up failed: $error');
    }
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (error) {
      throw Exception('Sign-in failed: $error');
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (error) {
      throw Exception('Sign-out failed: $error');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } catch (error) {
      throw Exception('Password reset failed: $error');
    }
  }

  User? get currentUser => client.auth.currentUser;

  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // User Profile Methods
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select('*')
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // Get memes count
      final memesData = await _client
          .from('memes')
          .select('id')
          .eq('user_id', userId)
          .count();

      // Get total likes received across all user's memes
      final likesData = await _client
          .from('meme_likes')
          .select('id')
          .inFilter(
            'meme_id',
            await _client
                .from('memes')
                .select('id')
                .eq('user_id', userId)
                .then((memes) => (memes as List).map((m) => m['id']).toList()),
          )
          .count();

      // Get followers count
      final followersData = await _client
          .from('user_follows')
          .select('id')
          .eq('following_id', userId)
          .count();

      // Get AI generations count
      final aiGenerationsData = await _client
          .from('memes')
          .select('id')
          .eq('user_id', userId)
          .eq('ai_generated', true)
          .count();

      return {
        'memes_count': memesData.count ?? 0,
        'likes_received': likesData.count ?? 0,
        'followers_count': followersData.count ?? 0,
        'ai_generations': aiGenerationsData.count ?? 0,
      };
    } catch (e) {
      debugPrint('Error fetching user stats: $e');
      return {
        'memes_count': 0,
        'likes_received': 0,
        'followers_count': 0,
        'ai_generations': 0,
      };
    }
  }

  Future<List<dynamic>> getUserMemesWithDetails(
    String userId, {
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from('memes')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(limit);
      return response;
    } catch (e) {
      debugPrint('Error fetching user memes: $e');
      return [];
    }
  }

  Future<List<dynamic>> getUserAchievements(String userId) async {
    try {
      final response = await _client
          .from('user_achievements')
          .select('*')
          .eq('user_id', userId)
          .order('is_unlocked', ascending: false)
          .order('created_at', ascending: true);
      return response;
    } catch (e) {
      debugPrint('Error fetching user achievements: $e');
      return [];
    }
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    try {
      final response = await _client
          .from('user_follows')
          .select('id')
          .eq('follower_id', followerId)
          .eq('following_id', followingId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      debugPrint('Error checking follow status: $e');
      return false;
    }
  }

  Future<bool> toggleFollow(String followerId, String followingId) async {
    try {
      final isCurrentlyFollowing = await isFollowing(followerId, followingId);

      if (isCurrentlyFollowing) {
        await _client
            .from('user_follows')
            .delete()
            .eq('follower_id', followerId)
            .eq('following_id', followingId);
        return false;
      } else {
        await _client.from('user_follows').insert({
          'follower_id': followerId,
          'following_id': followingId,
        });
        return true;
      }
    } catch (e) {
      debugPrint('Error toggling follow: $e');
      return false;
    }
  }

  Future<bool> updateUserProfile({
    required String userId,
    String? fullName,
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (fullName != null) updateData['full_name'] = fullName;
      if (username != null) updateData['username'] = username;
      if (bio != null) updateData['bio'] = bio;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      if (updateData.isEmpty) return false;

      await _client.from('user_profiles').update(updateData).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  // Meme Storage Methods
  Future<List<Map<String, dynamic>>> getUserMemes({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await client
          .from('memes')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Get user memes failed: $error');
    }
  }

  Future<Map<String, dynamic>> createMeme({
    required String userId,
    required String title,
    required String imageUrl,
    String? description,
    required String visibility,
    int fileSize = 0,
    bool aiGenerated = false,
    String? aiPrompt,
    String? topText,
    String? bottomText,
  }) async {
    try {
      final response = await _client
          .from('memes')
          .insert({
            'user_id': userId,
            'title': title,
            'image_url': imageUrl,
            'description': description,
            'visibility': visibility,
            'ai_generated': aiGenerated,
            'ai_prompt': aiPrompt,
            'top_text': topText,
            'bottom_text': bottomText,
            'file_size': fileSize,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create meme: ${e.toString()}');
    }
  }

  /// Upload meme image to Supabase Storage
  /// Returns the public URL of the uploaded image
  Future<String?> uploadMemeImage({
    required Uint8List bytes,
    required String fileName,
    required String userId,
  }) async {
    try {
      // Create bucket path: memes/{userId}/{fileName}
      final path = 'memes/$userId/$fileName';

      // Upload to Supabase Storage
      await _client.storage
          .from('memes')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final publicUrl = _client.storage.from('memes').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload meme image error: $e');
      return null;
    }
  }

  /// Upload profile avatar to Supabase Storage
  /// Returns the public URL of the uploaded avatar
  Future<String?> uploadProfileAvatar({
    required Uint8List bytes,
    required String userId,
  }) async {
    try {
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // Use memes bucket with avatars subfolder since avatars bucket doesn't exist yet
      final path = 'avatars/$userId/$fileName';

      // Upload to Supabase Storage (using memes bucket)
      await _client.storage
          .from('memes')
          .uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      // Get public URL
      final publicUrl = _client.storage.from('memes').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Upload avatar error: $e');
      return null;
    }
  }

  Future<void> deleteMeme(String memeId) async {
    try {
      await client.from('memes').delete().eq('id', memeId);
    } catch (error) {
      throw Exception('Delete meme failed: $error');
    }
  }

  Future<void> updateMeme({
    required String memeId,
    String? title,
    String? description,
    List<String>? tags,
    String? visibility,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (tags != null) updates['tags'] = tags;
      if (visibility != null) updates['visibility'] = visibility;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await client.from('memes').update(updates).eq('id', memeId);
    } catch (error) {
      throw Exception('Update meme failed: $error');
    }
  }

  // Likes Methods
  Future<void> toggleLike({
    required String userId,
    required String memeId,
  }) async {
    try {
      final existing = await client
          .from('meme_likes')
          .select()
          .eq('user_id', userId)
          .eq('meme_id', memeId)
          .maybeSingle();

      if (existing != null) {
        await client
            .from('meme_likes')
            .delete()
            .eq('user_id', userId)
            .eq('meme_id', memeId);
      } else {
        await client.from('meme_likes').insert({
          'user_id': userId,
          'meme_id': memeId,
        });
      }
    } catch (error) {
      throw Exception('Toggle like failed: $error');
    }
  }

  Future<bool> isMemeLiked({
    required String userId,
    required String memeId,
  }) async {
    try {
      final response = await client
          .from('meme_likes')
          .select()
          .eq('user_id', userId)
          .eq('meme_id', memeId)
          .maybeSingle();
      return response != null;
    } catch (error) {
      return false;
    }
  }

  // Collections Methods
  Future<List<Map<String, dynamic>>> getUserCollections(String userId) async {
    try {
      final response = await client
          .from('collections')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Get user collections failed: $error');
    }
  }

  Future<Map<String, dynamic>> createCollection({
    required String userId,
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    try {
      final response = await client
          .from('collections')
          .insert({
            'user_id': userId,
            'name': name,
            'description': description,
            'is_public': isPublic,
          })
          .select()
          .single();
      return response;
    } catch (error) {
      throw Exception('Create collection failed: $error');
    }
  }

  Future<void> addMemeToCollection({
    required String collectionId,
    required String memeId,
  }) async {
    try {
      await client.from('collection_items').insert({
        'collection_id': collectionId,
        'meme_id': memeId,
      });
    } catch (error) {
      throw Exception('Add meme to collection failed: $error');
    }
  }

  Future<void> removeMemeFromCollection({
    required String collectionId,
    required String memeId,
  }) async {
    try {
      await client
          .from('collection_items')
          .delete()
          .eq('collection_id', collectionId)
          .eq('meme_id', memeId);
    } catch (error) {
      throw Exception('Remove meme from collection failed: $error');
    }
  }

  // Public feed for trending memes
  Future<List<Map<String, dynamic>>> getPublicMemes({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await client
          .from('memes')
          .select('*, user_profiles!inner(username, avatar_url)')
          .eq('visibility', 'public')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Get public memes failed: $error');
    }
  }

  // Search memes by tags
  Future<List<Map<String, dynamic>>> searchMemes({
    required List<String> tags,
    int limit = 50,
  }) async {
    try {
      final response = await client
          .from('memes')
          .select('*, user_profiles!inner(username, avatar_url)')
          .eq('visibility', 'public')
          .contains('tags', tags)
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Search memes failed: $error');
    }
  }

  // ==================== COMMENTS OPERATIONS ====================

  /// Add a comment to a meme
  Future<Map<String, dynamic>> addComment(String memeId, String content) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await client
          .from('meme_comments')
          .insert({'meme_id': memeId, 'user_id': user.id, 'content': content})
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to add comment: $e');
    }
  }

  /// Get comments for a meme with user details
  Future<List<dynamic>> getMemeComments(String memeId) async {
    try {
      final response = await client
          .from('meme_comments')
          .select('*, user_profiles(*)')
          .eq('meme_id', memeId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to fetch comments: $e');
    }
  }

  /// Delete a comment
  Future<void> deleteComment(String commentId) async {
    try {
      await client.from('meme_comments').delete().eq('id', commentId);
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }

  // ==================== REMIX OPERATIONS ====================

  /// Create a remix relationship between two memes
  Future<Map<String, dynamic>> createRemix(
    String originalMemeId,
    String remixedMemeId,
  ) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await client
          .from('meme_remixes')
          .insert({
            'original_meme_id': originalMemeId,
            'remixed_meme_id': remixedMemeId,
            'user_id': user.id,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create remix: $e');
    }
  }

  /// Get all remixes of a specific meme
  Future<List<dynamic>> getMemeRemixes(String originalMemeId) async {
    try {
      final response = await client
          .from('meme_remixes')
          .select('*, remixed_meme:memes!remixed_meme_id(*)')
          .eq('original_meme_id', originalMemeId)
          .order('created_at', ascending: false);

      return response;
    } catch (e) {
      throw Exception('Failed to fetch remixes: $e');
    }
  }

  // ==================== REAL-TIME SUBSCRIPTIONS ====================

  /// Subscribe to real-time changes for a specific meme's engagement
  RealtimeChannel subscribeMemeEngagement({
    required String memeId,
    required Function(Map<String, dynamic>) onLikeChange,
    required Function(Map<String, dynamic>) onCommentChange,
    required Function(Map<String, dynamic>) onRemixChange,
  }) {
    final channel = client.channel('meme_engagement_$memeId');

    // Subscribe to likes changes
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'meme_likes',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'meme_id',
        value: memeId,
      ),
      callback: (payload) => onLikeChange(payload.newRecord),
    );

    // Subscribe to comments changes
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'meme_comments',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'meme_id',
        value: memeId,
      ),
      callback: (payload) => onCommentChange(payload.newRecord),
    );

    // Subscribe to remixes changes
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'meme_remixes',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'original_meme_id',
        value: memeId,
      ),
      callback: (payload) => onRemixChange(payload.newRecord),
    );

    channel.subscribe();
    return channel;
  }

  /// Subscribe to trending memes list changes
  RealtimeChannel subscribeTrendingMemes({required Function() onMemesUpdate}) {
    final channel = client.channel('trending_memes');

    // Subscribe to changes in memes table
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'memes',
      callback: (_) => onMemesUpdate(),
    );

    // Subscribe to changes in likes that affect trending status
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'meme_likes',
      callback: (_) => onMemesUpdate(),
    );

    // Subscribe to changes in comments
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'meme_comments',
      callback: (_) => onMemesUpdate(),
    );

    // Subscribe to changes in remixes
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'meme_remixes',
      callback: (_) => onMemesUpdate(),
    );

    channel.subscribe();
    return channel;
  }

  // ==================== NOTIFICATIONS ====================

  /// Get user notifications with actor and meme details
  Future<List<Map<String, dynamic>>> getUserNotifications({
    int limit = 50,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      PostgrestFilterBuilder query = client
          .from('user_notifications')
          .select('''
            *,
            actor:user_profiles!actor_id(id, username, full_name, avatar_url),
            meme:memes!meme_id(id, title, image_url, thumbnail_url)
          ''')
          .eq('user_id', user.id);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Get notifications failed: $error');
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await client
          .from('user_notifications')
          .update({
            'is_read': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', notificationId);
    } catch (error) {
      throw Exception('Mark notification as read failed: $error');
    }
  }

  /// Mark all user notifications as read
  Future<void> markAllNotificationsAsRead() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      await client
          .from('user_notifications')
          .update({
            'is_read': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id)
          .eq('is_read', false);
    } catch (error) {
      throw Exception('Mark all notifications as read failed: $error');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    try {
      final user = currentUser;
      if (user == null) return 0;

      final response = await client
          .from('user_notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', false)
          .count();

      return response.count;
    } catch (error) {
      return 0;
    }
  }

  /// Subscribe to user notifications in real-time
  RealtimeChannel subscribeUserNotifications({
    required Function(Map<String, dynamic>) onNewNotification,
  }) {
    final user = currentUser;
    if (user == null) throw Exception('User not authenticated');

    final channel = client.channel('user_notifications_${user.id}');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'user_notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: user.id,
      ),
      callback: (payload) => onNewNotification(payload.newRecord),
    );

    channel.subscribe();
    return channel;
  }

  /// Unsubscribe from a channel
  Future<void> unsubscribeChannel(RealtimeChannel channel) async {
    await client.removeChannel(channel);
  }
}
