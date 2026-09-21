import 'package:flutter/material.dart';
import '../ems/ems_connection.dart';
import '../ems/ems_protocol.dart';
import '../game/challenge.dart';
import '../settings_store.dart';
import '../l10n/app_localizations.dart';
import 'device_connection_screen.dart';
import 'game_screen.dart';
import 'pose_figure.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _store = SettingsStore();
  final _connection = EmsConnectionStore.instance;
  GameSettings _settings = const GameSettings();
  bool _loading = true;
  bool _saving = false;

  void _updateEms({int? baseIntensity, int? failureIncrement}) {
    setState(
      () => _settings = GameSettings(
        roundSeconds: _settings.roundSeconds,
        rounds: _settings.rounds,
        penalties: _settings.penalties,
        emsBaseIntensity: baseIntensity ?? _settings.emsBaseIntensity,
        emsFailureIncrement: failureIncrement ?? _settings.emsFailureIncrement,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final settings = await _store.load();
      if (mounted) setState(() => _settings = settings);
    } catch (_) {
      if (mounted) _message(AppLocalizations.of(context).settingsLoadFailed);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _start() async {
    setState(() => _saving = true);
    try {
      await _store.save(_settings);
    } catch (_) {
      if (mounted) _message(AppLocalizations.of(context).settingsSaveFailed);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => GameScreen(settings: _settings)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        AppLocalizations.of(context).appTitle,
        style: TextStyle(
          color: paper,
          fontWeight: FontWeight.w900,
          fontSize: 16,
          letterSpacing: .02,
        ),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 20),
          child: Icon(Icons.bolt_rounded, color: coral),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
                  children: [
                    Text(
                      AppLocalizations.of(context).appTitle,
                      style: TextStyle(
                        color: paper,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 4,
                      children: [
                        Text(
                          AppLocalizations.of(context).roundTime,
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          AppLocalizations.of(
                            context,
                          ).seconds(_settings.roundSeconds),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: teal,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _settings.roundSeconds.toDouble(),
                      min: 3,
                      max: 10,
                      divisions: 7,
                      label: AppLocalizations.of(
                        context,
                      ).seconds(_settings.roundSeconds),
                      onChanged: (value) => setState(
                        () => _settings = GameSettings(
                          roundSeconds: value.round(),
                          rounds: _settings.rounds,
                          penalties: _settings.penalties,
                          emsGeneration: _settings.emsGeneration,
                          emsBaseIntensity: _settings.emsBaseIntensity,
                          emsFailureIncrement: _settings.emsFailureIncrement,
                        ),
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).challengeRounds,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<int>(
                      segments: [5, 10, 20]
                          .map(
                            (count) => ButtonSegment(
                              value: count,
                              label: Text(
                                AppLocalizations.of(context).rounds(count),
                              ),
                            ),
                          )
                          .toList(),
                      selected: {_settings.rounds},
                      onSelectionChanged: (value) => setState(
                        () => _settings = GameSettings(
                          roundSeconds: _settings.roundSeconds,
                          rounds: value.single,
                          penalties: _settings.penalties,
                          emsGeneration: _settings.emsGeneration,
                          emsBaseIntensity: _settings.emsBaseIntensity,
                          emsFailureIncrement: _settings.emsFailureIncrement,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 32, color: line),
                    AnimatedBuilder(
                      animation: _connection,
                      builder: (context, _) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: _connection.connected
                              ? teal.withValues(alpha: .14)
                              : coral.withValues(alpha: .12),
                          border: Border.all(
                            color: _connection.connected ? teal : coral,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _connection.connected
                                        ? Icons.bluetooth_connected_rounded
                                        : Icons.bolt_rounded,
                                    color: _connection.connected ? teal : coral,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _connection.connected
                                          ? AppLocalizations.of(
                                              context,
                                            ).emsConnected
                                          : AppLocalizations.of(
                                              context,
                                            ).emsPenaltyTitle,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  if (_connection.connected)
                                    Text(
                                      _connection.generation!.deviceName,
                                      style: const TextStyle(
                                        color: teal,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _connection.connected
                                    ? AppLocalizations.of(
                                        context,
                                      ).emsConnectedDescription
                                    : AppLocalizations.of(
                                        context,
                                      ).emsNotConnectedDescription,
                                style: const TextStyle(
                                  color: muted,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _connection.connected
                                        ? mint
                                        : coral,
                                    foregroundColor: paper,
                                    minimumSize: const Size.fromHeight(54),
                                  ),
                                  onPressed: () => Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          const DeviceConnectionScreen(),
                                    ),
                                  ),
                                  icon: Icon(
                                    _connection.connected
                                        ? Icons.settings_bluetooth_rounded
                                        : Icons.bluetooth_rounded,
                                  ),
                                  label: Text(
                                    _connection.connected
                                        ? AppLocalizations.of(
                                            context,
                                          ).manageConnectedDevice
                                        : AppLocalizations.of(
                                            context,
                                          ).connectEmsDevice,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _intensitySlider(
                      title: AppLocalizations.of(context).firstFailureIntensity,
                      value: _settings.emsBaseIntensity,
                      onChanged: (value) =>
                          _updateEms(baseIntensity: value.round()),
                    ),
                    _intensitySlider(
                      title: AppLocalizations.of(context).failureIncrement,
                      value: _settings.emsFailureIncrement,
                      onChanged: (value) =>
                          _updateEms(failureIncrement: value.round()),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _saving ? null : _start,
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _saving
                            ? AppLocalizations.of(context).preparing
                            : AppLocalizations.of(context).startChallenge,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    ),
  );

  Widget _intensitySlider({
    required String title,
    required int value,
    required ValueChanged<double> onChanged,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        runSpacing: 2,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          Text('$value / 180', style: const TextStyle(color: teal)),
        ],
      ),
      Slider(
        value: value.toDouble(),
        min: 0,
        max: 180,
        divisions: 180,
        label: '$value',
        onChanged: onChanged,
      ),
    ],
  );
}
