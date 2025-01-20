import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_app/blocs/boards/board_bloc.dart';
import 'package:mobile_app/screens/device_screens/others/configure_network_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ScanEsp32ScreenEditWifi extends StatefulWidget {
  const ScanEsp32ScreenEditWifi({super.key});

  @override
  _ScanEsp32ScreenEditWifiState createState() => _ScanEsp32ScreenEditWifiState();
}

class _ScanEsp32ScreenEditWifiState extends State<ScanEsp32ScreenEditWifi> {
  List<String> espNetworks = [];
  bool isLoading = false;

  String? userId;
  String? boardId;
  String? clientId;
  String? mqttPassword;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    requestLocationPermission().then((_) {
      scanForEspNetworks();
    });
    fetchDataFromFirebase();
  }

  Future<void> fetchDataFromFirebase() async {
    if (userId == null) return;
    try {
      final firestore = FirebaseFirestore.instance;
      final boardQuery = await firestore.collection('boards').where('assigned_to', isEqualTo: userId).limit(1).get();
      if (boardQuery.docs.isNotEmpty) {
        boardId = boardQuery.docs.first.id;
        print('Pobrano boardId: $boardId');
      }

      if (boardId != null) {
        final snapshot = await firestore
            .collection('mqtt_clients')
            .where('boardId', isEqualTo: boardId)
            .where('userId', isEqualTo: userId)
            .limit(1)
            .get();
        if (snapshot.docs.isNotEmpty) {
          final data = snapshot.docs.first.data();
          clientId = data['clientId'] ?? data['userId'];
          mqttPassword = data['mqtt_password'];
          print('Pobrano dane MQTT: clientId=$clientId, mqttPassword=$mqttPassword');
        } else {
          print('Nie znaleziono danych MQTT dla boardId=$boardId, userId=$userId');
        }
      }
    } catch (e) {
      print('Błąd podczas pobierania danych z Firebase: $e');
    }
  }

  Future<void> requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isGranted) {
      print('permission granted');
    } else if (status.isDenied) {
      print('permission denied');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uprawnienia lokalizacji są wymagane do działania funkcji.'),
        ),
      );
    } else if (status.isPermanentlyDenied) {
      print('permission permanently denied');
      openAppSettings();
    }
  }

  Future<void> scanForEspNetworks() async {
    if (!await Permission.location.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brak uprawnień lokalizacji')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await WiFiScan.instance.startScan();
      final canScanResult = await WiFiScan.instance.canStartScan();
      print('Czy można rozpocząć skanowanie? $canScanResult');

      List<WiFiAccessPoint> networks = await WiFiScan.instance.getScannedResults();
      print('Znalezione sieci: ${networks.map((e) => e.ssid).toList()}');

      setState(() {
        espNetworks = networks.map((e) => e.ssid).where((ssid) => ssid.isNotEmpty).toList();
      });
    } catch (e) {
      print('Błąd podczas skanowania: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Błąd podczas skanowania: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> connectToEspNetwork(String ssid) async {
    String? password = await showDialog<String>(
      context: context,
      builder: (context) {
        String pwd = '';
        return AlertDialog(
          title: Text('Wprowadź hasło dla $ssid'),
          content: TextField(
            autofocus: true,
            obscureText: true,
            style: const TextStyle(color: Colors.black),
            decoration: const InputDecoration(
              labelText: 'Hasło',
            ),
            onChanged: (value) {
              pwd = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(pwd);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (password == null || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nie podano hasła.')),
      );
      return;
    }

    print('Próba połączenia z siecią: $ssid przy użyciu hasła: $password');
    bool connected = await WiFiForIoTPlugin.connect(
      ssid,
      password: password,
      security: NetworkSecurity.WPA,
    );

    print('Aktualnie połączono z: ${await WiFiForIoTPlugin.getSSID()}');

    if (connected) {
      print('Połączenie z $ssid udane.');
      await WiFiForIoTPlugin.forceWifiUsage(true);
      await Future.delayed(const Duration(seconds: 5));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfigureNetworkScreen(
            clientId: clientId,
            mqttPassword: mqttPassword,
            boardId: boardId,
            userId: userId,
            boardsBloc: BlocProvider.of<BoardsBloc>(context),
          ),
        ),
      );
    } else {
      print('Nie udało się połączyć z $ssid');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nie udało się połączyć z $ssid')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wyszukaj ESP32'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: espNetworks.length,
              itemBuilder: (context, index) {
                final ssid = espNetworks[index];
                return ListTile(
                  title: Text(
                    ssid,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  onTap: () => connectToEspNetwork(ssid),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: scanForEspNetworks,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
