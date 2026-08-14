import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:peakform_ai/app_navigator.dart';
import 'package:peakform_ai/config/supabase_config.dart';
import 'package:peakform_ai/screens/auth_gate.dart';
import 'package:peakform_ai/services/profile_avatar_service.dart';
import 'package:peakform_ai/services/supabase_service.dart';
import 'package:peakform_ai/services/theme_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env', isOptional: true);
  } catch (_) {}

  if (!SupabaseConfig.isConfigured) {
    try {
      await dotenv.load(fileName: '.env.example', isOptional: true);
    } catch (_) {}
  }

  await ProfileAvatarService.instance.initialize();
  await ThemeService.instance.load();

  if (SupabaseConfig.isConfigured) {
    await SupabaseService.initialize();
  }

  // Portrait-only for the rest of the app. AI Coach unlocks landscape itself.
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);

  runApp(const PeakFormApp());
}

void applySystemUiOverlay({required bool isDark}) {
  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
    ),
  );
}

class PeakFormApp extends StatelessWidget {
  const PeakFormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeService.instance.isDark,
      builder: (context, isDark, _) {
        applySystemUiOverlay(isDark: isDark);
        return MaterialApp(
          title: 'PeakForm AI',
          navigatorKey: appNavigatorKey,
          debugShowCheckedModeBanner: false,
          theme: _themeData(isDark: isDark),
          home: const AuthGate(),
        );
      },
    );
  }
}

ThemeData _themeData({required bool isDark}) {
  final scheme = isDark
      ? ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.background,
          onSurface: AppColors.textPrimary,
        )
      : ColorScheme.light(
          primary: AppColors.accent,
          surface: AppColors.background,
          onSurface: AppColors.textPrimary,
        );

  return ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: scheme,
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.card,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      contentTextStyle: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 14,
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        return isDark ? const Color(0xFFD1D5DB) : const Color(0xFFF9FAFB);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return AppColors.accent;
        return isDark ? const Color(0xFF3F4654) : const Color(0xFFD1D5DB);
      }),
    ),
    useMaterial3: true,
  );
}
