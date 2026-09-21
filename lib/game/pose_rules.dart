import 'dart:math' as math;
import '../l10n/app_localizations.dart';

enum PoseKind {
  reach,
  wings,
  goalpost,
  hips,
  reachWing,
  reachHip,
  down,
  cross,
  clap,
  wingGoalpost,
  wingHip,
  reachGoalpost,
  singleReach,
  sideLean,
  oneLeg,
  handsHead,
  squat,
  star,
}

/// 随机题库只使用容易摆出、容易识别的自然动作。
/// 保留大部分多手臂组合，只移除“举高+投降”和“平举+投降”两种最容易扭曲的组合。
const playablePoseKinds = <PoseKind>[
  PoseKind.reach,
  PoseKind.wings,
  PoseKind.goalpost,
  PoseKind.hips,
  PoseKind.reachWing,
  PoseKind.reachHip,
  PoseKind.down,
  PoseKind.cross,
  PoseKind.clap,
  PoseKind.wingHip,
  PoseKind.singleReach,
  PoseKind.sideLean,
  PoseKind.oneLeg,
  PoseKind.handsHead,
  PoseKind.squat,
  PoseKind.star,
];

extension PoseDescription on PoseKind {
  String localizedTitle(AppLocalizations l10n) =>
      l10n.pose('pose${name[0].toUpperCase()}${name.substring(1)}');

  String get title => switch (this) {
    PoseKind.reach => '双手举高',
    PoseKind.wings => '双臂平举',
    PoseKind.goalpost => '双臂投降',
    PoseKind.hips => '双手叉腰',
    PoseKind.reachWing => '一手举高，一手平举',
    PoseKind.reachHip => '一手举高，一手叉腰',
    PoseKind.down => '双臂自然下垂',
    PoseKind.cross => '双手抱胸',
    PoseKind.clap => '双手合十',
    PoseKind.wingGoalpost => '一手平举，一手投降',
    PoseKind.wingHip => '一手平举，一手叉腰',
    PoseKind.reachGoalpost => '一手举高，一手投降',
    PoseKind.singleReach => '单手举高',
    PoseKind.sideLean => '向侧面倾斜',
    PoseKind.oneLeg => '单腿抬起',
    PoseKind.handsHead => '双手抱头',
    PoseKind.squat => '半蹲',
    PoseKind.star => '星形站姿',
  };
}

enum Joint {
  nose,
  leftShoulder,
  rightShoulder,
  leftElbow,
  rightElbow,
  leftWrist,
  rightWrist,
  leftHip,
  rightHip,
  leftKnee,
  rightKnee,
  leftAnkle,
  rightAnkle,
}

class BodyPoint {
  const BodyPoint(this.x, this.y, {this.confidence = 1});
  final double x;
  final double y;
  final double confidence;
}

enum PoseMatch { unknown, mismatch, match }

class PoseRules {
  const PoseRules();

