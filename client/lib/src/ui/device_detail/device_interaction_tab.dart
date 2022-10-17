import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:wio_controller/src/ble/ble_device_connector.dart';
import 'package:wio_controller/src/ble/ble_device_interactor.dart';
import 'package:functional_data/functional_data.dart';
import 'package:wio_controller/src/ui/console.dart';
import 'package:provider/provider.dart';

import 'characteristic_interaction_dialog.dart';

part 'device_interaction_tab.g.dart';
//ignore_for_file: annotate_overrides

const wio_service_id = '188f';

class DeviceInteractionTab extends StatelessWidget {
  final DiscoveredDevice device;

  const DeviceInteractionTab({
    required this.device,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) =>
      Consumer3<BleDeviceConnector, ConnectionStateUpdate, BleDeviceInteractor>(
        builder: (_, deviceConnector, connectionStateUpdate, serviceDiscoverer,
                __) =>
            _DeviceInteractionTab(
          viewModel: DeviceInteractionViewModel(
              deviceId: device.id,
              connectionStatus: connectionStateUpdate.connectionState,
              deviceConnector: deviceConnector,
              discoverServices: () =>
                  serviceDiscoverer.discoverServices(device.id)),
        ),
      );
}

@immutable
@FunctionalData()
class DeviceInteractionViewModel extends $DeviceInteractionViewModel {
  const DeviceInteractionViewModel({
    required this.deviceId,
    required this.connectionStatus,
    required this.deviceConnector,
    required this.discoverServices,
  });

  final String deviceId;
  final DeviceConnectionState connectionStatus;
  final BleDeviceConnector deviceConnector;
  @CustomEquality(Ignore())
  final Future<List<DiscoveredService>> Function() discoverServices;

  bool get deviceConnected =>
      connectionStatus == DeviceConnectionState.connected;

  void connect() {
    deviceConnector.connect(deviceId);
  }

  void disconnect() {
    deviceConnector.disconnect(deviceId);
  }
}

class _DeviceInteractionTab extends StatefulWidget {
  const _DeviceInteractionTab({
    required this.viewModel,
    Key? key,
  }) : super(key: key);

  final DeviceInteractionViewModel viewModel;

  @override
  _DeviceInteractionTabState createState() => _DeviceInteractionTabState();
}

class _DeviceInteractionTabState extends State<_DeviceInteractionTab> {
  late List<DiscoveredService> discoveredServices;

  @override
  void initState() {
    discoveredServices = [];
    super.initState();
  }

  Future<void> discoverServices() async {
    final result = await widget.viewModel.discoverServices();
    setState(() {
      discoveredServices = result
          .where((service) =>
              service.serviceId.toString().contains(wio_service_id))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) => CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildListDelegate.fixed(
              [
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      top: 8.0, bottom: 16.0, start: 16.0),
                  child: Text(
                    "ID: ${widget.viewModel.deviceId}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 16.0),
                  child: Text(
                    "Status: ${widget.viewModel.connectionStatus}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      ElevatedButton(
                        onPressed: !widget.viewModel.deviceConnected
                            ? widget.viewModel.connect
                            : null,
                        child: const Text("Connect"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: widget.viewModel.deviceConnected
                            ? widget.viewModel.disconnect
                            : null,
                        child: const Text("Disconnect"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: widget.viewModel.deviceConnected
                            ? () async {
                                await discoverServices();
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => Console(
                                            characteristic:
                                                QualifiedCharacteristic(
                                                    characteristicId:
                                                        discoveredServices[0]
                                                                .characteristicIds[
                                                            0],
                                                    serviceId:
                                                        discoveredServices[0]
                                                            .serviceId,
                                                    deviceId: widget
                                                        .viewModel.deviceId))));
                              }
                            : null,
                        child: const Text("Detail"),
                      ),
                      // ElevatedButton(
                      //     onPressed: () => print(discoveredServices),
                      //     child: Text('print'))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
