import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/squat_analyzer.dart';

void main() {
  late SquatAnalyzer analyzer;
  final t0 = DateTime(2026, 8, 14, 10);

  setUp(() {
    analyzer = SquatAnalyzer();
  });

  test('standing is the top spot', () {
    final result = analyzer.update(_standPose(), t0);
    expect(result.poseVisible, isTrue);
    expect(result.phase, 'Stand');
    expect(result.reps, 0);
  });

  test('deep knee bend is the bottom spot', () {
    final result = analyzer.update(_bottomPose(), t0);
    expect(result.poseVisible, isTrue);
    expect(result.phase, 'Down');
    expect(result.reps, 0);
  });

  test('counts one rep after down then stand', () {
    analyzer.update(_standPose(), t0);
    analyzer.update(_bottomPose(), t0.add(const Duration(milliseconds: 200)));
    final done = analyzer.update(
      _standPose(),
      t0.add(const Duration(milliseconds: 400)),
    );
    expect(done.reps, 1);
    expect(done.phase, 'Stand');
  });

  test('staying at the bottom does not add extra reps', () {
    analyzer.update(_standPose(), t0);
    analyzer.update(_bottomPose(), t0.add(const Duration(milliseconds: 200)));
    analyzer.update(_bottomPose(), t0.add(const Duration(milliseconds: 400)));
    final stillDown = analyzer.update(
      _bottomPose(),
      t0.add(const Duration(milliseconds: 600)),
    );
    expect(stillDown.reps, 0);
    expect(stillDown.phase, 'Down');
  });
}

Pose _standPose() {
  return _pose({
    PoseLandmarkType.leftShoulder: (100, 80),
    PoseLandmarkType.rightShoulder: (140, 80),
    PoseLandmarkType.leftHip: (105, 220),
    PoseLandmarkType.rightHip: (135, 220),
    PoseLandmarkType.leftKnee: (108, 380),
    PoseLandmarkType.rightKnee: (132, 380),
    PoseLandmarkType.leftAnkle: (110, 540),
    PoseLandmarkType.rightAnkle: (130, 540),
  });
}

Pose _bottomPose() {
  return _pose({
    PoseLandmarkType.leftShoulder: (70, 160),
    PoseLandmarkType.rightShoulder: (110, 160),
    PoseLandmarkType.leftHip: (150, 300),
    PoseLandmarkType.rightHip: (180, 300),
    PoseLandmarkType.leftKnee: (230, 340),
    PoseLandmarkType.rightKnee: (250, 340),
    PoseLandmarkType.leftAnkle: (170, 540),
    PoseLandmarkType.rightAnkle: (190, 540),
  });
}

Pose _pose(Map<PoseLandmarkType, (double, double)> points) {
  return Pose(
    landmarks: {
      for (final entry in points.entries)
        entry.key: PoseLandmark(
          type: entry.key,
          x: entry.value.$1,
          y: entry.value.$2,
          z: 0,
          likelihood: 1,
        ),
    },
  );
}