  PoseMatch evaluate(PoseKind target, Map<Joint, BodyPoint> points) {
    // 只检查当前动作需要的关节。上半身动作不应因腿部暂时出画而误判失败。
    final requiredJoints = <Joint>[
      Joint.nose,
      Joint.leftShoulder,
      Joint.rightShoulder,
      Joint.leftHip,
      Joint.rightHip,
      if (target != PoseKind.sideLean && target != PoseKind.squat) ...[
        Joint.leftElbow,
        Joint.rightElbow,
        Joint.leftWrist,
        Joint.rightWrist,
      ],
      if (target == PoseKind.oneLeg || target == PoseKind.squat) ...[
        Joint.leftKnee,
        Joint.rightKnee,
        Joint.leftAnkle,
        Joint.rightAnkle,
      ],
    ];
    for (final joint in requiredJoints) {
      final point = points[joint];
      if (point == null ||
          !point.confidence.isFinite ||
          point.confidence < _minimumConfidence(joint) ||
          !point.x.isFinite ||
          !point.y.isFinite) {
        return PoseMatch.unknown;
      }
    }
    final ls = points[Joint.leftShoulder]!;
    final rs = points[Joint.rightShoulder]!;
    final lh = points[Joint.leftHip]!;
    final rh = points[Joint.rightHip]!;
    final width = _distance(ls, rs);
    final torso = ((lh.y + rh.y) - (ls.y + rs.y)) / 2;
    if (width < 20 || torso < 20 || width < torso * 0.45) {
      return PoseMatch.unknown;
    }
    final left = _Arm(
      ls,
      points[Joint.leftElbow] ?? ls,
      points[Joint.leftWrist] ?? ls,
      lh,
      width,
      ls.x < rs.x ? -1 : 1,
    );
    final right = _Arm(
      rs,
      points[Joint.rightElbow] ?? rs,
      points[Joint.rightWrist] ?? rs,
      rh,
      width,
      rs.x < ls.x ? -1 : 1,
    );
    final leftKnee = points[Joint.leftKnee];
    final rightKnee = points[Joint.rightKnee];
    final leftAnkle = points[Joint.leftAnkle];
    final rightAnkle = points[Joint.rightAnkle];
    // 用肩宽归一化，减少玩家距离摄像头远近造成的影响。
    final matched = switch (target) {
      PoseKind.reach => left.raised && right.raised,
      PoseKind.wings => left.horizontal && right.horizontal,
      PoseKind.goalpost => left.bentUp && right.bentUp,
      PoseKind.hips => left.onHip && right.onHip,
      // 非对称姿势接受左右镜像，玩家跟随前置预览即可。
      PoseKind.reachWing =>
        (left.raised && right.horizontal) || (right.raised && left.horizontal),
      PoseKind.reachHip =>
        (left.raised && right.onHip) || (right.raised && left.onHip),
      PoseKind.down => left.down && right.down,
      PoseKind.cross => left.crossesTo(rs, width) && right.crossesTo(ls, width),
      PoseKind.clap => _handsTogether(left, right, width),
      PoseKind.wingGoalpost =>
        (left.horizontal && right.bentUp) || (right.horizontal && left.bentUp),
      PoseKind.wingHip =>
        (left.horizontal && right.onHip) || (right.horizontal && left.onHip),
      PoseKind.reachGoalpost =>
        (left.raised && right.bentUp) || (right.raised && left.bentUp),
      PoseKind.singleReach =>
        (left.raised && right.down) || (right.raised && left.down),
      PoseKind.sideLean => _sideLean(ls, rs, lh, rh, width),
      PoseKind.oneLeg => _oneLegRaised(
        lh,
        rh,
        leftKnee!,
        rightKnee!,
        leftAnkle!,
        rightAnkle!,
        width,
      ),
      PoseKind.handsHead => left.nearHead && right.nearHead,
      PoseKind.squat => _isSquat(
        lh,
        rh,
        leftKnee!,
        rightKnee!,
        leftAnkle!,
        rightAnkle!,
        width,
      ),
      PoseKind.star => left.diagonalUp && right.diagonalUp,
    };
    return matched ? PoseMatch.match : PoseMatch.mismatch;
  }
}

double _minimumConfidence(Joint joint) => switch (joint) {
  // 手腕和脚踝在侧身、抬腿时最容易降低置信度，适当放宽但仍拒绝明显误点。
  Joint.leftWrist ||
  Joint.rightWrist ||
  Joint.leftAnkle ||
  Joint.rightAnkle => 0.35,
  Joint.leftElbow ||
  Joint.rightElbow ||
  Joint.leftKnee ||
  Joint.rightKnee => 0.45,
  Joint.nose => 0.45,
  Joint.leftShoulder ||
  Joint.rightShoulder ||
  Joint.leftHip ||
  Joint.rightHip => 0.55,
};

bool _sideLean(
  BodyPoint leftShoulder,
  BodyPoint rightShoulder,
  BodyPoint leftHip,
  BodyPoint rightHip,
  double scale,
) {
  final shoulderCenter = (leftShoulder.x + rightShoulder.x) / 2;
  final hipCenter = (leftHip.x + rightHip.x) / 2;
  final verticalSpan =
      ((leftHip.y + rightHip.y) - (leftShoulder.y + rightShoulder.y)) / 2;
  return (shoulderCenter - hipCenter).abs() > scale * 0.28 &&
      verticalSpan > scale * 0.7;
}

bool _oneLegRaised(
  BodyPoint leftHip,
  BodyPoint rightHip,
  BodyPoint leftKnee,
  BodyPoint rightKnee,
  BodyPoint leftAnkle,
  BodyPoint rightAnkle,
  double scale,
) {
  final leftRaised =
      leftKnee.y < leftHip.y - scale * 0.2 &&
      leftAnkle.y < rightAnkle.y - scale * 0.12;
  final rightRaised =
      rightKnee.y < rightHip.y - scale * 0.2 &&
      rightAnkle.y < leftAnkle.y - scale * 0.12;
  return leftRaised != rightRaised;
}

