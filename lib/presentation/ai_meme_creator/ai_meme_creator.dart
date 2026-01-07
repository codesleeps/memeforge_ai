import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/gemini_service.dart';
import '../../services/supabase_service.dart';
import '../../services/unsplash_service.dart';
import './widgets/chat_message_widget.dart';
import './widgets/input_area_widget.dart';
import './widgets/meme_preview_widget.dart';

/// AI Meme Creator screen with conversational interface for intelligent meme generation
/// Implements cyberpunk minimalism design with neon-accented chat interface
class AiMemeCreator extends StatefulWidget {
  const AiMemeCreator({Key? key}) : super(key: key);

  @override
  State<AiMemeCreator> createState() => _AiMemeCreatorState();
}

class _AiMemeCreatorState extends State<AiMemeCreator>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  final GeminiService _geminiService = GeminiService();
  final _supabaseService = SupabaseService.instance;
  final _unsplashService = UnsplashService();

  bool _isGenerating = false;
  bool _showScrollButton = false;
  late bool _isAiOnline;
  bool _isSaving = false;

  // Mock conversation data
  final List<Map<String, dynamic>> _messages = [
    {
      "id": 1,
      "type": "ai",
      "content":
          "Hey there! I'm your AI meme assistant powered by Gemini. Tell me what kind of meme you'd like to create, and I'll make it happen! 🎨",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 5)),
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _isAiOnline = _geminiService.isInitialized;

    // Show initialization error if present
    if (!_geminiService.isInitialized &&
        _geminiService.initializationError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showConfigurationError();
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.hasClients) {
      final showButton = _scrollController.offset > 200;
      if (showButton != _showScrollButton) {
        setState(() => _showScrollButton = showButton);
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showConfigurationError() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('AI Configuration Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _geminiService.initializationError ??
                  'AI service is not configured',
            ),
            const SizedBox(height: 16),
            const Text(
              'To use AI meme generation:\n'
              '1. Get a Gemini API key from Google AI Studio\n'
              '2. Configure it in your environment settings\n'
              '3. Restart the app',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context, rootNavigator: true).pop();
            },
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continue Anyway'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isGenerating) return;

    // Check if Gemini is initialized
    if (!_geminiService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _geminiService.initializationError ?? 'AI service is not available',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          action: SnackBarAction(
            label: 'Info',
            textColor: Colors.white,
            onPressed: _showConfigurationError,
          ),
        ),
      );
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _messages.add({
        "id": _messages.length + 1,
        "type": "user",
        "content": message,
        "timestamp": DateTime.now(),
      });
      _messageController.clear();
      _isGenerating = true;
    });

    _scrollToBottom();

    try {
      // Generate AI response using Gemini
      final aiResponse = await _geminiService.generateChatResponse(message);

      if (mounted) {
        setState(() {
          _messages.add({
            "id": _messages.length + 1,
            "type": "ai",
            "content": aiResponse,
            "timestamp": DateTime.now(),
          });
        });

        _scrollToBottom();

        // Add a "generating" status message
        setState(() {
          _messages.add({
            "id": _messages.length + 1,
            "type": "ai",
            "content": "🎨 Creating your meme concept...",
            "timestamp": DateTime.now(),
          });
        });

        _scrollToBottom();

        // Generate meme concept
        final memeResult = await _geminiService.generateMemeIdea(message);

        if (mounted) {
          // Remove the "generating" message
          setState(() {
            _messages.removeLast();
          });

          // Add concept explanation
          String conceptText = "✨ **Meme Concept**: ${memeResult.concept}\n\n";
          if (memeResult.topText.isNotEmpty) {
            conceptText += "📝 Top text: ${memeResult.topText}\n";
          }
          if (memeResult.bottomText.isNotEmpty) {
            conceptText += "📝 Bottom text: ${memeResult.bottomText}\n";
          }
          conceptText += "\n🔍 Finding the perfect image...";

          setState(() {
            _messages.add({
              "id": _messages.length + 1,
              "type": "ai",
              "content": conceptText,
              "timestamp": DateTime.now(),
            });
          });

          _scrollToBottom();

          // Generate meme image with better search terms
          await Future.delayed(const Duration(milliseconds: 1500));

          if (mounted) {
            // Use search terms for better image matching
            final memeUrl = await _getMemeImageUrl(memeResult.searchTerms);

            setState(() {
              _messages.add({
                "id": _messages.length + 1,
                "type": "meme",
                "content":
                    "Your meme is ready! ${memeResult.topText.isNotEmpty || memeResult.bottomText.isNotEmpty ? 'Tap to add text overlay.' : ''}",
                "memeUrl": memeUrl,
                "memeData": {
                  "topText": memeResult.topText,
                  "bottomText": memeResult.bottomText,
                  "concept": memeResult.concept,
                },
                "semanticLabel": memeResult.imagePrompt,
                "timestamp": DateTime.now(),
              });
              _isGenerating = false;
            });

            _scrollToBottom();
            HapticFeedback.mediumImpact();
          }
        }
      }
    } on GeminiException catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            "id": _messages.length + 1,
            "type": "ai",
            "content":
                "⚠️ ${e.message}\n\nTry rephrasing your request or describe a different meme idea!",
            "timestamp": DateTime.now(),
          });
          _isGenerating = false;
        });

        _scrollToBottom();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Meme generation issue: ${e.message}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            "id": _messages.length + 1,
            "type": "ai",
            "content":
                "😅 Oops! Something went wrong on my end. Let's try a different meme idea!\n\nTip: Try being more specific about what kind of meme you want.",
            "timestamp": DateTime.now(),
          });
          _isGenerating = false;
        });

        _scrollToBottom();
      }
    }
  }

  Future<String> _getMemeImageUrl(String searchTerms) async {
    // Try to fetch from Unsplash API first
    try {
      final imageUrl = await _unsplashService.searchPhoto(searchTerms);
      if (imageUrl != null) {
        return imageUrl;
      }
    } catch (e) {
      print('Unsplash API error: $e');
    }

    // Fallback to curated images if API fails
    final Map<String, String> categoryToImage = {
      'cat':
          'https://images.unsplash.com/photo-1574158622682-e40e69881006?w=800',
      'dog':
          'https://images.unsplash.com/photo-1583511655857-d19b40a7a54e?w=800',
      'coffee':
          'https://images.unsplash.com/photo-1509042239860-f550ce710b93?w=800',
      'work':
          'https://images.unsplash.com/photo-1497215728101-856f4ea42174?w=800',
      'office':
          'https://images.unsplash.com/photo-1497366216548-37526070297c?w=800',
      'monday':
          'https://images.unsplash.com/photo-1517849845537-4d257902454a?w=800',
      'tired':
          'https://images.unsplash.com/photo-1611162616475-46b635cb6868?w=800',
      'sleep':
          'https://images.unsplash.com/photo-1541781774459-bb2af2f05b55?w=800',
      'food':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800',
      'pizza':
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800',
      'coding':
          'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=800',
      'programmer':
          'https://images.unsplash.com/photo-1484417894907-623942c8ee29?w=800',
      'computer':
          'https://images.unsplash.com/photo-1587614382346-4ec70e388b28?w=800',
      'funny':
          'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?w=800',
      'love':
          'https://images.unsplash.com/photo-1518199266791-5375a83190b7?w=800',
      'friend':
          'https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800',
      'party':
          'https://images.unsplash.com/photo-1530103862676-de8c9debad1d?w=800',
      'workout':
          'https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=800',
      'gym':
          'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800',
      'study':
          'https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?w=800',
      'student':
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800',
      'phone':
          'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=800',
      'social':
          'https://images.unsplash.com/photo-1611162617213-7d7a39e9b1d7?w=800',
      'stress':
          'https://images.unsplash.com/photo-1566125882500-87e10f726cdc?w=800',
      'happy':
          'https://images.unsplash.com/photo-1554080353-a576cf803bda?w=800',
      'sad':
          'https://images.unsplash.com/photo-1516302752625-fcc3c50ae61f?w=800',
      'angry':
          'https://images.unsplash.com/photo-1551817958-11e0f7bbea7a?w=800',
      'success':
          'https://images.unsplash.com/photo-1519834785169-98be25ec3f84?w=800',
      'fail':
          'https://images.unsplash.com/photo-1620207418302-439b387441b0?w=800',
      'money':
          'https://images.unsplash.com/photo-1579621970563-ebec7560ff3e?w=800',
    };

    // Clean search terms
    final cleanTerms = searchTerms.toLowerCase().trim();

    // Try to match specific categories
    for (var entry in categoryToImage.entries) {
      if (cleanTerms.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default fallback to a generic funny/relatable image
    return 'https://images.unsplash.com/photo-1518791841217-8f162f1e1131?w=800';
  }

  void _handleVoiceInput() {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Voice input feature coming soon!',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSettings() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsSheet(),
    );
  }

  Widget _buildSettingsSheet() {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: theme.colorScheme.primary, width: 1),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generation Settings',
                    style: theme.textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  _buildSettingItem(
                    'Style',
                    'Cyberpunk',
                    Icons.palette_outlined,
                    theme,
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    'Quality',
                    'High',
                    Icons.high_quality_outlined,
                    theme,
                  ),
                  const SizedBox(height: 16),
                  _buildSettingItem(
                    'Format',
                    'Square (1:1)',
                    Icons.crop_square_outlined,
                    theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: CustomIconWidget(
            iconName: icon.codePoint.toRadixString(16),
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(value, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        CustomIconWidget(
          iconName: 'chevron_right',
          color: theme.colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ],
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveMeme(String imageUrl, Map<String, dynamic> memeData) async {
    if (_isSaving) return;

    final currentUser = _supabaseService.currentUser;
    if (currentUser == null) {
      _showSnackBar('Please log in to save memes');
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Extract meme data
      final topText = memeData['topText'] as String? ?? '';
      final bottomText = memeData['bottomText'] as String? ?? '';
      final concept = memeData['concept'] as String? ?? 'AI Generated Meme';

      // Create title from concept or text
      String title = concept;
      if (title.isEmpty && (topText.isNotEmpty || bottomText.isNotEmpty)) {
        title = [topText, bottomText].where((s) => s.isNotEmpty).join(' - ');
      }
      if (title.isEmpty) {
        title =
            'AI Generated Meme ${DateTime.now().toString().substring(0, 10)}';
      }

      // Create description from original prompt
      final lastUserMessage =
          _messages.lastWhere(
                (m) => m['type'] == 'user',
                orElse: () => {'content': ''},
              )['content']
              as String;

      String description = 'AI-generated meme';
      if (lastUserMessage.isNotEmpty) {
        description = 'Generated from: $lastUserMessage';
      }

      await _supabaseService.createMeme(
        userId: currentUser.id,
        title: title.length > 100 ? '${title.substring(0, 97)}...' : title,
        imageUrl: imageUrl,
        description: description,
        visibility: 'private',
        aiGenerated: true,
        aiPrompt: lastUserMessage,
        topText: topText,
        bottomText: bottomText,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                CustomIconWidget(
                  iconName: 'check_circle',
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text('Meme saved to your gallery!'),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushNamed(AppRoutes.memeGallery);
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Failed to save meme: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareMeme(
    String imageUrl,
    Map<String, dynamic> memeData,
  ) async {
    try {
      HapticFeedback.lightImpact();

      // Show dialog with share options
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => _buildShareSheet(imageUrl, memeData),
      );
    } catch (e) {
      _showSnackBar('Failed to share meme: ${e.toString()}');
    }
  }

  Widget _buildShareSheet(String imageUrl, Map<String, dynamic> memeData) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: theme.colorScheme.primary, width: 1),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Share Meme', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  _buildShareOption('Copy Link', Icons.link, () {
                    Clipboard.setData(ClipboardData(text: imageUrl));
                    Navigator.pop(context);
                    _showSnackBar('Link copied to clipboard!');
                  }, theme),
                  const SizedBox(height: 16),
                  _buildShareOption('Download Image', Icons.download, () {
                    Navigator.pop(context);
                    _showSnackBar('Download feature coming soon!');
                  }, theme),
                  const SizedBox(height: 16),
                  _buildShareOption('Share to Social Media', Icons.share, () {
                    Navigator.pop(context);
                    _showSnackBar('Social sharing coming soon!');
                  }, theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareOption(
    String label,
    IconData icon,
    VoidCallback onTap,
    ThemeData theme,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outline, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CustomIconWidget(
                iconName: icon.codePoint.toRadixString(16),
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Text(label, style: theme.textTheme.bodyLarge),
            const Spacer(),
            CustomIconWidget(
              iconName: 'chevron_right',
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back_ios_new',
                color: theme.colorScheme.onSurface,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context, rootNavigator: true).pop();
              },
              tooltip: 'Back',
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isAiOnline
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_isAiOnline
                                    ? theme.colorScheme.tertiary
                                    : theme.colorScheme.error)
                                .withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text('AI Meme Creator', style: theme.textTheme.titleLarge),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: CustomIconWidget(
                  iconName: 'settings',
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
                onPressed: _showSettings,
                tooltip: 'Settings',
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 2.h,
                      ),
                      itemCount: _messages.length + (_isGenerating ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _messages.length && _isGenerating) {
                          return ChatMessageWidget(
                            message: {
                              "id": 0,
                              "type": "loading",
                              "content": "Generating your meme...",
                              "timestamp": DateTime.now(),
                            },
                          );
                        }

                        final message = _messages[index];

                        if (message["type"] == "meme") {
                          return MemePreviewWidget(
                            memeUrl: message["memeUrl"] as String,
                            semanticLabel: message["semanticLabel"] as String,
                            timestamp: message["timestamp"] as DateTime,
                            onSave: () {
                              _saveMeme(
                                message["memeUrl"] as String,
                                message["memeData"] as Map<String, dynamic>,
                              );
                            },
                            onShare: () {
                              _shareMeme(
                                message["memeUrl"] as String,
                                message["memeData"] as Map<String, dynamic>,
                              );
                            },
                            onRegenerate: () {
                              HapticFeedback.lightImpact();
                              _sendMessage();
                            },
                            onEdit: () {
                              HapticFeedback.lightImpact();
                              Navigator.of(
                                context,
                                rootNavigator: true,
                              ).pushNamed(
                                AppRoutes.imageUploadEdit,
                                arguments: {
                                  'imageUrl': message["memeUrl"] as String,
                                  'memeData':
                                      message["memeData"]
                                          as Map<String, dynamic>,
                                },
                              );
                            },
                          );
                        }

                        return ChatMessageWidget(message: message);
                      },
                    ),
                    if (_showScrollButton)
                      Positioned(
                        right: 4.w,
                        bottom: 2.h,
                        child: FloatingActionButton.small(
                          onPressed: _scrollToBottom,
                          backgroundColor: theme.colorScheme.surface,
                          child: CustomIconWidget(
                            iconName: 'keyboard_arrow_down',
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              InputAreaWidget(
                controller: _messageController,
                focusNode: _messageFocusNode,
                isGenerating: _isGenerating,
                onSend: _sendMessage,
                onVoiceInput: _handleVoiceInput,
              ),
            ],
          ),
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                      SizedBox(height: 2.h),
                      Text('Saving meme...', style: theme.textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
