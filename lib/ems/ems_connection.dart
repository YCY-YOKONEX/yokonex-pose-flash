import 'package:flutter/foundation.dart';
import 'ems_protocol.dart';
import 'ems_service.dart';

/// 应用级 EMS 连接状态，跨首页、连接页和挑战页复用同一个蓝牙控制器。
class EmsConnectionStore extends ChangeNotifier {
  EmsConnectionStore._();

  static final instance = EmsConnectionStore._();

  final BluetoothEmsController controller = BluetoothEmsController();
  EmsDeviceGeneration? generation;
  bool busy = false;
  String? message;

  bool get connected => controller.isConnected;

  Future<void> connect() async {
    if (busy) return;
    busy = true;
    message = null;
    notifyListeners();
    try {
      generation = await controller.connectAny();
      message = '设备已连接，可以开始挑战';
    } catch (error) {
      generation = null;
      message = _friendlyError(error);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (busy) return;
    busy = true;
    notifyListeners();
    try {
      await controller.disconnect();
      generation = null;
      message = '设备已断开';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('未找到设备')) return '没有找到设备，请确认设备已开机并靠近手机';
    return '连接失败，请确认蓝牙权限和设备状态';
  }
}
