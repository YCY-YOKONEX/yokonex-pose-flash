import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../game/pose_rules.dart';

/// 将 ML Kit 的关节点坐标映射到摄像头预览，并绘制玩家骨架。
class PoseSkeletonPainter extends CustomPainter {
  const PoseSkeletonPainter({
    required this.points,
    required this.frameSize,
    this.mirrorX = true,
  });

  final Map<Joint, BodyPoint> points;
  final Size frameSize;
  final bool mirrorX;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty || frameSize.width <= 0 || frameSize.height <= 0) {
      return;
    }
    final transform = _FrameTransform(frameSize, size, mirrorX: mirrorX);
    final bonePaint = Paint()
      ..color = const Color(0xFFF4E9E8).withValues(alpha: .92)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final jointPaint = Paint()
      ..color = const Color(0xFFF0646C)
      ..style = PaintingStyle.fill;

    void bone(Joint from, Joint to) {
      final start = points[from];
      final end = points[to];
      if (start == null ||
          end == null ||
          start.confidence < 0.15 ||
          end.confidence < 0.15) {
        return;
      }
      canvas.drawLine(transform.point(start), transform.point(end), bonePaint);
    }

    const bones = [
      (Joint.nose, Joint.leftShoulder),
      (Joint.nose, Joint.rightShoulder),
      (Joint.leftShoulder, Joint.rightShoulder),
      (Joint.leftShoulder, Joint.leftElbow),
      (Joint.leftElbow, Joint.leftWrist),
      (Joint.rightShoulder, Joint.rightElbow),
      (Joint.rightElbow, Joint.rightWrist),
      (Joint.leftShoulder, Joint.leftHip),
      (Joint.rightShoulder, Joint.rightHip),
      (Joint.leftHip, Joint.rightHip),
      (Joint.leftHip, Joint.leftKnee),
      (Joint.leftKnee, Joint.leftAnkle),
      (Joint.rightHip, Joint.rightKnee),
      (Joint.rightKnee, Joint.rightAnkle),
    ];
    for (final (from, to) in bones) {
      bone(from, to);
    }

    for (final point in points.values) {
      if (point.confidence < 0.15) continue;
      canvas.drawCircle(transform.point(point), 5, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PoseSkeletonPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.frameSize != frameSize ||
      oldDelegate.mirrorX != mirrorX;
}

class _FrameTransform {
  _FrameTransform(this.frameSize, this.canvasSize, {required this.mirrorX}) {
    _scale = math.min(
      canvasSize.width / frameSize.width,
      canvasSize.height / frameSize.height,
    );
    _offset = Offset(
      (canvasSize.width - frameSize.width * _scale) / 2,
      (canvasSize.height - frameSize.height * _scale) / 2,
    );
  }

  final Size frameSize;
  final Size canvasSize;
  final bool mirrorX;
  late final double _scale;
  late final Offset _offset;

  Offset point(BodyPoint bodyPoint) {
    final x = mirrorX ? frameSize.width - bodyPoint.x : bodyPoint.x;
    return Offset(_offset.dx + x * _scale, _offset.dy + bodyPoint.y * _scale);
  }
}
