import 'package:flutter/material.dart';
import 'package:peakform_ai/screens/home_screen.dart';
import 'package:peakform_ai/screens/nutrition_screen.dart';
import 'package:peakform_ai/screens/profile_screen.dart';
import 'package:peakform_ai/screens/schedule_screen.dart';
import 'package:peakform_ai/screens/training_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _currentIndex,
      children: [
        HomeScreen(
          onStartTraining: () => _onNavTap(2),
          onNavTap: _onNavTap,
        ),
        ScheduleScreen(onNavTap: _onNavTap),
        TrainingScreen(
          onBack: () => _onNavTap(0),
          onNavTap: _onNavTap,
        ),
        NutritionScreen(onNavTap: _onNavTap),
        ProfileScreen(onNavTap: _onNavTap),
      ],
    );
  }
}
