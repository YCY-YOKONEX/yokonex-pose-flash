import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:pose_flash/game/challenge.dart';
import 'package:pose_flash/game/pose_rules.dart';

class Session {
  Session({GameSettings settings = const GameSettings()})
    : game = Challenge(settings, random: Random(7)) {
    game.start(now);
  }
  final Challenge game;
  Duration now = Duration.zero;

  void advance(int milliseconds, PoseMatch match) {
    game.observe(match, now);
    for (var elapsed = 0; elapsed < milliseconds; elapsed += 50) {
      now += const Duration(milliseconds: 50);
      game.observe(match, now);
      game.tick(now);
    }
  }

  void begin() {
    advance(3000, PoseMatch.mismatch);
    expect(game.phase, GamePhase.playing);
  }
}

void main() {
  test('waits for a visible body before the preparation countdown', () {
    final session = Session();
    session.advance(5000, PoseMatch.unknown);
    expect(session.game.countdown, 3);
    expect(session.game.remaining.inSeconds, 5);
    session.begin();
  });

  test('requires 800ms of continuous matching and scores only once', () {
    final session = Session()..begin();
    session.advance(750, PoseMatch.match);
    expect(session.game.phase, GamePhase.playing);
    session.advance(50, PoseMatch.match);
    expect(session.game.phase, GamePhase.success);
    expect(session.game.passed, 1);
    session.advance(100, PoseMatch.match);
    expect(session.game.passed, 1);
  });

  test('a wrong pose clears accumulated hold progress', () {
    final session = Session()..begin();
    session.advance(500, PoseMatch.match);
    session.advance(50, PoseMatch.mismatch);
    expect(session.game.hold, Duration.zero);
    session.advance(500, PoseMatch.match);
    expect(session.game.phase, GamePhase.playing);
    session.advance(300, PoseMatch.match);
    expect(session.game.phase, GamePhase.success);
  });

  test('body occlusion freezes round time and clears hold progress', () {
    final session = Session()..begin();
    session.advance(300, PoseMatch.match);
    session.game.observe(PoseMatch.unknown, session.now);
    final remaining = session.game.remaining;
    session.advance(10000, PoseMatch.unknown);
    expect(session.game.remaining, remaining);
    expect(session.game.hold, Duration.zero);
    expect(session.game.failed, 0);
  });

  test(
    'stale observations cannot grant success or consume the full timeout',
    () {
      final session = Session()..begin();
      session.advance(250, PoseMatch.match);
      final remaining = session.game.remaining;
      session.now += const Duration(seconds: 2);
      session.game.tick(session.now);
      expect(session.game.observation, PoseMatch.unknown);
      expect(session.game.hold, Duration.zero);
      expect(session.game.remaining, remaining);
      session.advance(750, PoseMatch.match);
      expect(session.game.passed, 0);
    },
  );

  test('timeout waits for device punishment acknowledgement', () {
    final session = Session()..begin();
    session.advance(5000, PoseMatch.mismatch);
    expect(session.game.phase, GamePhase.penalty);
    expect(session.game.failed, 1);
    final first = session.game.target;
    session.advance(10000, PoseMatch.match);
    expect(session.game.round, 1);
    expect(session.game.failed, 1);
    session.game.acknowledgePenalty(session.now);
    expect(session.game.round, 2);
    expect(session.game.target, isNot(first));
    expect(session.game.phase, GamePhase.countdown);
  });

  test('a last-moment pose must complete its hold before time expires', () {
    final session = Session()..begin();
    session.advance(4500, PoseMatch.mismatch);
    session.advance(500, PoseMatch.match);
    expect(session.game.phase, GamePhase.penalty);
    expect(session.game.passed, 0);
  });

  test('pause freezes time and requires fresh tracking after resume', () {
    final session = Session()..begin();
    session.advance(300, PoseMatch.match);
    final remaining = session.game.remaining;
    session.game.pause();
    session.advance(10000, PoseMatch.match);
    expect(session.game.phase, GamePhase.paused);
    expect(session.game.remaining, remaining);
    session.game.resume(session.now);
    expect(session.game.hold, Duration.zero);
    expect(session.game.observation, PoseMatch.unknown);
    session.advance(800, PoseMatch.match);
    expect(session.game.phase, GamePhase.success);
  });

  test(
    'a full challenge finishes with exactly the configured number of rounds',
    () {
      final session = Session(settings: const GameSettings(rounds: 5));
      PoseKind? previous;
      for (var round = 1; round <= 5; round++) {
        expect(session.game.target, isNot(previous));
        previous = session.game.target;
        session.begin();
        session.advance(800, PoseMatch.match);
        session.advance(1200, PoseMatch.unknown);
      }
      expect(session.game.phase, GamePhase.finished);
      expect(session.game.round, 5);
      expect(session.game.passed, 5);
      expect(session.game.failed, 0);
    },
  );

  test('last-round failure finishes only after acknowledging the penalty', () {
    final session = Session(settings: const GameSettings(rounds: 5));
    for (var round = 1; round <= 5; round++) {
      session.begin();
      session.advance(5000, PoseMatch.mismatch);
      expect(session.game.phase, GamePhase.penalty);
      session.game.acknowledgePenalty(session.now);
    }
    expect(session.game.phase, GamePhase.finished);
    expect(session.game.failed, 5);
  });

  test('later rounds add a combo step and shorten the time limit', () {
    final session = Session(
      settings: const GameSettings(rounds: 10, roundSeconds: 5),
    );
    for (var round = 1; round < 6; round++) {
      session.begin();
      session.advance(800, PoseMatch.match);
      session.advance(1200, PoseMatch.unknown);
    }
    expect(session.game.round, 6);
    expect(session.game.isCombo, isTrue);
    expect(session.game.sequenceLength, 2);
    expect(session.game.remaining.inSeconds, 4);

    session.begin();
    session.advance(800, PoseMatch.match);
    expect(session.game.phase, GamePhase.playing);
    expect(session.game.sequenceStep, 2);
    session.advance(800, PoseMatch.match);
    expect(session.game.phase, GamePhase.success);
  });

  test('random action library excludes the two awkward arm combinations', () {
    expect(playablePoseKinds, contains(PoseKind.reachWing));
    expect(playablePoseKinds, contains(PoseKind.reachHip));
    expect(playablePoseKinds, contains(PoseKind.wingHip));
    expect(playablePoseKinds, isNot(contains(PoseKind.reachGoalpost)));
    expect(playablePoseKinds, isNot(contains(PoseKind.wingGoalpost)));
  });

  test('invalid saved settings receive usable defaults', () {
    final settings = const GameSettings(
      roundSeconds: 0,
      rounds: 0,
      penalties: ['  '],
    ).validated();
    expect(settings.roundSeconds, 3);
    expect(settings.rounds, 10);
    expect(settings.penalties, defaultPenalties);
  });
}
