import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peakform_ai/screens/app_shell.dart';
import 'package:peakform_ai/services/profile_avatar_service.dart';
import 'package:peakform_ai/theme/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ProfileAvatarService.instance.initialize();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
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
      home: const AppShell(),
    );
  }
}
