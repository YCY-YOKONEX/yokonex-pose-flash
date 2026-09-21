import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../game/pose_rules.dart';

class PoseCamera extends ChangeNotifier {
  PoseCamera({required this.onBody, this.onFrame});
  final void Function(Map<Joint, BodyPoint>) onBody;
  final void Function(Map<Joint, BodyPoint> body, Size? frameSize)? onFrame;
  final _detector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.stream,
    ),
  );
  CameraController? controller;
  String? error;
  bool loading = false;
  bool _disposed = false;
  bool _acceptFrames = false;
  Future<void> _queue = Future.value();
  Future<void>? _processing;
  int _errors = 0;
  Map<Joint, BodyPoint> _smoothedBody = const {};
  int _missingFrames = 0;
  Size? _lastFrameSize;

  // 摄像头启动、关闭串行执行，防止切后台时重复占用同一设备。
  Future<void> open() => _queue = _queue.then((_) => _open());
  Future<void> close() {
    _acceptFrames = false;
    return _queue = _queue.then((_) => _close());
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _open() async {
    if (_disposed) return;
    await _close();
    loading = true;
    error = null;
    _errors = 0;
    _notify();
    try {
      if (!Platform.isAndroid && !Platform.isIOS) {
        throw CameraException('Unsupported', '请在安卓或 iPhone 上运行');
      }
      final cameras = await availableCameras();
      final front = cameras.where(
        (camera) => camera.lensDirection == CameraLensDirection.front,
      );
      if (front.isEmpty) {
        throw CameraException('NoFrontCamera', '未找到前置摄像头');
      }
      final camera = CameraController(
        front.first,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );
      controller = camera;
      await camera.initialize();
      await camera.lockCaptureOrientation(DeviceOrientation.portraitUp);
      if (_disposed) {
        await _close();
        return;
      }
      _acceptFrames = true;
      await camera.startImageStream((image) {
        if (!_acceptFrames || _processing != null || _disposed) return;
        _processing = _detect(
          image,
          camera,
        ).whenComplete(() => _processing = null);
      });
    } on CameraException catch (exception) {
      error = switch (exception.code) {
        'CameraAccessDenied' ||
        'CameraAccessDeniedWithoutPrompt' ||
        'CameraAccessRestricted' => '无法使用摄像头，请在系统设置中允许相机权限',
        'Unsupported' || 'NoFrontCamera' => exception.description,
        _ => '摄像头启动失败，请重试',
      };
      await _close();
    } catch (_) {
      error = '摄像头启动失败，请重试';
      await _close();
    } finally {
      loading = false;
      _notify();
    }
  }

  Future<void> _detect(CameraImage image, CameraController camera) async {
    final started = Stopwatch()..start();
    try {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      final expected = Platform.isAndroid
          ? InputImageFormat.nv21
          : InputImageFormat.bgra8888;
      if (format != expected || image.planes.length != 1) {
        throw StateError('Unsupported camera image format');
      }
      // 画面锁定竖屏，安卓传入传感器角度；iOS 使用原生竖屏缓冲区。
      final rotation = InputImageRotationValue.fromRawValue(
        camera.description.sensorOrientation,
      );
      if (rotation == null) throw StateError('Unsupported camera rotation');
      final rotated =
          Platform.isAndroid && [90, 270].contains(rotation.rawValue);
      final width = rotated ? image.height : image.width;
      final height = rotated ? image.width : image.height;
      final frameSize = Size(width.toDouble(), height.toDouble());
      final plane = image.planes.single;
      final poses = await _detector.processImage(
        InputImage.fromBytes(
          bytes: plane.bytes,
          metadata: InputImageMetadata(
            size: Size(image.width.toDouble(), image.height.toDouble()),
            rotation: rotation,
            format: expected,
            bytesPerRow: plane.bytesPerRow,
          ),
        ),
      );
      if (!_acceptFrames || _disposed) return;
      _errors = 0;
      if (started.elapsedMilliseconds > 800 || poses.length != 1) {
        _emitMissingFrame(frameSize);
        return;
      }
      final body = <Joint, BodyPoint>{};
      for (final joint in Joint.values) {
        final type = PoseLandmarkType.values.byName(joint.name);
        final point = poses.single.landmarks[type];
        if (point == null) continue;
        // 手脚靠近边缘时坐标可能轻微越界，保留少量容差避免骨架突然缺失。
        final marginX = width * 0.05;
        final marginY = height * 0.05;
        final inside =
            point.x >= -marginX &&
            point.y >= -marginY &&
            point.x < width + marginX &&
            point.y < height + marginY;
        body[joint] = BodyPoint(
          point.x,
          point.y,
          confidence: inside ? point.likelihood : 0,
        );
      }
      final smoothedBody = _smoothBody(body);
      _lastFrameSize = frameSize;
      onFrame?.call(smoothedBody, frameSize);
      onBody(body);
    } catch (_) {
      if (!_acceptFrames || _disposed) return;
      _emitMissingFrame(null);
      _errors++;
      if (_errors >= 5) {
        error = '动作识别暂不可用，请重新启动摄像头';
        _acceptFrames = false;
        _notify();
      }
    }
  }

  Map<Joint, BodyPoint> _smoothBody(Map<Joint, BodyPoint> body) {
    final smoothed = <Joint, BodyPoint>{};
    for (final joint in Joint.values) {
      final current = body[joint];
      final previous = _smoothedBody[joint];
      if (current == null) {
        if (previous != null) {
          final confidence = previous.confidence * 0.55;
          if (confidence >= 0.15) {
            smoothed[joint] = BodyPoint(
              previous.x,
              previous.y,
              confidence: confidence,
            );
          }
        }
        continue;
      }
      if (previous == null) {
        smoothed[joint] = current;
        continue;
      }
      // 低置信度关节点使用更强平滑，高置信度关节点保持动作响应速度。
      final alpha = (0.35 + current.confidence * 0.35).clamp(0.35, 0.7);
      smoothed[joint] = BodyPoint(
        previous.x + (current.x - previous.x) * alpha,
        previous.y + (current.y - previous.y) * alpha,
        confidence: current.confidence,
      );
    }
    _missingFrames = 0;
    _smoothedBody = Map.unmodifiable(smoothed);
    return _smoothedBody;
  }

  void _emitMissingFrame(Size? frameSize) {
    _missingFrames++;
    if (_missingFrames <= 2 && _smoothedBody.isNotEmpty) {
      onFrame?.call(_smoothedBody, frameSize ?? _lastFrameSize);
    } else {
      _smoothedBody = const {};
      onFrame?.call(const {}, frameSize ?? _lastFrameSize);
    }
    onBody({});
  }

  Future<void> _close() async {
    _acceptFrames = false;
    _smoothedBody = const {};
    _missingFrames = 0;
    _lastFrameSize = null;
    onFrame?.call(const {}, null);
    final camera = controller;
    controller = null;
    _notify();
    try {
      if (camera != null && camera.value.isStreamingImages) {
        await camera.stopImageStream();
      }
    } catch (_) {
      // 系统可能已经释放了退到后台的摄像头，仍继续清理其余资源。
    }
    await _processing;
    try {
      await camera?.dispose();
    } catch (_) {
      // 已失效的原生相机句柄无需再次关闭。
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(close().then((_) => _detector.close()).catchError((Object _) {}));
    super.dispose();
  }
}
