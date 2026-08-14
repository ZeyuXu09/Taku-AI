import 'package:flutter/material.dart';
import 'package:peakform_ai/app_navigator.dart';
import 'package:peakform_ai/config/supabase_config.dart';
import 'package:peakform_ai/screens/auth_gate.dart';
import 'package:peakform_ai/services/auth_service.dart';
import 'package:peakform_ai/services/supabase_service.dart';
import 'package:peakform_ai/services/user_profile_service.dart';
import 'package:peakform_ai/services/theme_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';
import 'package:peakform_ai/widgets/peak_bottom_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, this.onBack, this.onNavTap});

  final VoidCallback? onBack;
  final ValueChanged<int>? onNavTap;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _fallbackEmail = 'Add your email';
  static const _fallbackUnits = 'Imperial (lbs, ft)';

  String _email = _fallbackEmail;
  String _units = _fallbackUnits;

  bool _pushNotifications = true;
  bool _workoutReminders = true;
  bool _gameDayAlerts = false;

  @override
  void initState() {
    super.initState();
    _syncFromProfile();
    UserProfileService.instance.profile.addListener(_syncFromProfile);
    if (SupabaseConfig.isConfigured && SupabaseService.isSignedIn) {
      UserProfileService.instance.loadCurrentProfile();
    }
  }

  @override
  void dispose() {
    UserProfileService.instance.profile.removeListener(_syncFromProfile);
    super.dispose();
  }

  void _syncFromProfile() {
    if (!SupabaseConfig.isConfigured || !SupabaseService.isSignedIn) return;

    final email = UserProfileService.instance.displayEmail;
    final units = UserProfileService.instance.displayUnits;

    if (email.isNotEmpty && _email != email) {
      setState(() => _email = email);
    }
    if (units.isNotEmpty && _units != units) {
      setState(() => _units = units);
    }
  }

  String get _displayEmail {
    if (SupabaseConfig.isConfigured && SupabaseService.isSignedIn) {
      final email = UserProfileService.instance.displayEmail;
      if (email.isNotEmpty) return email;
    }
    return _email;
  }

  String get _displayUnits {
    if (SupabaseConfig.isConfigured && SupabaseService.isSignedIn) {
      return UserProfileService.instance.displayUnits;
    }
    return _units;
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
                    _buildHeader(context),
                    const SizedBox(height: 24),
                    _sectionTitle('Account'),
                    _settingsGroup([
                      _SettingsRow(
                        icon: Icons.email_outlined,
                        iconColor: AppColors.accent,
                        iconBackground: AppColors.accent.withValues(alpha: 0.15),
                        label: 'Email',
                        value: _displayEmail,
                        onTap: _showEmailDialog,
                      ),
                      _SettingsRow(
                        icon: Icons.lock_outline_rounded,
                        iconColor: AppColors.accent,
                        iconBackground: AppColors.accent.withValues(alpha: 0.15),
                        label: 'Change Password',
                        onTap: _showPasswordDialog,
                      ),
                      _SettingsRow(
                        icon: Icons.bar_chart_rounded,
                        iconColor: AppColors.accent,
                        iconBackground: AppColors.accent.withValues(alpha: 0.15),
                        label: 'Units',
                        value: _displayUnits,
                        onTap: _showUnitsDialog,
                        showDivider: false,
                      ),
                    ]),
                    _sectionTitle('Notifications'),
                    _settingsGroup([
                      _SettingsToggleRow(
                        icon: Icons.notifications_none_rounded,
                        label: 'Push Notifications',
                        value: _pushNotifications,
                        onChanged: (v) => setState(() => _pushNotifications = v),
                      ),
                      _SettingsToggleRow(
                        icon: Icons.schedule_rounded,
                        label: 'Workout Reminders',
                        value: _workoutReminders,
                        onChanged: (v) => setState(() => _workoutReminders = v),
                      ),
                      _SettingsToggleRow(
                        icon: Icons.emoji_events_outlined,
                        label: 'Game Day Alerts',
                        value: _gameDayAlerts,
                        onChanged: (v) => setState(() => _gameDayAlerts = v),
                        showDivider: false,
                      ),
                    ],),
                    _sectionTitle('Preferences'),
                    _settingsGroup([
                      _SettingsToggleRow(
                        icon: Icons.lightbulb_outline_rounded,
                        label: 'Dark Mode',
                        value: ThemeService.instance.isDark.value,
                        onChanged: (v) => ThemeService.instance.setDark(v),
                        prefsStyle: true,
                      ),
                      _SettingsRow(
                        icon: Icons.translate_rounded,
                        iconColor: const Color(0xFFF97316),
                        iconBackground:
                            const Color(0xFFF97316).withValues(alpha: 0.15),
                        label: 'Language',
                        value: 'English',
                        onTap: () {},
                        showDivider: false,
                        prefsStyle: true,
                      ),
                    ]),
                    _sectionTitle('About'),
                    _settingsGroup([
                      _SettingsRow(
                        icon: Icons.shield_outlined,
                        iconColor: AppColors.textSecondary,
                        iconBackground:
                            AppColors.textSecondary.withValues(alpha: 0.15),
                        label: 'Privacy Policy',
                        onTap: () {},
                        aboutStyle: true,
                      ),
                      _SettingsRow(
                        icon: Icons.description_outlined,
                        iconColor: AppColors.textSecondary,
                        iconBackground:
                            AppColors.textSecondary.withValues(alpha: 0.15),
                        label: 'Terms of Service',
                        onTap: () {},
                        aboutStyle: true,
                      ),
                      _SettingsRow(
                        icon: Icons.info_outline_rounded,
                        iconColor: AppColors.textSecondary,
                        iconBackground:
                            AppColors.textSecondary.withValues(alpha: 0.15),
                        label: 'App Version',
                        value: '1.0.0',
                        showChevron: false,
                        showDivider: false,
                        aboutStyle: true,
                      ),
                    ]),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: SupabaseConfig.isConfigured
                          ? () async {
                              try {
                                await AuthService.signOut();
                              } catch (_) {}
                              UserProfileService.instance.clear();
                              // Reset the entire nav stack to a fresh AuthGate
                              // so AuthScreen is shown even if Settings was covering it.
                              appNavigatorKey.currentState?.pushAndRemoveUntil(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AuthGate(),
                                ),
                                (_) => false,
                              );
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        foregroundColor: const Color(0xFFEF4444),
                        backgroundColor:
                            const Color(0xFFEF4444).withValues(alpha: 0.1),
                        side: BorderSide(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'PeakForm AI · Build 2025.02',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.navInactive,
                        ),
                      ),
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

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _IconBoxButton(
          icon: Icons.arrow_back_ios_new_rounded,
          size: 32,
          iconSize: 16,
          onTap: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _settingsGroup(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(children: children),
      ),
    );
  }

  Future<void> _showEmailDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _EmailDialog(initialEmail: _displayEmail),
    );
    if (result == null || !mounted) return;

    if (result == _displayEmail) return;

    if (SupabaseConfig.isConfigured && SupabaseService.isSignedIn) {
      try {
        await UserProfileService.instance.updateEmail(result);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Email updated')),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not update email')),
          );
        }
        return;
      }
    }

    setState(() => _email = result);
  }

  Future<void> _showPasswordDialog() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => const _PasswordDialog(),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    }
  }

  Future<void> _showUnitsDialog() async {
    var selected = _displayUnits;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return _SettingsDialog(
            title: 'Units',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _unitOption(
                  title: 'Imperial',
                  desc: 'lbs, ft, in',
                  value: 'Imperial (lbs, ft)',
                  selected: selected,
                  onSelect: (v) => setDialogState(() => selected = v),
                ),
                const SizedBox(height: 8),
                _unitOption(
                  title: 'Metric',
                  desc: 'kg, cm, m',
                  value: 'Metric (kg, cm)',
                  selected: selected,
                  onSelect: (v) => setDialogState(() => selected = v),
                ),
              ],
            ),
            onSave: () => _SettingsDialog.dismiss(context, true),
          );
        },
      ),
    );
    if (saved != true || !mounted) return;

    if (SupabaseConfig.isConfigured && SupabaseService.isSignedIn) {
      await UserProfileService.instance.updateUnits(selected);
    }

    setState(() => _units = selected);
  }

  Widget _unitOption({
    required String title,
    required String desc,
    required String value,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    final isSelected = selected == value;
    return Material(
      color: isSelected
          ? AppColors.accent.withValues(alpha: 0.12)
          : AppColors.barTrack,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? AppColors.accent
              : AppColors.cardBorder,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => onSelect(value),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.navInactive,
                    width: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

InputDecoration _dialogInputDecoration({String? hint}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: AppColors.navInactive),
    filled: true,
    fillColor: AppColors.barTrack,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: AppColors.cardBorder, width: 2),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.accent, width: 2),
    ),
  );
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
    this.value,
    this.onTap,
    this.showChevron = true,
    this.showDivider = true,
    this.aboutStyle = false,
    this.prefsStyle = false,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
  final String? value;
  final VoidCallback? onTap;
  final bool showChevron;
  final bool showDivider;
  final bool aboutStyle;
  final bool prefsStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (value != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          value!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showChevron)
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.navInactive,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: AppColors.divider,
          ),
      ],
    );
  }
}

