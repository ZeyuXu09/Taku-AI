import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:storage_client/storage_client.dart';
import 'package:peakform_ai/services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    this.fullName,
    this.email,
    this.avatarUrl,
    this.sport,
    this.units,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String? avatarUrl;
  final String? sport;
  final String? units;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      fullName: map['full_name'] as String?,
      email: map['email'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      sport: map['sport'] as String?,
      units: map['units'] as String?,
    );
  }
}

class UserProfileService {
  UserProfileService._();

  static final UserProfileService instance = UserProfileService._();

  final ValueNotifier<UserProfile?> profile = ValueNotifier(null);

  Future<void> loadCurrentProfile() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      profile.value = null;
      return;
    }

    try {
      final data = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        await ensureProfileRow();
        profile.value = UserProfile(
          id: user.id,
          fullName: user.userMetadata?['full_name'] as String?,
          email: user.email,
        );
        return;
      }

      profile.value = UserProfile.fromMap({
        ...data,
        'email': data['email'] ?? user.email,
        'full_name': data['full_name'] ?? user.userMetadata?['full_name'],
      });
    } catch (_) {
      profile.value = UserProfile(
        id: user.id,
        fullName: user.userMetadata?['full_name'] as String?,
        email: user.email,
      );
    }
  }

  /// Creates the profiles row if missing (required before saving games).
  Future<void> ensureProfileRow() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    await SupabaseService.client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'full_name': user.userMetadata?['full_name'] as String? ??
          profile.value?.fullName ??
          'Athlete',
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  String get displayName {
    final user = SupabaseService.currentUser;
    final name = profile.value?.fullName ??
        user?.userMetadata?['full_name'] as String?;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    return 'Athlete';
  }

  String get displayEmail {
    final user = SupabaseService.currentUser;
    return profile.value?.email ?? user?.email ?? '';
  }

  String get displayUnits {
    return profile.value?.units ?? 'Imperial (lbs, ft)';
  }

  Future<void> updateFullName(String fullName) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    await SupabaseService.client.auth.updateUser(
      UserAttributes(data: {'full_name': fullName}),
    );

    await _upsertProfile({
      'full_name': fullName,
      'email': user.email ?? profile.value?.email,
    });

    await loadCurrentProfile();
  }

  Future<void> updateEmail(String email) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    await SupabaseService.client.auth.updateUser(
      UserAttributes(email: email),
    );

    await _upsertProfile({
      'email': email,
      'full_name': profile.value?.fullName ??
          user.userMetadata?['full_name'] as String?,
    });

    await loadCurrentProfile();
  }

  Future<void> updateUnits(String units) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    await _upsertProfile({'units': units});

    await loadCurrentProfile();
  }

  Future<void> _upsertProfile(Map<String, dynamic> fields) async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    await SupabaseService.client.from('profiles').upsert({
      'id': user.id,
      'updated_at': DateTime.now().toIso8601String(),
      ...fields,
    });
  }

  Future<String?> uploadAvatar(File file) async {
    final user = SupabaseService.currentUser;
    if (user == null) return null;

    final extension = file.path.split('.').last.toLowerCase();
    final path = '${user.id}/avatar.$extension';

    await SupabaseService.client.storage.from('avatars').upload(
          path,
          file,
          fileOptions: FileOptions(upsert: true),
        );

    final publicUrl =
        SupabaseService.client.storage.from('avatars').getPublicUrl(path);

    await SupabaseService.client.from('profiles').upsert({
      'id': user.id,
      'avatar_url': publicUrl,
      'updated_at': DateTime.now().toIso8601String(),
    });

    await loadCurrentProfile();
    return publicUrl;
  }

  Future<void> clearRemoteAvatar() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;

    final bucket = SupabaseService.client.storage.from('avatars');
    final files = await bucket.list(path: user.id);

    for (final item in files) {
      await bucket.remove(['${user.id}/${item.name}']);
    }

    await SupabaseService.client.from('profiles').update({
      'avatar_url': null,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', user.id);

    await loadCurrentProfile();
  }

  void clear() {
    profile.value = null;
  }
}
