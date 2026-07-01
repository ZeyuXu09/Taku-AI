import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peakform_ai/main.dart';
import 'package:peakform_ai/screens/ai_coach_screen.dart';
import 'package:peakform_ai/screens/analytics_screen.dart';
import 'package:peakform_ai/screens/app_shell.dart';
import 'package:peakform_ai/screens/growth_hub_screen.dart';
import 'package:peakform_ai/screens/settings_screen.dart';
import 'package:peakform_ai/screens/sports_selection_screen.dart';
import 'package:peakform_ai/widgets/profile_avatar.dart';

void main() {
  testWidgets('Home screen shows greeting and training card', (tester) async {
    await tester.pumpWidget(const PeakFormApp());
    await tester.pump();

    expect(find.text('Good Morning,'), findsOneWidget);
    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.text("Today's Training"), findsOneWidget);
    expect(find.text('Agility & Speed Drills'), findsOneWidget);
  });

  testWidgets('Profile photo tap shows upload options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 4)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ProfileAvatar));
    await tester.pumpAndSettle();

    expect(find.text('Change Profile Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('Take a Photo'), findsOneWidget);
  });

  testWidgets('Home profile photo opens profile tab', (tester) async {
    await tester.pumpWidget(const PeakFormApp());
    await tester.pumpAndSettle();

    expect(find.text('Good Morning,'), findsOneWidget);

    await tester.tap(find.byType(ProfileAvatar).first);
    await tester.pumpAndSettle();

    expect(find.text('Growth Hub'), findsOneWidget);
    expect(find.text('Good Morning,'), findsNothing);
  });

  testWidgets('Schedule tab shows calendar and upcoming games', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 1)),
    );
    await tester.pump();

    expect(find.text('Game Schedule'), findsOneWidget);
    expect(find.text('February 2025'), findsOneWidget);
    expect(find.text('vs Panthers'), findsOneWidget);
    expect(find.text("This Week's Plan"), findsOneWidget);
  });

  testWidgets('Training tab shows focus card and exercises', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 2)),
    );
    await tester.pump();

    expect(find.text('Pre-Game Agility'), findsOneWidget);
    expect(find.text('Lateral Shuttle Runs'), findsOneWidget);
    expect(find.text('Start Workout with AI Coach'), findsOneWidget);
  });

  testWidgets('Nutrition tab shows calorie ring and meals', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 3)),
    );
    await tester.pump();

    expect(find.text('/ 2,400 kcal'), findsOneWidget);
    expect(find.text('Oatmeal with Berries'), findsOneWidget);
    expect(find.text('Grilled Chicken Salad'), findsOneWidget);
  });

  testWidgets('AI coach screen shows pose feedback and metrics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AiCoachScreen()),
    );
    await tester.pump();

    expect(find.text('FEATURED AI'), findsOneWidget);
    expect(find.text('AI TRAINING'), findsOneWidget);
    expect(find.text('98% CONFIDENCE'), findsOneWidget);
    expect(find.text('Left Knee'), findsOneWidget);
    expect(find.text('EXCELLENT'), findsOneWidget);
  });

  testWidgets('Profile tab shows menu items', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 4)),
    );
    await tester.pump();

    expect(find.text('Growth Hub'), findsOneWidget);
    expect(find.text('Alex Rivera'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Growth hub shows height and body composition', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: GrowthHubScreen()),
    );
    await tester.pump();

    expect(find.text('Growth Hub'), findsOneWidget);
    expect(find.text('Maximize Your Potential'), findsOneWidget);
    expect(find.text("5'10\""), findsOneWidget);
    expect(find.text('Body Composition'), findsOneWidget);
  });

  testWidgets('Analytics screen shows gauges and PRs', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AnalyticsScreen()));
    await tester.pump();

    expect(find.text('Optimal'), findsOneWidget);
    expect(find.text('Vertical Jump'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
  });

  testWidgets('Sports selection shows sport grid', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SportsSelectionScreen()));
    await tester.pump();

    expect(find.text('PeakForm AI'), findsOneWidget);
    expect(find.text('Basketball'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });

  testWidgets('Sports selection get started uses onNavTap without double pop', (
    tester,
  ) async {
    var navTapCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SportsSelectionScreen(
          onNavTap: (_) => navTapCount++,
        ),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Get Started'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(navTapCount, 1);
  });

  testWidgets('Sports selection get started from profile returns to home', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 4)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sports Selection'));
    await tester.pumpAndSettle();

    expect(find.text('Choose Your Sport'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Get Started'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Good Morning,'), findsOneWidget);
    expect(find.text('Choose Your Sport'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Growth Hub'), findsOneWidget);
  });

  testWidgets('Settings email dialog closes without layout overflow', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'new@email.com');
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Settings email dialog closes with keyboard inset visible', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            viewInsets: EdgeInsets.only(bottom: 336),
          ),
          child: const SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Settings screen shows account section', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));
    await tester.pump();

    expect(find.text('Log Out'), findsOneWidget);
    expect(find.text('alex.rivera@email.com'), findsOneWidget);
    expect(find.text('Push Notifications'), findsOneWidget);
  });
}