class _SettingsToggleRow extends StatelessWidget {
  const _SettingsToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
    this.prefsStyle = false,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;
  final bool prefsStyle;

  @override
  Widget build(BuildContext context) {
    final iconColor = prefsStyle ? const Color(0xFFF97316) : AppColors.green;
    final iconBg = prefsStyle
        ? const Color(0xFFF97316).withValues(alpha: 0.15)
        : AppColors.green.withValues(alpha: 0.12);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: AppColors.divider,
          ),
      ],
    );
  }
}

class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog({
    required this.title,
    required this.child,
    required this.onSave,
  });

  final String title;
  final Widget child;
  final VoidCallback onSave;

  static void dismiss(BuildContext context, [dynamic result]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => dismiss(context),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: AppColors.textSecondary,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.barTrack,
                      minimumSize: const Size(28, 28),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
              const SizedBox(height: 16),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [AppColors.accent, Color(0xFF764BA2)],
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onSave,
                    borderRadius: BorderRadius.circular(14),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Save',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailDialog extends StatefulWidget {
  const _EmailDialog({required this.initialEmail});

  final String initialEmail;

  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value);
  }

  void _saveEmail() {
    final email = _controller.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter an email address');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _errorMessage = 'Enter a valid email address');
      return;
    }
    _SettingsDialog.dismiss(context, email);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsDialog(
      title: 'Email',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMAIL ADDRESS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _controller,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: _dialogInputDecoration(),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      onSave: _saveEmail,
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  late final TextEditingController _currentController;
  late final TextEditingController _newController;
  late final TextEditingController _confirmController;

  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentController = TextEditingController();
    _newController = TextEditingController();
    _confirmController = TextEditingController();
  }

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    final current = _currentController.text;
    final newPassword = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty) {
      setState(() => _errorMessage = 'Enter your current password');
      return;
    }
    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'New password must be at least 6 characters');
      return;
    }
    if (newPassword != confirm) {
      setState(() => _errorMessage = 'New passwords do not match');
      return;
    }

    if (!SupabaseConfig.isConfigured || !SupabaseService.isSignedIn) {
      setState(() => _errorMessage = 'Sign in to change your password');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await AuthService.updatePassword(
        currentPassword: current,
        newPassword: newPassword,
      );
      if (mounted) {
        _SettingsDialog.dismiss(context, true);
      }
    } on AuthException catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = error.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Could not update password';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsDialog(
      title: 'Change Password',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _passwordField(
            'CURRENT PASSWORD',
            _currentController,
            'Enter current password',
          ),
          const SizedBox(height: 14),
          _passwordField(
            'NEW PASSWORD',
            _newController,
            'Enter new password',
          ),
          const SizedBox(height: 14),
          _passwordField(
            'CONFIRM PASSWORD',
            _confirmController,
            'Confirm new password',
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: Color(0xFFEF4444),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
      onSave: _isSaving ? () {} : _savePassword,
    );
  }

  Widget _passwordField(
    String label,
    TextEditingController controller,
    String hint,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: _dialogInputDecoration(hint: hint),
        ),
      ],
    );
  }
}

class _IconBoxButton extends StatelessWidget {
  const _IconBoxButton({
    required this.icon,
    this.onTap,
    this.size = 36,
    this.iconSize = 18,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: AppColors.cardBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: iconSize, color: AppColors.textTertiary),
        ),
      ),
    );
  }
}
