import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:peakform_ai/coach/pullup_analyzer.dart';

void main() {
  late PullupAnalyzer analyzer;
  final t0 = DateTime(2026, 8, 13, 9);

  setUp(() {
    analyzer = PullupAnalyzer();
  });

  test('hang is the bottom spot', () {
    final result = analyzer.update(_hangPose(), t0);
    expect(result.poseVisible, isTrue);
    expect(result.phase, 'Hang');
    expect(result.reps, 0);
  });

  test('head over hands is the top spot', () {
    final result = analyzer.update(_topPose(), t0);
    expect(result.poseVisible, isTrue);
    expect(result.phase, 'Top');
    expect(result.reps, 0);
  });

  test('counts one rep after top then hang', () {
    analyzer.update(_hangPose(), t0);
    analyzer.update(_topPose(), t0.add(const Duration(milliseconds: 200)));
    final done = analyzer.update(
      _hangPose(),
      t0.add(const Duration(milliseconds: 400)),
    );
    expect(done.reps, 1);
    expect(done.phase, 'Hang');
  });

  test('staying at the top does not add extra reps', () {
    analyzer.update(_hangPose(), t0);
    analyzer.update(_topPose(), t0.add(const Duration(milliseconds: 200)));
    analyzer.update(_topPose(), t0.add(const Duration(milliseconds: 400)));
    final stillTop = analyzer.update(
      _topPose(),
      t0.add(const Duration(milliseconds: 600)),
    );
    expect(stillTop.reps, 0);
    expect(stillTop.phase, 'Top');
  });
}

Pose _hangPose() {
  return _pose({
    PoseLandmarkType.nose: (100, 300),
    PoseLandmarkType.leftShoulder: (80, 260),
    PoseLandmarkType.rightShoulder: (120, 260),
    PoseLandmarkType.leftElbow: (80, 170),
    PoseLandmarkType.rightElbow: (120, 170),
    PoseLandmarkType.leftWrist: (80, 80),
    PoseLandmarkType.rightWrist: (120, 80),
    PoseLandmarkType.leftHip: (85, 430),
    PoseLandmarkType.rightHip: (115, 430),
  });
}

Pose _topPose() {
  return _pose({
    PoseLandmarkType.nose: (100, 70),
    PoseLandmarkType.leftShoulder: (80, 130),
    PoseLandmarkType.rightShoulder: (120, 130),
    PoseLandmarkType.leftElbow: (40, 170),
    PoseLandmarkType.rightElbow: (160, 170),
    PoseLandmarkType.leftWrist: (80, 80),
    PoseLandmarkType.rightWrist: (120, 80),
    PoseLandmarkType.leftHip: (85, 360),
    PoseLandmarkType.rightHip: (115, 360),
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
