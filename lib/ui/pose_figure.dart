import 'package:flutter/material.dart';
import '../game/pose_rules.dart';
import '../l10n/app_localizations.dart';

// 暗黑调教主题：深黑作为底色，深红承担指令、进度和失败反馈。
const ink = Color(0xFF0D0B0E);
const teal = Color(0xFFD63B52);
const mint = Color(0xFF21161B);
const coral = Color(0xFFF0646C);
const yellow = Color(0xFFE0A94E);
const paper = Color(0xFFF4E9E8);
const muted = Color(0xFFAAA0A3);
const line = Color(0xFF3B252B);

class PoseFigure extends StatelessWidget {
  const PoseFigure({super.key, required this.pose, this.color = teal});
  final PoseKind pose;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: pose.localizedTitle(AppLocalizations.of(context)),
    image: true,
    child: CustomPaint(
      painter: _FigurePainter(pose, color),
      size: const Size(200, 200),
    ),
  );
}

class _FigurePainter extends CustomPainter {
  const _FigurePainter(this.pose, this.color);
  final PoseKind pose;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final scale = size.shortestSide / 200;
    canvas.translate(
      (size.width - 200 * scale) / 2,
      (size.height - 200 * scale) / 2,
    );
    canvas.scale(scale);
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 11
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = color;
    canvas.drawCircle(const Offset(100, 49), 14, fill);
    final bodyBottom = pose == PoseKind.sideLean
        ? const Offset(116, 131)
        : const Offset(100, 131);
    canvas.drawLine(const Offset(100, 77), bodyBottom, stroke);
    canvas.drawLine(const Offset(80, 78), const Offset(120, 78), stroke);
    if (pose == PoseKind.squat) {
      canvas.drawPath(
        Path()
          ..moveTo(bodyBottom.dx, bodyBottom.dy)
          ..lineTo(80, 148)
          ..lineTo(65, 180),
        stroke,
      );
      canvas.drawPath(
        Path()
          ..moveTo(bodyBottom.dx, bodyBottom.dy)
          ..lineTo(120, 148)
          ..lineTo(135, 180),
        stroke,
      );
    } else if (pose == PoseKind.oneLeg) {
      canvas.drawLine(bodyBottom, const Offset(78, 180), stroke);
      canvas.drawPath(
        Path()
          ..moveTo(bodyBottom.dx, bodyBottom.dy)
          ..lineTo(130, 145)
          ..lineTo(151, 126),
        stroke,
      );
    } else {
      canvas.drawLine(bodyBottom, const Offset(73, 180), stroke);
      canvas.drawLine(bodyBottom, const Offset(127, 180), stroke);
    }
    // 图示与识别规则共用同一姿势枚举，避免题目和判定错位。
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
      PoseKind.sideLean => (4, 4),
      PoseKind.oneLeg => (4, 4),
      PoseKind.handsHead => (7, 7),
      PoseKind.squat => (4, 4),
      PoseKind.star => (8, 8),
    };
    void arm(int kind, bool isLeft) {
      Offset point(double x, double y) => Offset(isLeft ? x : 200 - x, y);
      final (elbow, wrist) = switch (kind) {
        0 => (point(65, 48), point(50, 17)),
        1 => (point(49, 78), point(18, 78)),
        2 => (point(48, 78), point(48, 39)),
        3 => (point(54, 106), point(89, 128)),
        4 => (point(93, 110), point(87, 160)),
        5 => (point(62, 102), point(116, 108)),
        7 => (point(58, 65), point(72, 42)),
        8 => (point(59, 56), point(32, 31)),
        _ => (point(67, 101), point(100, 101)),
      };
      canvas.drawPath(
        Path()
          ..moveTo(isLeft ? 80 : 120, 78)
          ..lineTo(elbow.dx, elbow.dy)
          ..lineTo(wrist.dx, wrist.dy),
        stroke,
      );
      canvas.drawCircle(wrist, 6.5, Paint()..color = coral);
    }

    arm(left, true);
    arm(right, false);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_FigurePainter oldDelegate) =>
      pose != oldDelegate.pose || color != oldDelegate.color;
}
