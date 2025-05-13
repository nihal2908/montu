import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_telephony_info/flutter_telephony_info.dart';

void main() => runApp(const MaterialApp(home: InfoPage()));

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});
  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  final Map<String, List<String>> infoData = {};

  @override
  void initState() {
    super.initState();
    requestPermissions().then((_) => fetchInfo());
  }

  Future<void> requestPermissions() async {
    await [
      Permission.location,
      Permission.phone,
      Permission.sensors,
      Permission.activityRecognition,
      Permission.ignoreBatteryOptimizations,
      Permission.bluetooth,
      Permission.notification,
    ].request();

    if (!await Geolocator.isLocationServiceEnabled()) {
      await Geolocator.openLocationSettings();
    }
  }

  Future<void> fetchInfo() async {
    final Map<String, List<String>> data = {};

    // Battery
    final battery = Battery();
    final batteryLevel = await battery.batteryLevel;
    final batteryState = await battery.batteryState;
    data['Battery'] = [
      'Level: $batteryLevel%',
      'Status: $batteryState',
    ];

    // Device Info
    final deviceInfo = await DeviceInfoPlugin().androidInfo;
    data['Device Info'] = [
      'Model: ${deviceInfo.model}',
      'Brand: ${deviceInfo.brand}',
      'Android Version: ${deviceInfo.version.release}',
      'API Level: ${deviceInfo.version.sdkInt}',
    ];

    // Connectivity
    final connectivity = await Connectivity().checkConnectivity();
    final wifi = NetworkInfo();
    final wifiName = await wifi.getWifiName();
    final wifiIP = await wifi.getWifiIP();
    data['Connectivity'] = [
      'Connection: $connectivity',
      'WiFi SSID: $wifiName',
      'WiFi IP: $wifiIP',
    ];

    // Location
    final position = await Geolocator.getCurrentPosition();
    data['Location'] = [
      'Lat: ${position.latitude}',
      'Long: ${position.longitude}',
      'Accuracy: ${position.accuracy} m',
    ];

    // Sensors
    AccelerometerEvent? accelEvent;
    accelerometerEvents.listen((event) {
      accelEvent = event;
    }).onData((_) {});

    await Future.delayed(const Duration(seconds: 1));
    if (accelEvent != null) {
      data['Accelerometer'] = [
        'x: ${accelEvent!.x}',
        'y: ${accelEvent!.y}',
        'z: ${accelEvent!.z}',
      ];
    }

    // Telephony Info
    try {
      final _flutterTelephonyInfoPlugin = TelephonyAPI();

      final telephonyData = await _flutterTelephonyInfoPlugin.getInfo();
      if (telephonyData == null || telephonyData.isEmpty) {
        data['Telephony'] = ['data: No telephony info available'];
        return;
      }
      final TelephonyInfo telephony = telephonyData.first!;
      data['Telephony'] = [
        'Carrier: ${telephony.displayName}',
        'Network Type: ${telephony.mobileNetworkCode}',
        'Signal Strength: ${telephony.cellSignalStrength} dBm',
        'SIM State: ${telephony.radioType}',
      ];
    } catch (e) {
      data['Telephony'] = ['Error fetching: $e'];
    }

    setState(() {
      infoData.clear();
      infoData.addAll(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Phone Info'), centerTitle: true),
      body: infoData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: infoData.entries.map((entry) {
                return ExpansionTile(
                  title: Text(entry.key),
                  children: entry.value
                      .map((item) => ListTile(title: Text(item)))
                      .toList(),
                );
              }).toList(),
            ),
    );
  }
}
