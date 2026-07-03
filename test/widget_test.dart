import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:peakform_ai/main.dart';
import 'package:peakform_ai/screens/ai_coach_screen.dart';
import 'package:peakform_ai/screens/analytics_screen.dart';
import 'package:peakform_ai/screens/active_workout_screen.dart';
import 'package:peakform_ai/screens/app_shell.dart';
import 'package:peakform_ai/screens/growth_hub_screen.dart';
import 'package:peakform_ai/screens/settings_screen.dart';
import 'package:peakform_ai/screens/sports_selection_screen.dart';
import 'package:peakform_ai/screens/exercise_detail_screen.dart';
import 'package:peakform_ai/services/training_plan_service.dart';
import 'package:peakform_ai/widgets/profile_avatar.dart';
import 'package:peakform_ai/widgets/training_location_toggle.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Home screen shows greeting and training card', (tester) async {
    final session = TrainingPlanService.instance.todaySession();

    await tester.pumpWidget(const PeakFormApp());
    await tester.pump();

    expect(find.text('Good Morning,'), findsOneWidget);
    expect(find.text('Athlete'), findsOneWidget);
    expect(find.text("Today's Training"), findsOneWidget);
    expect(find.text(session.title), findsOneWidget);
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

  testWidgets('Schedule tab shows calendar and empty games state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 1)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Game Schedule'), findsOneWidget);
    expect(find.text('No games scheduled'), findsOneWidget);
    expect(find.text('Add Game'), findsOneWidget);
    expect(find.text('vs Panthers'), findsNothing);
  });

  testWidgets('Training tab shows focus card and exercises', (tester) async {
    final session = TrainingPlanService.instance.todaySession();

    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 2)),
    );
    await tester.pump();

    expect(find.text(session.title), findsOneWidget);
    if (session.isRestDay) {
      expect(find.text('Recovery'), findsOneWidget);
    } else {
      if (session.exercises.isNotEmpty) {
        expect(find.text(session.exercises.first.name), findsOneWidget);
      }
      expect(find.text('Start Workout'), findsOneWidget);
      expect(find.text('Start with AI Coach'), findsOneWidget);
    }
  });

  testWidgets('Training tab switches visible exercises when gym selected', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 2)),
    );
    await tester.pump();

    final homeSession = TrainingPlanService.instance.todaySession();
    if (homeSession.isRestDay || homeSession.exercises.isEmpty) return;

    await tester.tap(find.text('Gym'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final gymSession = TrainingPlanService.instance.todaySession();
    expect(
      gymSession.exercises.every((e) => e.exercise.id.startsWith('gym_')),
      isTrue,
    );

    final homeNames =
        homeSession.exercises.map((e) => e.name).toList(growable: false);
    final gymNames =
        gymSession.exercises.map((e) => e.name).toList(growable: false);
    expect(gymNames, isNot(equals(homeNames)));
  });

  testWidgets('Training tab shows home/gym location toggle', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 2)),
    );
    await tester.pump();

    expect(find.byType(TrainingLocationToggle), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TrainingLocationToggle),
        matching: find.text('Home'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(TrainingLocationToggle),
        matching: find.text('Gym'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Training tab opens active workout with timer', (tester) async {
    final session = TrainingPlanService.instance.todaySession();
    if (session.isRestDay ||
        (session.exercises.isEmpty && session.routines.isEmpty)) {
      return;
    }

    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 2)),
    );
    await tester.pump();

    await tester.tap(find.text('Start Workout'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Active Workout'), findsOneWidget);
    expect(find.text('Finish Workout'), findsOneWidget);
    expect(find.text('WORKOUT TIME'), findsOneWidget);
    expect(find.text('EXERCISE TIME'), findsOneWidget);
    expect(find.text(session.exercises.first.name), findsOneWidget);
  });

  testWidgets('Training tab opens change focus sheet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 2)),
    );
    await tester.pump();

    await tester.tap(find.text('Change focus'));
    await tester.pumpAndSettle();

    expect(find.text("Change Today's Focus"), findsOneWidget);
    expect(find.text('Explosive Power'), findsOneWidget);
    expect(find.text('Pre-Game Agility'), findsOneWidget);
  });

  testWidgets('Training tab opens customize workout sheet', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 2)),
    );
    await tester.pump();

    await tester.tap(find.text('Customize'));
    await tester.pumpAndSettle();

    expect(find.text('Customize Workout'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Shuffle to new set'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Shuffle to new set'), findsOneWidget);
    expect(find.text('Reset to AI plan'), findsOneWidget);
  });

  testWidgets('Training tab opens exercise detail on tap', (tester) async {
    final session = TrainingPlanService.instance.todaySession();
    if (session.isRestDay || session.exercises.isEmpty) return;

    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 2)),
    );
    await tester.pumpAndSettle();

    final infoButton = find.byIcon(Icons.info_outline_rounded).first;
    await tester.scrollUntilVisible(
      infoButton,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(infoButton);
    await tester.pumpAndSettle();

    expect(find.text('How to do it'), findsOneWidget);
    expect(find.text('Coach notes'), findsOneWidget);
    expect(find.text(session.exercises.first.name), findsWidgets);
  });

  testWidgets('Exercise detail screen shows steps and notes', (tester) async {
    final session = TrainingPlanService.instance.todaySession();
    final scheduled = session.isRestDay
        ? session.routines.first
        : session.exercises.first;

    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseDetailScreen(scheduled: scheduled),
      ),
    );
    await tester.pump();

    expect(find.text('How to do it'), findsOneWidget);
    expect(find.text('Coach notes'), findsOneWidget);
    expect(find.text(scheduled.name), findsWidgets);
  });

  testWidgets('Nutrition tab shows calorie ring and empty meals state', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 3)),
    );
    await tester.pump();

    expect(find.text('/ 2,400 kcal'), findsOneWidget);
    expect(find.text('No meals logged yet'), findsOneWidget);
    expect(find.text('Add Manually'), findsOneWidget);
    expect(find.text('Scan Barcode'), findsOneWidget);
  });

  testWidgets('AI coach screen shows pose feedback and metrics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AiCoachScreen()),
    );
    await tester.pump();

    expect(find.text('FEATURED AI'), findsOneWidget);
    expect(find.text('AI TRAINING'), findsOneWidget);
    expect(find.text('AWAITING INPUT'), findsOneWidget);
    expect(find.text('Gallery'), findsOneWidget);
    expect(find.text('Left Knee'), findsOneWidget);
    expect(find.text('--'), findsWidgets);
  });

  testWidgets('Profile tab shows menu items', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: AppShell(initialIndex: 4)),
    );
    await tester.pump();

    expect(find.text('Growth Hub'), findsOneWidget);
    expect(find.text('Athlete'), findsOneWidget);
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
    expect(find.text('Table Tennis'), findsOneWidget);
    expect(find.text('Pickleball'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Casual'), findsOneWidget);
    expect(find.text('Serious'), findsOneWidget);
    expect(find.text('Professional'), findsOneWidget);
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
    expect(find.text('Add your email'), findsOneWidget);
    expect(find.text('Push Notifications'), findsOneWidget);
  });
}
