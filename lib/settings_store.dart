import 'package:shared_preferences/shared_preferences.dart';
import 'ems/ems_protocol.dart';
import 'game/challenge.dart';

class SettingsStore {
  Future<GameSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return GameSettings(
      roundSeconds: prefs.getInt('roundSeconds') ?? 5,
      rounds: prefs.getInt('rounds') ?? 10,
      penalties: prefs.getStringList('penalties') ?? defaultPenalties,
      emsGeneration: (prefs.getString('emsGeneration') == 'first')
          ? EmsDeviceGeneration.first
          : EmsDeviceGeneration.second,
      emsBaseIntensity: prefs.getInt('emsBaseIntensity') ?? 30,
      emsFailureIncrement: prefs.getInt('emsFailureIncrement') ?? 10,
    ).validated();
  }

  Future<void> save(GameSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final results = await Future.wait([
      prefs.setInt('roundSeconds', settings.roundSeconds),
      prefs.setInt('rounds', settings.rounds),
      prefs.setStringList('penalties', settings.penalties),
      prefs.setString('emsGeneration', settings.emsGeneration.name),
      prefs.setInt('emsBaseIntensity', settings.emsBaseIntensity),
      prefs.setInt('emsFailureIncrement', settings.emsFailureIncrement),
    ]);
    if (results.contains(false)) throw StateError('设置保存失败');
  }
}