bool _isSquat(
  BodyPoint leftHip,
  BodyPoint rightHip,
  BodyPoint leftKnee,
  BodyPoint rightKnee,
  BodyPoint leftAnkle,
  BodyPoint rightAnkle,
  double scale,
) {
  final leftAngle = _jointAngle(leftHip, leftKnee, leftAnkle);
  final rightAngle = _jointAngle(rightHip, rightKnee, rightAnkle);
  return leftAngle > 65 &&
      leftAngle < 155 &&
      rightAngle > 65 &&
      rightAngle < 155 &&
      leftKnee.y > leftHip.y + scale * 0.08 &&
      rightKnee.y > rightHip.y + scale * 0.08;
}

double _jointAngle(BodyPoint first, BodyPoint vertex, BodyPoint last) {
  final a = _distance(first, vertex);
  final b = _distance(last, vertex);
  if (a * b == 0) return 0;
  final cosine =
      ((first.x - vertex.x) * (last.x - vertex.x) +
          (first.y - vertex.y) * (last.y - vertex.y)) /
      (a * b);
  return math.acos(cosine.clamp(-1, 1)) * 180 / math.pi;
}

bool _handsTogether(_Arm left, _Arm right, double scale) =>
    _distance(left.wrist, right.wrist) < scale * 0.55 &&
    left.wrist.y > left.shoulder.y &&
    left.wrist.y < left.hip.y - scale * 0.35 &&
    right.wrist.y > right.shoulder.y &&
    right.wrist.y < right.hip.y - scale * 0.35 &&
    left.elbow.y > left.shoulder.y &&
    right.elbow.y > right.shoulder.y;

double _distance(BodyPoint a, BodyPoint b) =>
    math.sqrt(math.pow(a.x - b.x, 2) + math.pow(a.y - b.y, 2));

class _Arm {
  const _Arm(
    this.shoulder,
    this.elbow,
    this.wrist,
    this.hip,
    this.scale,
    this.outward,
  );
  final BodyPoint shoulder;
  final BodyPoint elbow;
  final BodyPoint wrist;
  final BodyPoint hip;
  final double scale;
  final int outward;

  double get angle {
    final a = _distance(shoulder, elbow);
    final b = _distance(wrist, elbow);
    if (a * b == 0) return 0;
    final cosine =
        ((shoulder.x - elbow.x) * (wrist.x - elbow.x) +
            (shoulder.y - elbow.y) * (wrist.y - elbow.y)) /
        (a * b);
    return math.acos(cosine.clamp(-1, 1)) * 180 / math.pi;
  }

  bool get raised =>
      wrist.y < shoulder.y - scale * 0.75 &&
      elbow.y < shoulder.y - scale * 0.2 &&
      angle > 140;
  bool get horizontal =>
      (wrist.y - shoulder.y).abs() < scale * 0.3 &&
      (elbow.y - shoulder.y).abs() < scale * 0.3 &&
      (wrist.x - shoulder.x) * outward > scale * 0.85 &&
      angle > 150;
  bool get diagonalUp =>
      wrist.y < shoulder.y - scale * 0.35 &&
      wrist.y > shoulder.y - scale * 0.95 &&
      elbow.y < shoulder.y - scale * 0.1 &&
      (wrist.x - shoulder.x) * outward > scale * 0.55 &&
      angle > 145;
  bool get bentUp =>
      (elbow.y - shoulder.y).abs() < scale * 0.35 &&
      (elbow.x - shoulder.x) * outward > scale * 0.35 &&
      wrist.y < elbow.y - scale * 0.4 &&
      angle > 55 &&
      angle < 120;
  bool get onHip =>
      _distance(wrist, hip) < scale * 0.45 &&
      (elbow.x - shoulder.x) * outward > scale * 0.25 &&
      elbow.y > shoulder.y + scale * 0.2 &&
      angle < 120;
  bool get down =>
      wrist.y > shoulder.y + scale * 0.65 &&
      (wrist.x - shoulder.x).abs() < scale * 0.75 &&
      elbow.y > shoulder.y + scale * 0.25 &&
      angle > 145;

  bool get nearHead =>
      wrist.y < shoulder.y - scale * 0.25 &&
      (wrist.x - shoulder.x) * outward > scale * 0.05 &&
      _distance(wrist, shoulder) < scale * 0.7;

  bool crossesTo(BodyPoint oppositeShoulder, double bodyScale) =>
      _distance(wrist, oppositeShoulder) < bodyScale * 0.7 &&
      wrist.y > shoulder.y &&
      wrist.y < hip.y - bodyScale * 0.25 &&
      elbow.y > shoulder.y + bodyScale * 0.1 &&
      angle > 35 &&
      angle < 150;
}
