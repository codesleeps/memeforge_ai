import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for message input area with send and voice input buttons
/// Implements neon-accented design with smart suggestions
class InputAreaWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isGenerating;
  final VoidCallback onSend;
  final VoidCallback onVoiceInput;

  const InputAreaWidget({
    Key? key,
    required this.controller,
    required this.focusNode,
    required this.isGenerating,
    required this.onSend,
    required this.onVoiceInput,
  }) : super(key: key);

  @override
  State<InputAreaWidget> createState() => _InputAreaWidgetState();
}

class _InputAreaWidgetState extends State<InputAreaWidget> {
  bool _showSuggestions = false;

  final List<String> _suggestions = [
    'Create funny cat meme about Monday mornings',
    'Make a meme about coffee addiction',
    'Generate a success kid meme',
    'Create a distracted boyfriend meme',
    'Make a Drake meme about coding',
  ];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChange);
    super.dispose();
  }

  void _handleTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (_showSuggestions != hasText) {
      setState(() => _showSuggestions = hasText);
    }
  }

  void _selectSuggestion(String suggestion) {
    HapticFeedback.lightImpact();
    widget.controller.text = suggestion;
    setState(() => _showSuggestions = false);
    widget.focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showSuggestions && widget.controller.text.length < 10)
              _buildSuggestions(theme),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(maxHeight: 15.h),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: theme.colorScheme.outline,
                          width: 1,
                        ),
                      ),
                      child: TextField(
                        controller: widget.controller,
                        focusNode: widget.focusNode,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        enabled: !widget.isGenerating,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: 'Describe your meme idea...',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 4.w,
                            vertical: 1.5.h,
                          ),
                        ),
                        onSubmitted: (_) => widget.onSend(),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                  _buildVoiceButton(theme),
                  SizedBox(width: 2.w),
                  _buildSendButton(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions(ThemeData theme) {
    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _suggestions.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => _selectSuggestion(_suggestions[index]),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  _suggestions[index],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVoiceButton(ThemeData theme) {
    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: theme.colorScheme.outline, width: 1),
      ),
      child: IconButton(
        icon: CustomIconWidget(
          iconName: 'mic',
          color: theme.colorScheme.onSurface,
          size: 20,
        ),
        onPressed: widget.isGenerating ? null : widget.onVoiceInput,
        tooltip: 'Voice input',
      ),
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    final canSend =
        widget.controller.text.trim().isNotEmpty && !widget.isGenerating;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: canSend ? theme.colorScheme.primary : theme.colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: canSend
              ? theme.colorScheme.primary
              : theme.colorScheme.outline,
          width: 1,
        ),
        boxShadow: canSend
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: widget.isGenerating
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : CustomIconWidget(
                iconName: 'send',
                color: canSend
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
        onPressed: canSend ? widget.onSend : null,
        tooltip: 'Send message',
      ),
    );
  }
}
