/// 协议中的设备代次。设备名必须与协议约定完全匹配。
enum EmsDeviceGeneration { first, second }

extension EmsDeviceGenerationName on EmsDeviceGeneration {
  String get deviceName => switch (this) {
    EmsDeviceGeneration.first => 'YYC-DJ',
    EmsDeviceGeneration.second => 'YYC-DJ-V2',
  };
}

class EmsWaveformPoint {
  const EmsWaveformPoint(this.frequencyHz, this.pulseUs);
  final int frequencyHz;
  final int pulseUs;
}

class EmsProtocol {
  EmsProtocol._();

  static const serviceUuid = '0000ff30-0000-1000-8000-00805f9b34fb';
  static const writeCharacteristicUuid = '0000ff31-0000-1000-8000-00805f9b34fb';
  static const notifyCharacteristicUuid =
      '0000ff32-0000-1000-8000-00805f9b34fb';
  static const maxProtocolIntensity = 276;
  static const maxUiIntensity = 180;

  /// UI 使用 180 级，协议按 276 级线性换算，避免越界。
  static int toProtocolIntensity(int uiIntensity) =>
      (uiIntensity.clamp(0, maxUiIntensity) *
              maxProtocolIntensity /
              maxUiIntensity)
          .round()
          .clamp(0, maxProtocolIntensity);

  /// 3 秒、每 100ms 一个采样点，兼容一代的自定义模式下发节奏。
  static List<EmsWaveformPoint> penaltyWaveform({int samples = 30}) {
    if (samples < 2) throw ArgumentError.value(samples, 'samples');
    return List.generate(samples, (index) {
      final progress = index / (samples - 1);
      return EmsWaveformPoint(
        (1 + progress * 99).round().clamp(1, 100),
        (10 + progress * 90).round().clamp(0, 100),
      );
    });
  }

  /// 一代：A、B 同步，模式 0x11 为自定义模式。
  static List<int> firstGenerationPacket({
    required int uiIntensity,
    required EmsWaveformPoint point,
    bool enabled = true,
  }) {
    final intensity = enabled ? toProtocolIntensity(uiIntensity) : 0;
    final body = <int>[
      0x35,
      0x11,
      0x03,
      enabled ? 0x01 : 0x00,
      intensity >> 8,
      intensity & 0xff,
      0x11,
      point.frequencyHz,
      point.pulseUs,
    ];
    return [...body, _checksum(body)];
  }

  /// 二代：频率模式一次承载整条波形，避免中途出现半条波形。
  static List<int> secondGenerationFrequencyPacket({
    required int uiIntensity,
    required List<EmsWaveformPoint> waveform,
    int channel = 0x01,
    bool enabled = true,
  }) {
    if (channel != 0x01 && channel != 0x02) {
      throw ArgumentError.value(channel, 'channel', '二代频率模式只支持 A 或 B');
    }
    final intensity = enabled ? toProtocolIntensity(uiIntensity) : 0;
    final body = <int>[
      0x35,
      0x11,
      0x03,
      channel,
      intensity >> 8,
      intensity & 0xff,
      ...waveform.expand((point) => [point.frequencyHz, point.pulseUs]),
    ];
    return [...body, _checksum(body)];
  }

  static List<int> stopPacket(
    EmsDeviceGeneration generation, {
    int channel = 0x01,
  }) {
    if (generation == EmsDeviceGeneration.first) {
      return firstGenerationPacket(
        uiIntensity: 0,
        point: const EmsWaveformPoint(0, 0),
        enabled: false,
      );
    }
    return secondGenerationFrequencyPacket(
      uiIntensity: 0,
      waveform: const [EmsWaveformPoint(1, 0)],
      channel: channel,
      enabled: false,
    );
  }

  static int _checksum(List<int> bytes) =>
      bytes.fold<int>(0, (sum, byte) => (sum + byte) & 0xff);
}
