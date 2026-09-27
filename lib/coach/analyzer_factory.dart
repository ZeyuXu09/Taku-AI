import 'package:peakform_ai/coach/bicep_curl_analyzer.dart';
import 'package:peakform_ai/coach/coach_exercise.dart';
import 'package:peakform_ai/coach/downward_dog_analyzer.dart';
import 'package:peakform_ai/coach/exercise_analyzer.dart';
import 'package:peakform_ai/coach/plank_analyzer.dart';
import 'package:peakform_ai/coach/pullup_analyzer.dart';
import 'package:peakform_ai/coach/pushup_analyzer.dart';
import 'package:peakform_ai/coach/squat_analyzer.dart';

ExerciseAnalyzer createAnalyzer(CoachExercise type) => switch (type) {
      CoachExercise.pushup => PushupAnalyzer(),
      CoachExercise.squat => SquatAnalyzer(),
      CoachExercise.plank => PlankAnalyzer(),
      CoachExercise.bicepCurl => BicepCurlAnalyzer(),
      CoachExercise.downwardDog => DownwardDogAnalyzer(),
      CoachExercise.pullup => PullupAnalyzer(),
    };
