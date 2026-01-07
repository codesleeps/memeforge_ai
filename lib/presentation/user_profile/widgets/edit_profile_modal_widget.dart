import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../theme/app_theme.dart';

class EditProfileModalWidget extends StatefulWidget {
  final Map<String, dynamic> currentProfile;
  final VoidCallback onProfileUpdated;

  const EditProfileModalWidget({
    super.key,
    required this.currentProfile,
    required this.onProfileUpdated,
  });

  @override
  State<EditProfileModalWidget> createState() => _EditProfileModalWidgetState();
}

class _EditProfileModalWidgetState extends State<EditProfileModalWidget> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final _supabaseService = SupabaseService.instance;
  final _imagePicker = ImagePicker();

  bool _isSaving = false;
  Uint8List? _selectedImageBytes;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.currentProfile['full_name'] ?? '';
    _usernameController.text = widget.currentProfile['username'] ?? '';
    _bioController.text = widget.currentProfile['bio'] ?? '';
    _currentAvatarUrl = widget.currentProfile['avatar_url'];
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: ${e.toString()}'),
            backgroundColor: AppTheme.errorDark,
          ),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final userId = _supabaseService.currentUser?.id;
    if (userId == null) {
      setState(() => _isSaving = false);
      return;
    }

    String? avatarUrl;

    // Upload new avatar if selected
    if (_selectedImageBytes != null) {
      debugPrint('Uploading avatar...');
      avatarUrl = await _supabaseService.uploadProfileAvatar(
        bytes: _selectedImageBytes!,
        userId: userId,
      );

      debugPrint('Avatar uploaded: $avatarUrl');

      if (avatarUrl == null) {
        setState(() => _isSaving = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to upload avatar'),
              backgroundColor: AppTheme.errorDark,
            ),
          );
        }
        return;
      }
    }

    debugPrint('Updating profile with avatar: $avatarUrl');

    final success = await _supabaseService.updateUserProfile(
      userId: userId,
      fullName: _fullNameController.text.trim(),
      username: _usernameController.text.trim(),
      bio: _bioController.text.trim(),
      avatarUrl: avatarUrl, // Only update if new avatar was uploaded
    );

    debugPrint('Profile update success: $success');

    setState(() => _isSaving = false);

    if (success && mounted) {
      widget.onProfileUpdated();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          backgroundColor: AppTheme.primaryDark,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to update profile'),
          backgroundColor: AppTheme.errorDark,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundDark,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20.0)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withAlpha(51),
            blurRadius: 20.0,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: AppTheme.textPrimaryDark,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppTheme.textPrimaryDark),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                // Avatar picker
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          width: 30.w,
                          height: 30.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.primaryDark,
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryDark.withAlpha(77),
                                blurRadius: 12.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: _selectedImageBytes != null
                                ? Image.memory(
                                    _selectedImageBytes!,
                                    fit: BoxFit.cover,
                                  )
                                : _currentAvatarUrl != null &&
                                      _currentAvatarUrl!.isNotEmpty
                                ? CustomImageWidget(
                                    imageUrl: _currentAvatarUrl!,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    color: AppTheme.cardDark,
                                    child: Icon(
                                      Icons.person,
                                      size: 15.w,
                                      color: AppTheme.textSecondaryDark,
                                    ),
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(2.w),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryDark,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.backgroundDark,
                                width: 2.0,
                              ),
                            ),
                            child: Icon(
                              Icons.camera_alt,
                              color: AppTheme.backgroundDark,
                              size: 4.w,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                TextFormField(
                  controller: _fullNameController,
                  style: TextStyle(
                    color: AppTheme.textPrimaryDark,
                    fontSize: 13.sp,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: AppTheme.textSecondaryDark),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: AppTheme.primaryDark.withAlpha(77),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: AppTheme.primaryDark.withAlpha(77),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: AppTheme.primaryDark,
                        width: 2.0,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: _usernameController,
                  style: TextStyle(
                    color: AppTheme.textPrimaryDark,
                    fontSize: 13.sp,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: AppTheme.textSecondaryDark),
                    prefixText: '@',
                    prefixStyle: TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: 13.sp,
                    ),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: AppTheme.primaryDark.withAlpha(77),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: AppTheme.primaryDark.withAlpha(77),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: AppTheme.primaryDark,
                        width: 2.0,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a username';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Username can only contain letters, numbers, and underscores';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: _bioController,
                  style: TextStyle(
                    color: AppTheme.textPrimaryDark,
                    fontSize: 13.sp,
                  ),
                  maxLines: 3,
                  maxLength: 200,
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    labelStyle: TextStyle(color: AppTheme.textSecondaryDark),
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: AppTheme.primaryDark.withAlpha(77),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: AppTheme.primaryDark.withAlpha(77),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(
                        color: AppTheme.primaryDark,
                        width: 2.0,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 3.h),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: AppTheme.backgroundDark,
                      padding: EdgeInsets.symmetric(vertical: 1.8.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      disabledBackgroundColor: AppTheme.primaryDark.withAlpha(
                        128,
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 2.5.h,
                            width: 2.5.h,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.backgroundDark,
                              ),
                            ),
                          )
                        : Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 2.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
