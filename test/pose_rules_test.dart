import 'package:flutter_test/flutter_test.dart';
import 'package:pose_flash/game/pose_rules.dart';

Map<Joint, BodyPoint> sample(PoseKind pose) {
  final points = <Joint, BodyPoint>{
    Joint.nose: const BodyPoint(250, 140),
    Joint.leftShoulder: const BodyPoint(200, 200),
    Joint.rightShoulder: const BodyPoint(300, 200),
    Joint.leftHip: const BodyPoint(215, 320),
    Joint.rightHip: const BodyPoint(285, 320),
    Joint.leftKnee: const BodyPoint(220, 320),
    Joint.rightKnee: const BodyPoint(280, 320),
    Joint.leftAnkle: const BodyPoint(220, 430),
    Joint.rightAnkle: const BodyPoint(280, 430),
  };
  final (left, right) = switch (pose) {
    PoseKind.reach => (0, 0),
    PoseKind.wings => (1, 1),
    PoseKind.goalpost => (2, 2),
    PoseKind.hips => (3, 3),
    PoseKind.reachWing => (0, 1),
    PoseKind.reachHip => (0, 3),
    PoseKind.down => (4, 4),
    PoseKind.cross => (5, 5),
    PoseKind.clap => (6, 6),
    PoseKind.wingGoalpost => (1, 2),
    PoseKind.wingHip => (1, 3),
    PoseKind.reachGoalpost => (0, 2),
    PoseKind.singleReach => (0, 4),
    PoseKind.sideLean => (2, 2),
    PoseKind.oneLeg => (1, 1),
    PoseKind.handsHead => (7, 7),
    PoseKind.squat => (4, 4),
    PoseKind.star => (8, 8),
  };
  void arm(int kind, bool left) {
    BodyPoint point(double x, double y) => BodyPoint(left ? x : 500 - x, y);
    final (elbow, wrist) = switch (kind) {
      0 => (point(180, 140), point(160, 80)),
      1 => (point(140, 200), point(80, 200)),
      2 => (point(140, 200), point(140, 140)),
      3 => (point(155, 260), point(215, 320)),
      4 => (point(205, 270), point(195, 370)),
      5 => (point(180, 250), point(290, 250)),
      7 => (point(190, 155), point(190, 140)),
      8 => (point(160, 160), point(120, 120)),
      _ => (point(185, 250), point(250, 250)),
    };
    points[left ? Joint.leftElbow : Joint.rightElbow] = elbow;
    points[left ? Joint.leftWrist : Joint.rightWrist] = wrist;
  }

  arm(left, true);
  arm(right, false);
  if (pose == PoseKind.sideLean) {
    points[Joint.leftShoulder] = const BodyPoint(160, 200);
    points[Joint.rightShoulder] = const BodyPoint(260, 200);
  }
  if (pose == PoseKind.oneLeg) {
    points[Joint.leftKnee] = const BodyPoint(220, 250);
    points[Joint.leftAnkle] = const BodyPoint(220, 280);
  }
  if (pose == PoseKind.squat) {
    points[Joint.leftKnee] = const BodyPoint(220, 335);
    points[Joint.rightKnee] = const BodyPoint(280, 335);
    points[Joint.leftAnkle] = const BodyPoint(320, 430);
    points[Joint.rightAnkle] = const BodyPoint(180, 430);
  }
  if (pose == PoseKind.star) {
    points[Joint.leftAnkle] = const BodyPoint(150, 430);
    points[Joint.rightAnkle] = const BodyPoint(350, 430);
  }
  return points;
}

