import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:peakform_ai/config/supabase_config.dart';
import 'package:peakform_ai/screens/auth_gate.dart';
import 'package:peakform_ai/services/profile_avatar_service.dart';
import 'package:peakform_ai/services/supabase_service.dart';
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

  if (SupabaseConfig.isConfigured) {
    await SupabaseService.initialize();
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const PeakFormApp());
}

class PeakFormApp extends StatelessWidget {
  const PeakFormApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PeakForm AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.dark(
          primary: AppColors.accent,
          surface: AppColors.background,
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}
