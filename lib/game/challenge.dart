import 'dart:math';
import '../ems/ems_protocol.dart';
import 'pose_rules.dart';

const defaultPenalties = [
  '用播音腔介绍一下自己',
  '说出自己三个优点',
  '模仿机器人说一句话',
  '唱一句喜欢的歌',
  '给自己起一个超级英雄名字',
  '用三个词形容今天的心情',
];

class GameSettings {
  const GameSettings({
    this.roundSeconds = 5,
    this.rounds = 10,
    this.penalties = defaultPenalties,
    this.emsGeneration = EmsDeviceGeneration.second,
    this.emsBaseIntensity = 30,
    this.emsFailureIncrement = 10,
  });
  final int roundSeconds;
  final int rounds;
  final List<String> penalties;
  final EmsDeviceGeneration emsGeneration;
  final int emsBaseIntensity;
  final int emsFailureIncrement;

  // 每轮时间越长，候选姿势越多；最多使用完整姿势库，避免额外配置项。
  int get poseCount => (roundSeconds * 2).clamp(3, playablePoseKinds.length);

  GameSettings copyWith({
    int? roundSeconds,
    int? rounds,
    List<String>? penalties,
    EmsDeviceGeneration? emsGeneration,
    int? emsBaseIntensity,
    int? emsFailureIncrement,
  }) => GameSettings(
    roundSeconds: roundSeconds ?? this.roundSeconds,
    rounds: rounds ?? this.rounds,
    penalties: penalties ?? this.penalties,
    emsGeneration: emsGeneration ?? this.emsGeneration,
    emsBaseIntensity: emsBaseIntensity ?? this.emsBaseIntensity,
    emsFailureIncrement: emsFailureIncrement ?? this.emsFailureIncrement,
  );

  GameSettings validated() => GameSettings(
    roundSeconds: roundSeconds.clamp(3, 10),
    rounds: [5, 10, 20].contains(rounds) ? rounds : 10,
    penalties: penalties.any((text) => text.trim().isNotEmpty)
        ? penalties
              .map((text) => text.trim())
              .where((text) => text.isNotEmpty)
              .toList()
        : defaultPenalties,
    emsGeneration: emsGeneration,
    emsBaseIntensity: emsBaseIntensity.clamp(0, EmsProtocol.maxUiIntensity),
    emsFailureIncrement: emsFailureIncrement.clamp(
      0,
      EmsProtocol.maxUiIntensity,
    ),
  );
}

enum GamePhase { ready, countdown, playing, success, penalty, paused, finished }

class Challenge {
  Challenge(GameSettings settings, {Random? random})
    : settings = settings.validated(),
      _random = random ?? Random();
  final GameSettings settings;
  final Random _random;
  List<PoseKind> _posePool = const [];
  List<PoseKind> _roundTargets = const [];
  int _sequenceIndex = 0;
  static const holdRequired = Duration(milliseconds: 800);
  static const freshness = Duration(milliseconds: 750);
  GamePhase phase = GamePhase.ready;
  GamePhase _resumePhase = GamePhase.ready;
  PoseKind target = PoseKind.reach;
  int round = 0;
  int passed = 0;
  int failed = 0;
  Duration remaining = Duration.zero;
  Duration hold = Duration.zero;
  Duration _transition = Duration.zero;
  Duration? _lastTick;
  Duration? _lastObservation;
  PoseMatch observation = PoseMatch.unknown;

  bool get tracking => observation != PoseMatch.unknown;
  List<PoseKind> get sequence => List.unmodifiable(_roundTargets);
  int get sequenceStep => _roundTargets.isEmpty ? 0 : _sequenceIndex + 1;
  int get sequenceLength => _roundTargets.length;
  bool get isCombo => sequenceLength > 1;
  int get roundTimeLimitSeconds {
    if (settings.rounds < 10 || settings.rounds == 1) {
      return settings.roundSeconds;
    }
    final span = settings.roundSeconds - 3;
    final reduction = span == 0
        ? 0
        : ((round - 1) * span ~/ (settings.rounds - 1));
    return (settings.roundSeconds - reduction).clamp(3, 10);
  }

  double get holdProgress =>
      (hold.inMilliseconds / holdRequired.inMilliseconds).clamp(0, 1);
  int get countdown => (_transition.inMilliseconds / 1000).ceil();

