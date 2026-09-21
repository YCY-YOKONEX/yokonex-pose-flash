import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'ems_protocol.dart';

abstract interface class EmsController {
  Future<void> playPenalty({
    required EmsDeviceGeneration generation,
    required int uiIntensity,
  });

  Future<void> dispose();
}

/// BLE 控制层只负责扫描、连接和发包，游戏逻辑不直接依赖蓝牙插件。
class BluetoothEmsController implements EmsController {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  EmsDeviceGeneration? _generation;
  bool _playing = false;

  bool get isConnected => _device?.isConnected == true;
  EmsDeviceGeneration? get connectedGeneration => _generation;

  Future<void> connect(EmsDeviceGeneration generation) async {
    await _ensureConnected(generation);
  }

  /// 扫描两种设备名称，连接时由实际发现的设备决定协议代次。
  Future<EmsDeviceGeneration> connectAny() async {
    await _disconnect();
    final found = await _scanAny();
    await _connectDevice(found.$1, found.$2);
    return found.$2;
  }

  Future<void> disconnect() => _disconnect();

  @override
  Future<void> playPenalty({
    required EmsDeviceGeneration generation,
    required int uiIntensity,
  }) async {
    if (_playing) return;
    _playing = true;
    try {
      final characteristic = await _ensureConnectedAny();
      final activeGeneration = _generation!;
      final waveform = EmsProtocol.penaltyWaveform();
      if (activeGeneration == EmsDeviceGeneration.second) {
        // 二代协议要求 A、B 通道分别发送频率模式包。
        for (final channel in [0x01, 0x02]) {
          await characteristic.write(
            EmsProtocol.secondGenerationFrequencyPacket(
              uiIntensity: uiIntensity,
              waveform: waveform,
              channel: channel,
            ),
            withoutResponse: true,
          );
        }
        await Future<void>.delayed(const Duration(seconds: 3));
      } else {
        // 一代协议规定自定义模式最快每 100ms 下发一次。
        for (final point in waveform) {
          await characteristic.write(
            EmsProtocol.firstGenerationPacket(
              uiIntensity: uiIntensity,
              point: point,
            ),
            withoutResponse: true,
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
      if (activeGeneration == EmsDeviceGeneration.second) {
        for (final channel in [0x01, 0x02]) {
          await characteristic.write(
            EmsProtocol.stopPacket(activeGeneration, channel: channel),
            withoutResponse: true,
          );
        }
      } else {
        await characteristic.write(
          EmsProtocol.stopPacket(activeGeneration),
          withoutResponse: true,
        );
      }
    } finally {
      _playing = false;
    }
  }

  Future<BluetoothCharacteristic> _ensureConnected(
    EmsDeviceGeneration generation,
  ) async {
    if (_generation == generation &&
        _device?.isConnected == true &&
        _writeCharacteristic != null) {
      return _writeCharacteristic!;
    }
    await _disconnect();
    final device = await _scan(generation);
    return _connectDevice(device, generation);
  }

  Future<BluetoothCharacteristic> _ensureConnectedAny() async {
    if (_device?.isConnected == true &&
        _writeCharacteristic != null &&
        _generation != null) {
      return _writeCharacteristic!;
    }
    await _disconnect();
    final found = await _scanAny();
    return _connectDevice(found.$1, found.$2);
  }

  Future<BluetoothCharacteristic> _connectDevice(
    BluetoothDevice device,
    EmsDeviceGeneration generation,
  ) async {
    await device.connect(timeout: const Duration(seconds: 12));
    final services = await device.discoverServices();
    final service = services.firstWhere(
      (item) => item.uuid == Guid(EmsProtocol.serviceUuid),
      orElse: () => throw StateError('未找到 FF30 服务'),
    );
    final write = service.characteristics.firstWhere(
      (item) => item.uuid == Guid(EmsProtocol.writeCharacteristicUuid),
      orElse: () => throw StateError('未找到 FF31 写入特征'),
    );
    final notify = service.characteristics.where(
      (item) => item.uuid == Guid(EmsProtocol.notifyCharacteristicUuid),
    );
    if (notify.isNotEmpty) {
      await notify.first.setNotifyValue(true);
    }
    _device = device;
    _writeCharacteristic = write;
    _generation = generation;
    return write;
  }

  Future<(BluetoothDevice, EmsDeviceGeneration)> _scanAny() async {
    final names = {
      for (final generation in EmsDeviceGeneration.values)
        generation.deviceName: generation,
    };
    final results = <BluetoothDevice, EmsDeviceGeneration>{};
    final subscription = FlutterBluePlus.onScanResults.listen((items) {
      for (final result in items) {
        final advertised = result.advertisementData.advName;
        final platform = result.device.platformName;
        final generation = names[advertised] ?? names[platform];
        if (generation != null) results[result.device] = generation;
      }
    });
    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(EmsProtocol.serviceUuid)],
        timeout: const Duration(seconds: 8),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 8));
      while (results.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await FlutterBluePlus.stopScan();
      if (results.isEmpty) throw StateError('未找到 YYC-DJ 设备');
      final device = results.keys.first;
      return (device, results[device]!);
    } finally {
      await subscription.cancel();
      await FlutterBluePlus.stopScan();
    }
  }

  Future<BluetoothDevice> _scan(EmsDeviceGeneration generation) async {
    final name = generation.deviceName;
    final results = <BluetoothDevice, ScanResult>{};
    final subscription = FlutterBluePlus.onScanResults.listen((items) {
      for (final result in items) {
        final advertised = result.advertisementData.advName;
        final platform = result.device.platformName;
        if (advertised == name || platform == name) {
          results[result.device] = result;
        }
      }
    });
    try {
      await FlutterBluePlus.startScan(
        withServices: [Guid(EmsProtocol.serviceUuid)],
        timeout: const Duration(seconds: 8),
      );
      final deadline = DateTime.now().add(const Duration(seconds: 8));
      while (results.isEmpty && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      await FlutterBluePlus.stopScan();
      if (results.isEmpty) throw StateError('未找到设备 $name');
      return results.keys.first;
    } finally {
      await subscription.cancel();
      await FlutterBluePlus.stopScan();
    }
  }

  Future<void> _disconnect() async {
    final device = _device;
    _device = null;
    _writeCharacteristic = null;
    _generation = null;
    if (device != null && device.isConnected) await device.disconnect();
  }

  @override
  Future<void> dispose() => _disconnect();
}

class NoopEmsController implements EmsController {
  @override
  Future<void> playPenalty({
    required EmsDeviceGeneration generation,
    required int uiIntensity,
  }) async {}

  @override
  Future<void> dispose() async {}
}