void main() {
  const rules = PoseRules();
  final upperBodyPoses = PoseKind.values
      .where(
        (pose) =>
            pose != PoseKind.sideLean &&
            pose != PoseKind.oneLeg &&
            pose != PoseKind.squat &&
            pose != PoseKind.star,
      )
      .toList();
  for (final pose in upperBodyPoses) {
    test('${pose.name}: accepts the intended pose and rejects other poses', () {
      final body = sample(pose);
      for (final target in PoseKind.values) {
        expect(
          rules.evaluate(target, body),
          target == pose ? PoseMatch.match : PoseMatch.mismatch,
          reason: '${pose.name} must not pass ${target.name}',
        );
      }
    });
    test('${pose.name}: mirrored and scaled poses have the same result', () {
      final mirrored = sample(pose).map(
        (key, value) =>
            MapEntry(key, BodyPoint(1000 - value.x * 1.6, value.y * 1.6 + 50)),
      );
      expect(rules.evaluate(pose, mirrored), PoseMatch.match);
    });
  }

  test('side lean accepts either mirrored direction', () {
    expect(
      rules.evaluate(PoseKind.sideLean, sample(PoseKind.sideLean)),
      PoseMatch.match,
    );
    final mirrored = sample(
      PoseKind.sideLean,
    ).map((key, value) => MapEntry(key, BodyPoint(1000 - value.x, value.y)));
    expect(rules.evaluate(PoseKind.sideLean, mirrored), PoseMatch.match);
  });

  test('one leg raised accepts either leg', () {
    expect(
      rules.evaluate(PoseKind.oneLeg, sample(PoseKind.oneLeg)),
      PoseMatch.match,
    );
    final mirrored = sample(
      PoseKind.oneLeg,
    ).map((key, value) => MapEntry(key, BodyPoint(1000 - value.x, value.y)));
    expect(rules.evaluate(PoseKind.oneLeg, mirrored), PoseMatch.match);
  });

  test('hands-head, squat and star poses are recognized', () {
    expect(
      rules.evaluate(PoseKind.handsHead, sample(PoseKind.handsHead)),
      PoseMatch.match,
    );
    expect(
      rules.evaluate(PoseKind.squat, sample(PoseKind.squat)),
      PoseMatch.match,
    );
    expect(
      rules.evaluate(PoseKind.star, sample(PoseKind.star)),
      PoseMatch.match,
    );
  });

  test('missing, low-confidence and non-finite joints are unknown', () {
    expect(rules.evaluate(PoseKind.reach, {}), PoseMatch.unknown);
    for (final joint in [
      Joint.nose,
      Joint.leftShoulder,
      Joint.rightShoulder,
      Joint.leftElbow,
      Joint.rightElbow,
      Joint.leftWrist,
      Joint.rightWrist,
      Joint.leftHip,
      Joint.rightHip,
    ]) {
      final body = sample(PoseKind.reach);
      body[joint] = const BodyPoint(100, 100, confidence: 0.1);
      expect(rules.evaluate(PoseKind.reach, body), PoseMatch.unknown);
      body[joint] = const BodyPoint(double.nan, 100);
      expect(rules.evaluate(PoseKind.reach, body), PoseMatch.unknown);
    }
    final legs = sample(PoseKind.oneLeg);
    legs[Joint.leftKnee] = const BodyPoint(100, 100, confidence: 0.4);
    expect(rules.evaluate(PoseKind.oneLeg, legs), PoseMatch.unknown);
  });

  test('distal joints tolerate moderate confidence at difficult angles', () {
    final body = sample(PoseKind.reach);
    final wrist = body[Joint.leftWrist]!;
    body[Joint.leftWrist] = BodyPoint(wrist.x, wrist.y, confidence: 0.4);
    expect(rules.evaluate(PoseKind.reach, body), PoseMatch.match);

    final shoulder = body[Joint.leftShoulder]!;
    body[Joint.leftShoulder] = BodyPoint(
      shoulder.x,
      shoulder.y,
      confidence: 0.4,
    );
    expect(rules.evaluate(PoseKind.reach, body), PoseMatch.unknown);
  });

  test('side-on or tiny bodies are not judged as failed poses', () {
    final body = sample(PoseKind.reach);
    body[Joint.rightShoulder] = const BodyPoint(210, 200);
    expect(rules.evaluate(PoseKind.reach, body), PoseMatch.unknown);
  });
}