  void start(Duration now) {
    if (phase != GamePhase.ready) return;
    _nextRound(now);
  }

  void _nextRound(Duration now) {
    if (round >= settings.rounds) {
      phase = GamePhase.finished;
      return;
    }
    if (round == 0) {
      // 根据每轮时间自动决定候选姿势数量，具体姿势从完整姿势库中随机抽取。
      _posePool = playablePoseKinds.toList()..shuffle(_random);
      _posePool = _posePool.take(settings.poseCount).toList();
    }
    final currentRound = round + 1;
    final comboStart = settings.rounds >= 10
        ? (settings.rounds * 0.6).ceil()
        : settings.rounds + 1;
    final comboLength = currentRound >= comboStart ? 2 : 1;
    final choices = _posePool
        .where((value) => round == 0 || value != target)
        .toList();
    _roundTargets = <PoseKind>[];
    var previous = round == 0 ? null : target;
    for (var index = 0; index < comboLength; index++) {
      final available = choices.where((value) => value != previous).toList();
      final source = available.isEmpty ? choices : available;
      final next = source[_random.nextInt(source.length)];
      _roundTargets.add(next);
      previous = next;
    }
    _sequenceIndex = 0;
    target = _roundTargets.first;
    round++;
    remaining = Duration(seconds: roundTimeLimitSeconds);
    _transition = const Duration(seconds: 3);
    hold = Duration.zero;
    observation = PoseMatch.unknown;
    _lastObservation = null;
    _lastTick = now;
    phase = GamePhase.countdown;
  }

  void observe(PoseMatch result, Duration now) {
    if (phase != GamePhase.playing && phase != GamePhase.countdown) return;
    // 先结算旧观测，再接收新帧，避免将新帧结果倒算到过去。
    tick(now);
    if (phase != GamePhase.playing && phase != GamePhase.countdown) return;
    if (result != PoseMatch.match || observation != PoseMatch.match) {
      hold = Duration.zero;
    }
    observation = result;
    _lastObservation = now;
  }

  void tick(Duration now) {
    final previous = _lastTick;
    _lastTick = now;
    if (previous == null || now <= previous) return;
    final elapsed = now - previous;
    if (phase == GamePhase.success) {
      _transition -= elapsed;
      if (_transition <= Duration.zero) _nextRound(now);
      return;
    }
    if (phase != GamePhase.countdown && phase != GamePhase.playing) return;
    // 识别停滞、应用卡顿、人体出画时冻结计时并清空保持进度。
    if (_lastObservation == null ||
        now - _lastObservation! > freshness ||
        elapsed > const Duration(milliseconds: 500)) {
      observation = PoseMatch.unknown;
      hold = Duration.zero;
      return;
    }
    if (!tracking) return;
    if (phase == GamePhase.countdown) {
      _transition -= elapsed;
      if (_transition <= Duration.zero) {
        phase = GamePhase.playing;
        hold = Duration.zero;
      }
      return;
    }
    final activeTime = elapsed > remaining ? remaining : elapsed;
    remaining -= activeTime;
    if (observation == PoseMatch.match) {
      hold += activeTime;
      if (hold >= holdRequired) {
        if (_sequenceIndex + 1 < _roundTargets.length) {
          // 连续动作切换时清空旧动作观测，必须重新保持下一动作。
          _sequenceIndex++;
          target = _roundTargets[_sequenceIndex];
          hold = Duration.zero;
          observation = PoseMatch.unknown;
          _lastObservation = null;
        } else {
          passed++;
          phase = GamePhase.success;
          _transition = const Duration(milliseconds: 1200);
        }
        return;
      }
    }
    if (remaining <= Duration.zero) {
      failed++;
      phase = GamePhase.penalty;
    }
  }

  void acknowledgePenalty(Duration now) {
    if (phase == GamePhase.penalty) _nextRound(now);
  }

  void pause() {
    if (![
      GamePhase.countdown,
      GamePhase.playing,
      GamePhase.success,
    ].contains(phase)) {
      return;
    }
    _resumePhase = phase;
    phase = GamePhase.paused;
    hold = Duration.zero;
    observation = PoseMatch.unknown;
    _lastObservation = null;
  }

  void resume(Duration now) {
    if (phase != GamePhase.paused) return;
    phase = _resumePhase;
    _lastTick = now;
  }
}
