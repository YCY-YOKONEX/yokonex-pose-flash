import 'package:flutter_test/flutter_test.dart';
import 'package:pose_flash/ems/ems_protocol.dart';

void main() {
  test('maps the UI intensity range to the protocol range', () {
    expect(EmsProtocol.toProtocolIntensity(0), 0);
    expect(EmsProtocol.toProtocolIntensity(90), 138);
    expect(EmsProtocol.toProtocolIntensity(180), 276);
    expect(EmsProtocol.toProtocolIntensity(999), 276);
  });

  test('builds a three-second soothing-to-dense waveform', () {
    final waveform = EmsProtocol.penaltyWaveform();
    expect(waveform, hasLength(30));
    expect(waveform.first.frequencyHz, 1);
    expect(waveform.first.pulseUs, 10);
    expect(waveform.last.frequencyHz, 100);
    expect(waveform.last.pulseUs, 100);
    for (var i = 1; i < waveform.length; i++) {
      expect(
        waveform[i].frequencyHz,
        greaterThanOrEqualTo(waveform[i - 1].frequencyHz),
      );
      expect(
        waveform[i].pulseUs,
        greaterThanOrEqualTo(waveform[i - 1].pulseUs),
      );
    }
  });

  test('encodes first-generation custom mode with an additive checksum', () {
    final packet = EmsProtocol.firstGenerationPacket(
      uiIntensity: 180,
      point: const EmsWaveformPoint(100, 100),
    );
    expect(packet, hasLength(10));
    expect(packet.sublist(0, 9), [
      0x35,
      0x11,
      0x03,
      0x01,
      0x01,
      0x14,
      0x11,
      0x64,
      0x64,
    ]);
    expect(packet.last, 0x38);
  });

  test('encodes second-generation frequency mode with both channels', () {
    final packet = EmsProtocol.secondGenerationFrequencyPacket(
      uiIntensity: 90,
      waveform: const [EmsWaveformPoint(1, 10), EmsWaveformPoint(100, 100)],
      channel: 0x02,
    );
    expect(packet.sublist(0, 7), [0x35, 0x11, 0x03, 0x02, 0x00, 0x8A, 0x01]);
    expect(packet.sublist(6, 10), [1, 10, 100, 100]);
    expect(packet.last, 0xA8);
  });
}
