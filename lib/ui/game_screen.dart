import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../camera/pose_camera.dart';
import '../ems/ems_connection.dart';
import '../ems/ems_protocol.dart';
import '../ems/ems_service.dart';
import '../game/challenge.dart';
import '../game/pose_rules.dart';
import '../l10n/app_localizations.dart';
import 'pose_figure.dart';
import 'pose_skeleton.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.settings});
  final GameSettings settings;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late final Challenge _game = Challenge(widget.settings);
  late final PoseCamera _camera;
  // 失败惩罚固定启用，设备未连接时由控制层报错并跳过本次发送。
  // 复用首页和设备页的连接，避免进入挑战后重新扫描设备。
  late final EmsController _ems = EmsConnectionStore.instance.controller;
  final _clock = Stopwatch();
  Timer? _timer;
  bool _foreground = true;
  bool _leaving = false;
  bool _allowPop = false;
  int? _penaltyTriggeredForRound;
  bool _penaltyInFlight = false;
  String? _penaltyError;
  Map<Joint, BodyPoint> _body = const {};
  Size? _bodyFrameSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock.start();
    _keepAwake(true);
    _game.start(_clock.elapsed);
    _camera = PoseCamera(
      onFrame: (body, frameSize) {
        if (!mounted) return;
        _body = body;
        _bodyFrameSize = frameSize;
      },
      onBody: (body) {
        if (!mounted || !_foreground || _leaving) return;
        final previousPhase = _game.phase;
        _game.observe(
          const PoseRules().evaluate(_game.target, body),
          _clock.elapsed,
        );
        _handleGameChange(previousPhase);
      },
    )..addListener(_cameraChanged);
    unawaited(_camera.open());
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || !_foreground || _leaving) return;
      final previousPhase = _game.phase;
      _game.tick(_clock.elapsed);
      _handleGameChange(previousPhase);
    });
  }

  // 摄像头帧和定时器都可能推进游戏状态，统一处理惩罚和界面刷新。
  void _handleGameChange(GamePhase previousPhase) {
    if (!mounted) return;
    if (previousPhase != GamePhase.penalty &&
        _game.phase == GamePhase.penalty) {
      unawaited(_triggerPenalty());
    }
    setState(() {});
    if (_game.phase == GamePhase.finished) {
      _timer?.cancel();
      _keepAwake(false);
      unawaited(_camera.close());
    }
  }

  void _cameraChanged() {
    if (!mounted) return;
    if (_camera.error != null) _game.pause();
    setState(() {});
  }

  void _keepAwake(bool enabled) {
    unawaited(
      WakelockPlus.toggle(enable: enabled).catchError((Object error) {
        debugPrint('Screen wake lock unavailable: $error');
      }),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 来电、锁屏及切后台统一暂停；返回后等待玩家主动继续。
    _foreground = state == AppLifecycleState.resumed;
    _keepAwake(_foreground && _game.phase != GamePhase.finished);
    if (!_foreground) {
      _game.pause();
      unawaited(_camera.close());
    } else if (!_leaving && _game.phase != GamePhase.finished) {
      unawaited(_camera.open());
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _clock.stop();
    _keepAwake(false);
    _camera.removeListener(_cameraChanged);
    _camera.dispose();
    super.dispose();
  }

  Future<void> _triggerPenalty() async {
    if (_penaltyTriggeredForRound == _game.round || _penaltyInFlight) {
      return;
    }
    _penaltyTriggeredForRound = _game.round;
    _penaltyInFlight = true;
    _penaltyError = null;
    final l10n = AppLocalizations.of(context);
    // 失败次数从 1 开始，每次按设置叠加强度，最终仍限制在 180。
    final intensity =
        (widget.settings.emsBaseIntensity +
                (_game.failed - 1) * widget.settings.emsFailureIncrement)
            .clamp(0, 180);
    try {
      await _ems.playPenalty(
        generation: widget.settings.emsGeneration,
        uiIntensity: intensity,
      );
    } catch (error) {
      _penaltyError = l10n.noDevicePenalty;
      debugPrint('EMS 惩罚未执行: $error');
    } finally {
      // 波形结束或发送失败后自动进入下一轮，不再要求玩家手动确认。
      _penaltyInFlight = false;
      if (mounted) {
        final previousPhase = _game.phase;
        if (!_leaving && _game.phase == GamePhase.penalty) {
          _game.acknowledgePenalty(_clock.elapsed);
        }
        _handleGameChange(previousPhase);
      }
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    final wasActive = [
      GamePhase.countdown,
      GamePhase.playing,
      GamePhase.success,
    ].contains(_game.phase);
    _game.pause();
    setState(() {});
    _leaving = true;
    final confirmed =
        _game.phase == GamePhase.finished ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(AppLocalizations.of(context).endChallengeQuestion),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text(AppLocalizations.of(context).stay),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(AppLocalizations.of(context).endChallenge),
                  ),
                ],
              ),
            ) ==
            true;
    if (!mounted) return;
    if (confirmed) {
      setState(() => _allowPop = true);
      await _camera.close();
      if (mounted) Navigator.pop(context);
    } else {
      if (wasActive && _game.phase == GamePhase.paused) {
        // 用户取消退出时恢复弹窗前的倒计时或挑战状态。
        _game.resume(_clock.elapsed);
      }
      setState(() => _leaving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _allowPop,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) unawaited(_leave());
    },
    child: Scaffold(
      backgroundColor: ink,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Expanded(child: _preview()),
              if (_camera.error == null)
                SafeArea(top: false, child: _targetBand()),
            ],
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    _topIcon(
                      tooltip: AppLocalizations.of(context).endChallenge,
                      icon: Icons.close_rounded,
                      onPressed: _leave,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${_game.round.toString().padLeft(2, '0')} / ${AppLocalizations.of(context).rounds(_game.settings.rounds)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          shadows: [Shadow(blurRadius: 8)],
                        ),
                      ),
                    ),
                    _topIcon(
                      tooltip: AppLocalizations.of(context).pause,
                      icon: Icons.pause_rounded,
                      onPressed:
                          [
                            GamePhase.countdown,
                            GamePhase.playing,
                            GamePhase.success,
                          ].contains(_game.phase)
                          ? () => setState(_game.pause)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_camera.error == null) _targetOverlay(),
          if (_camera.error != null)
            _overlay(
              icon: Icons.videocam_off_outlined,
              title: AppLocalizations.of(context).cameraNotReady,
              text: AppLocalizations.of(
                context,
              ).translateCameraError(_camera.error!),
              action: AppLocalizations.of(context).retry,
              onAction: () => unawaited(_camera.open()),
            )
          else if (_game.phase == GamePhase.paused)
            _overlay(
              icon: Icons.pause_circle_outline,
              title: AppLocalizations.of(context).challengePaused,
              action: AppLocalizations.of(context).continueChallenge,
              onAction: _camera.loading
                  ? null
                  : () => setState(() => _game.resume(_clock.elapsed)),
            )
          else if (_game.phase == GamePhase.penalty)
            _overlay(
              icon: Icons.bolt_rounded,
              title: _penaltyInFlight
                  ? AppLocalizations.of(context).emsPenaltyRunning
                  : _penaltyError == null
                  ? AppLocalizations.of(context).emsPenaltyCompleted
                  : AppLocalizations.of(context).challengeFailed,
              text: _penaltyInFlight
                  ? AppLocalizations.of(context).waitPenalty
                  : _penaltyError ??
                        '${widget.settings.emsGeneration.deviceName} · ${AppLocalizations.of(context).emsPenaltyCompleted}',
              action: _penaltyInFlight
                  ? AppLocalizations.of(context).waitPenalty
                  : _game.round == _game.settings.rounds
                  ? AppLocalizations.of(context).finishSeeResult
                  : AppLocalizations.of(context).finishContinue,
              onAction: _penaltyInFlight
                  ? null
                  : () => setState(
                      () => _game.acknowledgePenalty(_clock.elapsed),
                    ),
            )
          else if (_game.phase == GamePhase.finished)
            _overlay(
              icon: Icons.emoji_events_outlined,
              title: AppLocalizations.of(context).challengeComplete,
              text: AppLocalizations.of(
                context,
              ).result(_game.passed, _game.failed),
              action: AppLocalizations.of(context).back,
              onAction: _leave,
            ),
        ],
      ),
    ),
  );

  Widget _preview() {
    final camera = _camera.controller;
    if (camera == null || !camera.value.isInitialized) {
      return const Center(child: CircularProgressIndicator(color: teal));
    }
    // 预览完整保留原始取景范围，不裁掉识别所需的手腕和髋部。
    final showTargetGhost = [
      GamePhase.countdown,
      GamePhase.playing,
    ].contains(_game.phase);
    return Center(
      child: AspectRatio(
        aspectRatio: 1 / camera.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview(camera),
            if (showTargetGhost)
              IgnorePointer(
                child: Opacity(
                  opacity: .28,
                  child: Center(
                    child: SizedBox(
                      width: 250,
                      height: 300,
                      child: PoseFigure(
                        pose: _game.target,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            if (_body.isNotEmpty && _bodyFrameSize != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: PoseSkeletonPainter(
                      points: _body,
                      frameSize: _bodyFrameSize!,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _targetOverlay() {
    final remaining = (_game.remaining.inMilliseconds / 1000).toStringAsFixed(
      1,
    );
    final timerColor = _game.remaining.inSeconds < 2 ? coral : Colors.white;
    return Positioned(
      top: 94,
      left: 28,
      right: 28,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 目标区域直接展示动作示意，玩家无需只看文字猜动作。
          DecoratedBox(
            decoration: BoxDecoration(
              color: mint.withValues(alpha: .94),
              border: Border.all(color: line),
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              width: 78,
              height: 88,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: PoseFigure(pose: _game.target, color: paper),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).targetPose,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .14,
                    shadows: [Shadow(blurRadius: 8)],
                  ),
                ),
                if (_game.isCombo) ...[
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).combo(_game.sequenceStep, _game.sequenceLength),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _game.target.localizedTitle(AppLocalizations.of(context)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -.06,
                    shadows: [Shadow(blurRadius: 10)],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            remaining,
            style: TextStyle(
              color: timerColor,
              fontSize: 50,
              fontWeight: FontWeight.w900,
              height: .92,
              letterSpacing: -.08,
              fontFeatures: const [FontFeature.tabularFigures()],
              shadows: const [Shadow(blurRadius: 10)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _topIcon({
    required String tooltip,
    required IconData icon,
    required VoidCallback? onPressed,
  }) => DecoratedBox(
    decoration: BoxDecoration(
      color: mint.withValues(alpha: .94),
      border: Border.all(color: line),
      shape: BoxShape.circle,
      boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
    ),
    child: IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: paper,
      icon: Icon(icon),
    ),
  );

  Widget _targetBand() {
    final phase = _game.phase;
    final status = switch (phase) {
      GamePhase.success => AppLocalizations.of(context).poseSuccess,
      GamePhase.countdown =>
        _game.tracking
            ? AppLocalizations.of(context).countdown(_game.countdown)
            : AppLocalizations.of(context).waitingForPlayer,
      GamePhase.playing =>
        !_game.tracking
            ? AppLocalizations.of(context).getInFrame
            : _game.observation == PoseMatch.match
            ? AppLocalizations.of(context).holdStill
            : AppLocalizations.of(context).keepAdjusting,
      GamePhase.paused => AppLocalizations.of(context).challengePaused,
      _ => AppLocalizations.of(context).actionStatus,
    };
    final statusColor = phase == GamePhase.success ? coral : paper;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 184),
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 30),
      decoration: const BoxDecoration(
        color: mint,
        border: Border(top: BorderSide(color: line)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 78,
                height: 90,
                child: PoseFigure(pose: _game.target, color: paper),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context).actionStatus,
                      style: TextStyle(
                        color: teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .08,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _holdValue(),
            ],
          ),
          const SizedBox(height: 13),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: phase == GamePhase.success ? 1 : _game.holdProgress,
              minHeight: 7,
              color: phase == GamePhase.success ? coral : teal,
              backgroundColor: line,
            ),
          ),
        ],
      ),
    );
  }

  Widget _holdValue() {
    final value = _game.phase == GamePhase.success
        ? '✓'
        : '${(_game.holdProgress * 100).round()}%';
    return Text(
      value,
      style: TextStyle(
        color: _game.phase == GamePhase.success ? coral : paper,
        fontSize: 22,
        fontWeight: FontWeight.w900,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _overlay({
    required IconData icon,
    required String title,
    String? text,
    required String action,
    required VoidCallback? onAction,
  }) => ColoredBox(
    color: ink,
    child: SafeArea(
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: IconButton(
                tooltip: AppLocalizations.of(context).endChallenge,
                onPressed: _leave,
                color: paper,
                icon: const Icon(Icons.close),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DecoratedBox(
                        decoration: const BoxDecoration(
                          color: teal,
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(15),
                          child: Icon(icon, color: ink, size: 34),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: paper,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (text != null) ...[
                        const SizedBox(height: 18),
                        Text(
                          text,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: muted,
                            fontSize: 20,
                            height: 1.6,
                          ),
                        ),
                      ],
                      const SizedBox(height: 36),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: teal,
                            foregroundColor: paper,
                          ),
                          onPressed: onAction,
                          child: Text(action, textAlign: TextAlign.center),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
