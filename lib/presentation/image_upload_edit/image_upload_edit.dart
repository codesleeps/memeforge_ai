import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../widgets/custom_icon_widget.dart';

class ImageUploadEdit extends StatefulWidget {
  const ImageUploadEdit({Key? key}) : super(key: key);

  @override
  State<ImageUploadEdit> createState() => _ImageUploadEditState();
}

class _ImageUploadEditState extends State<ImageUploadEdit> {
  File? _imageFile;
  Uint8List? _webImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isSaving = false;

  // Text overlay state
  String _overlayText = '';
  double _fontSize = 32.0;
  Color _textColor = Colors.white;
  TextAlign _textAlignment = TextAlign.center;
  Offset _textPosition = const Offset(0.5, 0.5);

  Future<void> _pickImage(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            _imageFile = null;
            _isLoading = false;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _webImage = null;
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    if ((_imageFile == null && _webImage == null) || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      final currentUser = SupabaseService.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // For now, we'll use a placeholder URL
      // In production, you would upload the image to storage first
      final imageUrl = 'https://via.placeholder.com/600x400';

      await SupabaseService.instance.createMeme(
        userId: currentUser.id,
        title: 'My Meme ${DateTime.now().millisecondsSinceEpoch}',
        imageUrl: imageUrl,
        description: _overlayText.isNotEmpty ? _overlayText : null,
        visibility: 'private',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meme saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Action Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: _handleCancel,
                    icon: CustomIconWidget(
                      iconName: 'close',
                      color: theme.colorScheme.onSurface,
                      size: 24,
                    ),
                  ),
                  Text(
                    'Edit Meme',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  _isSaving
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : IconButton(
                          onPressed: (_imageFile != null || _webImage != null)
                              ? _handleSave
                              : null,
                          icon: CustomIconWidget(
                            iconName: 'check',
                            color: (_imageFile != null || _webImage != null)
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.3,
                                  ),
                            size: 24,
                          ),
                        ),
                ],
              ),
            ),

            // Image Preview Area
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : _imageFile == null && _webImage == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: theme.colorScheme.primary.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            child: CustomIconWidget(
                              iconName: 'add_photo_alternate',
                              color: theme.colorScheme.primary,
                              size: 64,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            'Upload an Image',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          Text(
                            'Choose from gallery or take a photo',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () =>
                                    _pickImage(ImageSource.gallery),
                                icon: CustomIconWidget(
                                  iconName: 'photo_library',
                                  color: theme.colorScheme.onPrimary,
                                  size: 20,
                                ),
                                label: Text('Gallery'),
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                ),
                              ),
                              SizedBox(width: 4.w),
                              OutlinedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: CustomIconWidget(
                                  iconName: 'camera_alt',
                                  color: theme.colorScheme.primary,
                                  size: 20,
                                ),
                                label: Text('Camera'),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : Stack(
                      children: [
                        Center(
                          child: kIsWeb && _webImage != null
                              ? Image.memory(_webImage!, fit: BoxFit.contain)
                              : _imageFile != null
                              ? Image.file(_imageFile!, fit: BoxFit.contain)
                              : const SizedBox.shrink(),
                        ),
                        if (_overlayText.isNotEmpty)
                          Positioned.fill(
                            child: Align(
                              alignment: Alignment(
                                (_textPosition.dx * 2) - 1,
                                (_textPosition.dy * 2) - 1,
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(4.w),
                                child: Text(
                                  _overlayText,
                                  textAlign: _textAlignment,
                                  style: TextStyle(
                                    fontSize: _fontSize,
                                    color: _textColor,
                                    fontWeight: FontWeight.w900,
                                    shadows: [
                                      Shadow(
                                        blurRadius: 4.0,
                                        color: Colors.black,
                                        offset: Offset(2.0, 2.0),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            // Editing Toolbar (only show when image is loaded)
            if (_imageFile != null || _webImage != null)
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Text Input
                    TextField(
                      onChanged: (value) =>
                          setState(() => _overlayText = value),
                      decoration: InputDecoration(
                        hintText: 'Add text to your meme...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    // Quick Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          onPressed: () =>
                              setState(() => _textColor = Colors.white),
                          icon: CustomIconWidget(
                            iconName: 'format_color_text',
                            color: _textColor == Colors.white
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                        IconButton(
                          onPressed: () =>
                              setState(() => _textColor = Colors.black),
                          icon: CustomIconWidget(
                            iconName: 'format_color_fill',
                            color: _textColor == Colors.black
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() {
                            _fontSize = _fontSize == 32.0 ? 48.0 : 32.0;
                          }),
                          icon: CustomIconWidget(
                            iconName: 'format_size',
                            color: theme.colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                        IconButton(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: CustomIconWidget(
                            iconName: 'photo_library',
                            color: theme.colorScheme.onSurface,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
