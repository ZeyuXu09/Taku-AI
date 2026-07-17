import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/analysis_result.dart';

abstract class ExerciseAnalyzer {
  bool get isStatic;
  AnalysisResult update(Pose pose, DateTime now);
  void reset();
}
