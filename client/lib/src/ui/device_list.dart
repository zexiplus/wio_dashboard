import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:wio_controller/src/ble/ble_scanner.dart';
import 'package:provider/provider.dart';

import '../widgets.dart';
import 'device_detail/device_detail_screen.dart';

const exceptionDeviceName = 'wio terminal';

class DeviceListScreen extends StatelessWidget {
  const DeviceListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Consumer2<BleScanner, BleScannerState?>(
        builder: (_, bleScanner, bleScannerState, __) => _DeviceList(
          scannerState: bleScannerState ??
              const BleScannerState(
                discoveredDevices: [],
                scanIsInProgress: false,
              ),
          startScan: bleScanner.startScan,
          stopScan: bleScanner.stopScan,
        ),
      );
}

class _DeviceList extends StatefulWidget {
  const _DeviceList(
      {required this.scannerState,
      required this.startScan,
      required this.stopScan});

  final BleScannerState scannerState;
  final void Function(List<Uuid>) startScan;
  final VoidCallback stopScan;

  @override
  _DeviceListState createState() => _DeviceListState();
}

class _DeviceListState extends State<_DeviceList> {
  @override
  void dispose() {
    widget.stopScan();
    super.dispose();
  }

  void _startScanning() {
    widget.startScan([]);
  }

  bool filtter = true; // show only wio terminal

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Scan for bluetooth devices'),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Row(
                      //   children: [
                      //     const Text('Only wio terminal:'),
                      //     Switch(
                      //       value: filtter,
                      //       onChanged: (value) =>
                      //           setState(() => filtter = value),
                      //     )
                      //   ],
                      // ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: !widget.scannerState.scanIsInProgress
                                ? _startScanning
                                : null,
                            child: const Text('Scan'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: widget.scannerState.scanIsInProgress
                                ? widget.stopScan
                                : null,
                            child: const Text('Stop'),
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text('Tap a device to connect to it'),
                      ),
                      if (widget.scannerState.scanIsInProgress ||
                          widget.scannerState.discoveredDevices.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsetsDirectional.only(start: 18.0),
                          child: Text(
                              'count: ${filtter ? widget.scannerState.discoveredDevices.where((device) => device.name == exceptionDeviceName).toList().length : widget.scannerState.discoveredDevices.length}'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                children: widget.scannerState.discoveredDevices
                    .where((device) =>
                        filtter ? device.name == exceptionDeviceName : true)
                    .toList()
                    .map(
                      (device) => ListTile(
                        title: Text(device.name),
                        subtitle: Text("${device.id}\nRSSI: ${device.rssi}"),
                        leading: device.name == exceptionDeviceName
                            ? const WioIcon()
                            : const BluetoothIcon(),
                        onTap: () async {
                          widget.stopScan();
                          await Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      DeviceDetailScreen(device: device)));
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      );
}
