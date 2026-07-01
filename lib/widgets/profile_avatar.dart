import 'package:flutter/material.dart';
import 'package:peakform_ai/services/profile_avatar_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    required this.radius,
    this.borderWidth = 2,
    this.onTap,
    this.showCameraBadge = false,
  });

  final double radius;
  final double borderWidth;
  final VoidCallback? onTap;
  final bool showCameraBadge;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: ProfileAvatarService.instance.localPath,
      builder: (context, localPath, _) {
        final avatar = _buildAvatar(localPath);

        if (onTap == null) {
          return avatar;
        }

        return Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onTap,
            customBorder: const CircleBorder(),
            child: avatar,
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? localPath) {
    final size = radius * 2;
    final avatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.accent, width: borderWidth),
      ),
      child: CircleAvatar(
        radius: radius - borderWidth,
        backgroundColor: AppColors.barTrack,
        backgroundImage: ProfileAvatarService.instance.avatarImage(localPath),
        onBackgroundImageError: (_, __) {},
      ),
    );

    if (!showCameraBadge) {
      return avatar;
    }

    final badgeSize = radius * 0.72;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.card, width: 2),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                size: badgeSize * 0.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
