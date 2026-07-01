import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileAvatarService {
  ProfileAvatarService._();

  static final ProfileAvatarService instance = ProfileAvatarService._();

  static const defaultAvatarUrl =
      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=160&h=160&fit=crop&crop=face';

  static const _storageKey = 'profile_avatar_path';

  final ValueNotifier<String?> localPath = ValueNotifier(null);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString(_storageKey);
    if (savedPath != null && File(savedPath).existsSync()) {
      localPath.value = savedPath;
    } else if (savedPath != null) {
      await prefs.remove(_storageKey);
    }
  }

  ImageProvider avatarImage([String? path]) {
    final resolvedPath = path ?? localPath.value;
    if (resolvedPath != null && File(resolvedPath).existsSync()) {
      return FileImage(File(resolvedPath));
    }
    return NetworkImage(defaultAvatarUrl);
  }

  bool get hasCustomAvatar {
    final path = localPath.value;
    return path != null && File(path).existsSync();
  }

  Future<void> setLocalPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, path);
    localPath.value = path;
  }

  Future<void> clearAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    localPath.value = null;
  }
}
