import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/screens/device_screens/devices_screen.dart';
import 'package:wifi_iot/wifi_iot.dart';

class ConfigureNetworkScreen extends StatefulWidget {
  final String? clientId;
  final String? mqttPassword;
  final String? boardId;
  final String? userId;

  const ConfigureNetworkScreen({
    super.key,
    this.clientId,
    this.mqttPassword,
    this.boardId,
    this.userId,
  });

  @override
  _ConfigureNetworkScreenState createState() => _ConfigureNetworkScreenState();
}

class _ConfigureNetworkScreenState extends State<ConfigureNetworkScreen> {
  final TextEditingController ssidController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isSending = false;

  Future<bool> isHostReachable(String host, {int port = 80, Duration timeout = const Duration(seconds: 5)}) async {
    try {
      final socket = await Socket.connect(host, port, timeout: timeout);
      socket.destroy();
      print('Host $host jest osiągalny');
      return true;
    } catch (e) {
      print('Nie można osiągnąć hosta $host: $e');
      return false;
    }
  }

  Future<void> sendNetworkCredentials() async {
    print('Sprawdzanie dostępności hosta ESP32...');
    bool reachable = await isHostReachable('192.168.4.1');
    print('Host ESP32 osiągalny: $reachable');

    if (!reachable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ESP32 niedostępne. Upewnij się, że jesteś połączony z ESP32.')),
      );
      return;
    }

    final ssid = ssidController.text.trim();
    final wifiPassword = passwordController.text.trim();
    print('SSID: $ssid, WiFi Password: $wifiPassword');

    if (ssid.isEmpty || wifiPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proszę podać SSID i hasło')),
      );
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      final url = Uri.parse('http://192.168.4.1');
      final body = jsonEncode({
        "ssid": ssid,
        "password": wifiPassword,
        "clientId": widget.clientId,
        "mqttPassword": widget.mqttPassword,
      });

      print('Wysyłanie danych do ESP32: $body');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print('Odpowiedź z ESP32: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dane wysłane do ESP32')),
        );

        // Navigate to the Boards screen after a successful response
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>const DevicesScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Błąd konfiguracji: ${response.statusCode}')),
        );
        return;
      }
    } catch (e) {
      String errorMsg = e.toString();
      print('Błąd podczas wysyłania danych: $errorMsg');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wystąpił błąd: $errorMsg')),
      );
    } finally {
      print('Rozłączanie i czyszczenie połączeń Wi-Fi...');
      await WiFiForIoTPlugin.forceWifiUsage(false);
      await WiFiForIoTPlugin.disconnect();
      setState(() {
        isSending = false;
      });
      print('Zakończono wysyłanie danych.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfiguracja sieci domowej'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: ssidController,
              decoration: const InputDecoration(labelText: 'SSID sieci domowej'),
            ),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(labelText: 'Hasło'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            isSending
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: sendNetworkCredentials,
              child: const Text('Wyślij dane do ESP32'),
            ),
          ],
        ),
      ),
    );
  }
}
