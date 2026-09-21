import 'package:flutter/material.dart';
import '../ems/ems_protocol.dart';
import '../ems/ems_connection.dart';
import '../l10n/app_localizations.dart';
import 'pose_figure.dart';

class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  final _connection = EmsConnectionStore.instance;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _connection,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).deviceConnection),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        children: [
          const SizedBox(height: 8),
          Icon(
            _connection.connected
                ? Icons.bluetooth_connected_rounded
                : Icons.bluetooth_searching_rounded,
            size: 64,
            color: _connection.connected ? teal : coral,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context).connectEms,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: paper,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _connection.connected
                ? AppLocalizations.of(
                    context,
                  ).connectedDevice(_connection.generation!.deviceName)
                : AppLocalizations.of(context).scanYycDj,
            textAlign: TextAlign.center,
            style: const TextStyle(color: teal, fontSize: 16),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: _connection.connected ? mint : coral,
              foregroundColor: paper,
              minimumSize: const Size.fromHeight(58),
            ),
            onPressed: _connection.busy
                ? null
                : (_connection.connected
                      ? _connection.disconnect
                      : _connection.connect),
            icon: Icon(
              _connection.connected
                  ? Icons.bluetooth_disabled_rounded
                  : Icons.bluetooth_rounded,
            ),
            label: Text(
              _connection.busy
                  ? AppLocalizations.of(context).processing
                  : (_connection.connected
                        ? AppLocalizations.of(context).disconnectDevice
                        : AppLocalizations.of(context).scanAndConnectEms),
            ),
          ),
          if (_connection.message != null) ...[
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(
                context,
              ).translateConnectionMessage(_connection.message!),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _connection.connected ? teal : coral,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            AppLocalizations.of(context).connectionSafety,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, height: 1.5),
          ),
        ],
      ),
    ),
  );
}
