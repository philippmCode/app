import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:open_earable/ble/ble_controller.dart';
import 'package:open_earable/ble/ble_tab_bar_page.dart';
import 'package:open_earable/controls_tab/models/open_earable_settings_v2.dart';
import 'package:open_earable_flutter/src/open_earable_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectCard extends StatefulWidget {
  ConnectCard();

  @override
  _ConnectCard createState() => _ConnectCard();
}

class _ConnectCard extends State<ConnectCard> {
  late OpenEarable _openEarableLeft;
  late OpenEarable _openEarableRight;
  bool _autoConnectEnabled = false;
  late SharedPreferences prefs;

  _ConnectCard();

  void selectButton(int index) {
    setState(() {
      OpenEarableSettingsV2().selectedButtonIndex = index;
    });
    Provider.of<BluetoothController>(context, listen: false)
        .updateCurrentOpenEarable();
  }

  @override
  void initState() {
    super.initState();
    _getPrefs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _getPrefs() async {
    _autoConnectEnabled = false;
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoConnectEnabled = prefs.getBool("autoConnectEnabled") ?? false;
    });
    _startAutoConnectScan();
  }

  void _startAutoConnectScan() async {
    if (_autoConnectEnabled) {
      Provider.of<BluetoothController>(context, listen: false).startScanning(
          _openEarableLeft); // Scanning on one earable is sufficient to connect to both
    }
  }

  @override
  Widget build(BuildContext context) {
    _openEarableLeft = Provider.of<BluetoothController>(context, listen: false)
        .openEarableLeft;
    _openEarableRight = Provider.of<BluetoothController>(context, listen: false)
        .openEarableRight;
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5.0),
        child: Card(
            color: Platform.isIOS
                ? CupertinoTheme.of(context).primaryContrastingColor
                : Theme.of(context).colorScheme.primary,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Selector<BluetoothController, List<DiscoveredDevice>>(
                        selector: (context, bleController) =>
                            bleController.discoveredDevices,
                        builder: (context, devices, child) {
                          _tryAutoconnect(devices);
                          return Text(
                            'Devices',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }),
                    Row(
                      children: [
                        Platform.isIOS
                            ? CupertinoCheckbox(
                                value: _autoConnectEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _autoConnectEnabled = value ?? false;
                                  });
                                  _startAutoConnectScan();
                                  if (value != null)
                                    prefs.setBool("autoConnectEnabled", value);
                                },
                                activeColor: _autoConnectEnabled
                                    ? CupertinoTheme.of(context).primaryColor
                                    : CupertinoTheme.of(context)
                                        .primaryContrastingColor,
                                checkColor: CupertinoTheme.of(context)
                                    .primaryContrastingColor,
                              )
                            : Checkbox(
                                checkColor:
                                    Theme.of(context).colorScheme.primary,
                                //fillColor: Theme.of(context).colorScheme.primary,
                                value: _autoConnectEnabled,
                                onChanged: (value) {
                                  setState(() {
                                    _autoConnectEnabled = value ?? false;
                                  });
                                  _startAutoConnectScan();
                                  if (value != null)
                                    prefs.setBool("autoConnectEnabled", value);
                                },
                              ),
                        Text(
                          "Connect to OpenEarable automatically",
                          style: TextStyle(
                            color: Color.fromRGBO(168, 168, 172, 1.0),
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Expanded(
                            child: Column(children: [
                          Selector<BluetoothController, int?>(
                              selector: (context, bleController) =>
                                  bleController.earableSOCLeft,
                              builder: (context, socLeft, child) {
                                return _getEarableSelectButton(
                                    imagePath:
                                        "assets/OpenEarableV2-L.png", // path to your image asset
                                    isSelected: OpenEarableSettingsV2()
                                            .selectedButtonIndex ==
                                        0,
                                    onPressed: () => selectButton(0),
                                    openEarable: _openEarableLeft,
                                    percentage: socLeft);
                              }),
                          SizedBox(height: 8),
                          _getConnectButton(context, "Left"),
                        ])),
                        SizedBox(width: 8),
                        Expanded(
                            child: Column(children: [
                          Selector<BluetoothController, int?>(
                              selector: (context, bleController) =>
                                  bleController.earableSOCRight,
                              builder: (context, socRight, child) {
                                return _getEarableSelectButton(
                                  imagePath: "assets/OpenEarableV2-R.png",
                                  isSelected: OpenEarableSettingsV2()
                                          .selectedButtonIndex ==
                                      1,
                                  onPressed: () => selectButton(1),
                                  openEarable: _openEarableRight,
                                  percentage: socRight,
                                );
                              }),
                          SizedBox(height: 8),
                          _getConnectButton(context, "Right"),
                        ])),
                      ],
                    ),
                  ],
                ))));
  }

  String _batteryPercentageString(int? percentage) {
    if (percentage == null) {
      return " (XX%)";
    } else {
      return " ($percentage%)";
    }
  }

  Widget _getConnectButton(BuildContext context, String side) {
    return Container(
      height: 37,
      width: double.infinity,
      child: !Platform.isIOS
          ? ElevatedButton(
              onPressed: () => _connectButtonAction(context, side),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff77F2A1),
                foregroundColor: Colors.black,
              ),
              child: Text("Connect"),
            )
          : CupertinoButton(
              padding: EdgeInsets.zero,
              color: CupertinoTheme.of(context).primaryColor,
              child: Text("Connect"),
              onPressed: () => _connectButtonAction(context, side)),
    );
  }

  _connectButtonAction(BuildContext context, String side) {
    Navigator.of(context).push(Platform.isIOS
        ? CupertinoPageRoute(
            builder: (context) => BLETabBarPage(index: side == "Left" ? 0 : 1))
        : MaterialPageRoute(
            builder: (context) =>
                BLETabBarPage(index: side == "Left" ? 0 : 1)));
  }

  void _tryAutoconnect(List<DiscoveredDevice> devices) async {
    if (_autoConnectEnabled != true || devices.isEmpty) {
      return;
    }
    bool leftConnectSuccessful = true;
    bool rightConnectSuccessful = true;
    BluetoothController bleController =
        Provider.of<BluetoothController>(context, listen: false);
    List<DiscoveredDevice> devicesCopy = List.from(devices);
    String? lastConnectedDeviceNameLeft =
        prefs.getString("lastConnectedDeviceNameLeft");
    String? lastConnectedDeviceNameRight =
        prefs.getString("lastConnectedDeviceNameRight");
    try {
      DiscoveredDevice? deviceToConnectLeft = devicesCopy
          .firstWhere((device) => device.name == lastConnectedDeviceNameLeft);
      if (_openEarableLeft.bleManager.connectingDevice?.name !=
          deviceToConnectLeft.name) {
        bleController.connectToDevice(deviceToConnectLeft, _openEarableLeft, 0);
      }
      devicesCopy.remove(deviceToConnectLeft);
    } on StateError catch (_) {
      leftConnectSuccessful = false;
    }
    try {
      DiscoveredDevice? deviceToConnectRight = devicesCopy
          .firstWhere((device) => device.name == lastConnectedDeviceNameRight);
      if (_openEarableRight.bleManager.connectingDevice?.name !=
          deviceToConnectRight.name) {
        bleController.connectToDevice(
            deviceToConnectRight, _openEarableRight, 1);
      }
      devicesCopy.remove(deviceToConnectRight);
    } on StateError catch (_) {
      rightConnectSuccessful = false;
    }

    if (!leftConnectSuccessful) {
      DiscoveredDevice? leftDevice = devicesCopy.firstOrNull;
      if (leftDevice != null) {
        bleController.connectToDevice(leftDevice, _openEarableLeft, 0);
      }
      devicesCopy.remove(leftDevice);
    }
    if (!rightConnectSuccessful) {
      DiscoveredDevice? rightDevice = devicesCopy.firstOrNull;
      if (rightDevice != null) {
        bleController.connectToDevice(rightDevice, _openEarableRight, 1);
      }
    }
  }

  Widget _getEarableSelectButton({
    required OpenEarable openEarable,
    required String imagePath,
    required bool isSelected,
    required onPressed,
    required int? percentage,
  }) {
    if (Platform.isIOS) {
      return CupertinoButton(
        color: Color.fromARGB(255, 83, 81, 91),
        onPressed: onPressed,
        padding:
            EdgeInsets.zero, // Remove padding to use the entire container space
        child: Container(
          padding: EdgeInsets.all(8.0), // Internal padding within the button
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(
                7.0), // Slightly smaller radius for the inner border
            border: Border.all(
              color: isSelected
                  ? CupertinoTheme.of(context).primaryColor
                  : Colors.transparent,
              width: 3,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${openEarable.bleManager.connectedDevice?.name ?? "OpenEarable-XXXX"}${_batteryPercentageString(percentage)}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                ),
              ),
              SizedBox(height: 8),
              Image.asset(imagePath, fit: BoxFit.fill),
              SizedBox(height: 8),
              Text(
                "Firmware: ${openEarable.deviceFirmwareVersion ?? "X.X.X"}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                ),
              ),
              Text(
                "Hardware: ${openEarable.deviceHardwareVersion ?? "X.X.X"}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
              Color.fromARGB(255, 83, 81, 91)), // Adjust the color as needed
          shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                color: isSelected
                    ? Theme.of(context).colorScheme.secondary
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: MaterialStateProperty.all(
              EdgeInsets.zero), // Adjust padding if necessary
        ),
        child: Container(
          padding: EdgeInsets.all(8.0), // Padding inside the button for content
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${openEarable.bleManager.connectedDevice?.name ?? "OpenEarable-XXXX"}${_batteryPercentageString(percentage)}", // Assuming _openEarable and bleController are accessible
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                ),
              ),
              SizedBox(height: 8),
              Image.asset(imagePath, fit: BoxFit.fill),
              SizedBox(height: 8),
              Text(
                "Firmware: ${openEarable.deviceFirmwareVersion ?? "X.X.X"}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                ),
              ),
              Text(
                "Hardware: ${openEarable.deviceHardwareVersion ?? "X.X.X"}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.0,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
