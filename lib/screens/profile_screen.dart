import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peakform_ai/config/supabase_config.dart';
import 'package:peakform_ai/screens/analytics_screen.dart';
import 'package:peakform_ai/screens/coach_feedback_screen.dart';
import 'package:peakform_ai/screens/growth_hub_screen.dart';
import 'package:peakform_ai/screens/settings_screen.dart';
import 'package:peakform_ai/screens/sports_selection_screen.dart';
import 'package:peakform_ai/services/profile_avatar_service.dart';
import 'package:peakform_ai/services/supabase_service.dart';
import 'package:peakform_ai/services/user_profile_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';
import 'package:peakform_ai/widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.onNavTap});

  final ValueChanged<int>? onNavTap;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final FocusNode _nameFocusNode = FocusNode();

  late final TextEditingController _nameController;
  String _lastSavedName = '';

  @override
  void initState() {
    super.initState();
    _lastSavedName = UserProfileService.instance.displayName;
    _nameController = TextEditingController(text: _lastSavedName);
    _nameFocusNode.addListener(_handleNameFocusChange);
    UserProfileService.instance.profile.addListener(_syncNameFromProfile);
    if (SupabaseConfig.isConfigured && SupabaseService.isSignedIn) {
      UserProfileService.instance.loadCurrentProfile();
    }
  }

  void _handleNameFocusChange() {
    if (!_nameFocusNode.hasFocus) {
      _saveNameIfNeeded();
    }
  }

  void _syncNameFromProfile() {
    final name = UserProfileService.instance.profile.value?.fullName;
    if (name != null && name.isNotEmpty && _nameController.text != name) {
      _nameController.text = name;
      _lastSavedName = name;
    }
  }

  @override
  void dispose() {
    _saveNameIfNeeded();
    UserProfileService.instance.profile.removeListener(_syncNameFromProfile);
    _nameFocusNode.removeListener(_handleNameFocusChange);
    _nameFocusNode.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveNameIfNeeded() async {
    if (!SupabaseConfig.isConfigured || !SupabaseService.isSignedIn) return;

    final name = _nameController.text.trim();
    if (name.isEmpty || name == _lastSavedName) return;

    try {
      await UserProfileService.instance.updateFullName(name);
      _lastSavedName = name;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name saved')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save name')),
        );
      }
    }
  }

  bool get _hasCustomAvatar {
    if (ProfileAvatarService.instance.hasCustomAvatar) return true;
    final remoteUrl = UserProfileService.instance.profile.value?.avatarUrl;
    return remoteUrl != null && remoteUrl.isNotEmpty;
  }

  void _pushSubScreen(
    BuildContext context,
    Widget Function(BuildContext routeContext) builder,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: builder),
    );
  }

  ValueChanged<int> _subScreenNavHandler(BuildContext routeContext) {
    return (index) {
      Navigator.of(routeContext).maybePop();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        widget.onNavTap?.call(index);
      });
    };
  }

  VoidCallback _subScreenBackHandler(BuildContext routeContext) {
    return () => Navigator.of(routeContext).maybePop();
  }

  Future<void> _pickProfilePhoto() async {
    final action = await showModalBottomSheet<_PhotoPickAction>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.navInactive,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Change Profile Photo',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _photoOptionTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose from Gallery',
                  onTap: () => Navigator.of(context).pop(_PhotoPickAction.gallery),
                ),
                const SizedBox(height: 8),
                _photoOptionTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take a Photo',
                  onTap: () => Navigator.of(context).pop(_PhotoPickAction.camera),
                ),
                if (_hasCustomAvatar) ...[
                  const SizedBox(height: 8),
                  _photoOptionTile(
                    icon: Icons.delete_outline_rounded,
                    label: 'Remove Photo',
                    destructive: true,
                    onTap: () => Navigator.of(context).pop(_PhotoPickAction.remove),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    try {
      switch (action) {
        case _PhotoPickAction.gallery:
          await _pickImage(ImageSource.gallery);
        case _PhotoPickAction.camera:
          await _pickImage(ImageSource.camera);
        case _PhotoPickAction.remove:
          await ProfileAvatarService.instance.clearAvatar();
          if (SupabaseConfig.isConfigured && SupabaseService.isSignedIn) {
            await UserProfileService.instance.clearRemoteAvatar();
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile photo removed')),
            );
          }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update profile photo')),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (picked == null || !mounted) return;

    await ProfileAvatarService.instance.setLocalPath(picked.path);

    if (SupabaseConfig.isConfigured && SupabaseService.isSignedIn) {
      await UserProfileService.instance.uploadAvatar(File(picked.path));
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile photo updated')),
      );
    }
  }

  Widget _photoOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool destructive = false,
  }) {
    final color = destructive ? const Color(0xFFEF4444) : AppColors.textPrimary;

    return Material(
      color: AppColors.barTrack,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildProfileCard(),
                    const SizedBox(height: 28),
                    Text(
                      'MENU',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _MenuItem(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconColor: AppColors.green,
                      iconBackground: AppColors.green.withValues(alpha: 0.15),
                      title: 'Coach Feedback',
                      description: 'All AI Coach cues from your sessions',
                      onTap: () {
                        _pushSubScreen(
                          context,
                          (routeContext) => CoachFeedbackScreen(
                            onBack: _subScreenBackHandler(routeContext),
                            onNavTap: _subScreenNavHandler(routeContext),
                            navIndex: 4,
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.trending_up_rounded,
                      iconColor: AppColors.green,
                      iconBackground: AppColors.green.withValues(alpha: 0.15),
                      title: 'Growth Hub',
                      description: 'Track height, posture & recovery',
                      onTap: () {
                        _pushSubScreen(
                          context,
                          (routeContext) => GrowthHubScreen(
                            onBack: _subScreenBackHandler(routeContext),
                            onNavTap: _subScreenNavHandler(routeContext),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.show_chart_rounded,
                      iconColor: AppColors.accent,
                      iconBackground: AppColors.accent.withValues(alpha: 0.2),
                      title: 'Analytics',
                      description: 'Training load, recovery & body metrics',
                      onTap: () {
                        _pushSubScreen(
                          context,
                          (routeContext) => AnalyticsScreen(
                            onBack: _subScreenBackHandler(routeContext),
                            onNavTap: _subScreenNavHandler(routeContext),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.public_rounded,
                      iconColor: const Color(0xFFF97316),
                      iconBackground:
                          const Color(0xFFF97316).withValues(alpha: 0.2),
                      title: 'Sports Selection',
                      description: 'Choose your sport & intensity',
                      onTap: () {
                        _pushSubScreen(
                          context,
                          (routeContext) => SportsSelectionScreen(
                            onBack: _subScreenBackHandler(routeContext),
                            onNavTap: _subScreenNavHandler(routeContext),
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.settings_rounded,
                      iconColor: AppColors.textSecondary,
                      iconBackground:
                          AppColors.textSecondary.withValues(alpha: 0.15),
                      title: 'Settings',
                      description: 'Account, notifications & preferences',
                      onTap: () {
                        _pushSubScreen(
                          context,
                          (routeContext) => SettingsScreen(
                            onBack: _subScreenBackHandler(routeContext),
                            onNavTap: _subScreenNavHandler(routeContext),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            PeakBottomNav(
              currentIndex: 4,
              onTap: widget.onNavTap ?? (_) {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: ProfileAvatar(
              radius: 37,
              borderWidth: 3,
              showCameraBadge: true,
              onTap: _pickProfilePhoto,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NAME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _nameController,
                  focusNode: _nameFocusNode,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: _saveNameIfNeeded,
                  onSubmitted: (_) => _saveNameIfNeeded(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.barTrack,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.accent.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.accent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tap photo to upload · tap name to edit',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.navInactive,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _PhotoPickAction { gallery, camera, remove }

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.description,
    this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.cardBorder),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.navInactive,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
