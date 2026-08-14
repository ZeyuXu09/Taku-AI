import 'package:peakform_ai/coach/analysis_result.dart';
import 'package:peakform_ai/coach/analyzer_factory.dart';
import 'package:peakform_ai/coach/coach_exercise.dart';
import 'package:peakform_ai/coach/exercise_analyzer.dart';

/// Survives leaving / reopening the AI Coach screen so reps stay available.
class CoachSession {
  CoachSession._();
  static final CoachSession instance = CoachSession._();

  CoachExercise exercise = CoachExercise.pushup;
  final Map<CoachExercise, ExerciseAnalyzer> _analyzers = {};
  final Map<CoachExercise, AnalysisResult> _results = {};
  final Map<CoachExercise, String> lastCues = {};
  final Map<CoachExercise, bool> lastCueIsFix = {};
  bool preferLiveOnReturn = false;

  ExerciseAnalyzer analyzerFor(CoachExercise type) {
    return _analyzers.putIfAbsent(type, () => createAnalyzer(type));
  }

  AnalysisResult resultFor(CoachExercise type) {
    return _results[type] ?? const AnalysisResult.waiting();
  }

  void setResult(CoachExercise type, AnalysisResult result) {
    _results[type] = result;
  }

  void selectExercise(CoachExercise type) {
    exercise = type;
  }

  void resetCurrent() {
    final analyzer = _analyzers[exercise];
    analyzer?.reset();
    _results[exercise] = const AnalysisResult.waiting();
  }

  /// Keeps analyzers/results; only clears the "resume live" flag.
  void markLeftScreen({required bool wasLive}) {
    preferLiveOnReturn = wasLive;
  }
}
