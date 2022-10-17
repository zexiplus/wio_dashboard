import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:wio_controller/src/ble/ble_device_interactor.dart';
import 'package:provider/provider.dart';

class Console extends StatelessWidget {
  const Console({
    required this.characteristic,
    Key? key,
  }) : super(key: key);
  final QualifiedCharacteristic characteristic;

  @override
  Widget build(BuildContext context) => Consumer<BleDeviceInteractor>(
      builder: (context, interactor, _) => _CharacteristicInteraction(
            characteristic: characteristic,
            readCharacteristic: interactor.readCharacteristic,
            writeWithResponse: interactor.writeCharacterisiticWithResponse,
            writeWithoutResponse:
                interactor.writeCharacterisiticWithoutResponse,
            subscribeToCharacteristic: interactor.subScribeToCharacteristic,
          ));
}

class _CharacteristicInteraction extends StatefulWidget {
  const _CharacteristicInteraction({
    required this.characteristic,
    required this.readCharacteristic,
    required this.writeWithResponse,
    required this.writeWithoutResponse,
    required this.subscribeToCharacteristic,
    Key? key,
  }) : super(key: key);

  final QualifiedCharacteristic characteristic;
  final Future<List<int>> Function(QualifiedCharacteristic characteristic)
      readCharacteristic;
  final Future<void> Function(
          QualifiedCharacteristic characteristic, List<int> value)
      writeWithResponse;

  final Stream<List<int>> Function(QualifiedCharacteristic characteristic)
      subscribeToCharacteristic;

  final Future<void> Function(
          QualifiedCharacteristic characteristic, List<int> value)
      writeWithoutResponse;

  @override
  _CharacteristicInteractionState createState() =>
      _CharacteristicInteractionState();
}

class _CharacteristicInteractionState
    extends State<_CharacteristicInteraction> {
  late List<String> readOutput;
  late String writeOutput;
  late String subscribeOutput;
  late TextEditingController textEditingController;
  late StreamSubscription<List<int>>? subscribeStream;
  bool autoRead = false;
  bool relayOn = false;

  @override
  void initState() {
    readOutput = ['0', '0', '0'];
    writeOutput = '';
    subscribeOutput = '';
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (autoRead) {
        readCharacteristic();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    subscribeStream?.cancel();
    super.dispose();
  }

  // subscribe to the charateristic to get data
  Future<void> subscribeCharacteristic() async {
    subscribeStream =
        widget.subscribeToCharacteristic(widget.characteristic).listen((event) {
      setState(() {
        subscribeOutput = event.toString();
      });
    });
    setState(() {
      subscribeOutput = 'Notification set';
    });
  }

  Future<void> readCharacteristic() async {
    final result = await widget.readCharacteristic(widget.characteristic);
    setState(() {
      List<String> rs = utf8.decode(result).split(',');
      readOutput = rs;
    });
  }

  Future<void> writeCharacteristicWithResponse(data) async {
    await widget.writeWithResponse(widget.characteristic, data);
    setState(() {
      writeOutput = 'Ok';
    });
  }

  Future<void> writeCharacteristicWithoutResponse(data) async {
    await widget.writeWithoutResponse(widget.characteristic, data);
    setState(() {
      writeOutput = 'Done';
    });
  }

  Widget get divider => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Divider(thickness: 2.0),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Console'),
        ),
        body: CustomScrollView(slivers: [
          SliverList(
              delegate: SliverChildListDelegate.fixed([
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Text('Auto read'),
                          Switch(
                              value: autoRead,
                              onChanged: (value) => {
                                    setState(() {
                                      autoRead = value;
                                    })
                                  })
                        ]),
                        ElevatedButton(
                            onPressed: readCharacteristic,
                            child: const Text('read'))
                      ]),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.lightbulb),
                        const SizedBox(width: 8),
                        Text('Light: ${readOutput[0]}'),
                      ]),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.speed),
                        const SizedBox(width: 8),
                        Text('Accelerator: ${readOutput[1]}'),
                      ]),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.water_drop),
                        const SizedBox(width: 8),
                        Text('moisture: ${readOutput[2]}'),
                      ]),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: const [
                        Icon(Icons.volume_down),
                        SizedBox(width: 8),
                        Text('Buzzer'),
                      ]),
                      ElevatedButton(
                          onPressed: () {
                            const sendData = "buzzer";
                            writeCharacteristicWithResponse(
                                utf8.encode(sendData));
                          },
                          child: const Text('play'))
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: const [
                        Icon(Icons.skip_next),
                        SizedBox(width: 8),
                        Text('Relay'),
                      ]),
                      Switch(
                          value: relayOn,
                          onChanged: (value) {
                            setState(() {
                              relayOn = value;
                            });
                            String sendData = value ? "relay on" : "relay off";
                            writeCharacteristicWithResponse(
                                utf8.encode(sendData));
                          })
                    ],
                  )
                ],
              ),
            ),
          ]))
        ]),
      );
}
