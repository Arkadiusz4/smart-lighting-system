import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:wifi_iot/wifi_iot.dart';

class ConfigureNetworkScreen extends StatefulWidget {
  const ConfigureNetworkScreen({super.key});

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
    bool reachable = await isHostReachable('192.168.4.1');
    if (!reachable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ESP32 niedostępne. Upewnij się, że jesteś połączony z ESP32.')),
      );
      return;
    }

    final ssid = ssidController.text.trim();
    final password = passwordController.text.trim();

    print('Próba wysłania danych: SSID="$ssid", PASSWORD="$password"');

    if (ssid.isEmpty || password.isEmpty) {
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
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: '{"ssid": "$ssid", "password": "$password"}',
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dane wysłane do ESP32')),
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
      if (errorMsg.contains('Software caused connection abort')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dane wysłane do ESP32')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wystąpił błąd: $e')),
        );
        return;
      }
    } finally {
      await WiFiForIoTPlugin.forceWifiUsage(false);
      await WiFiForIoTPlugin.disconnect();
      setState(() {
        isSending = false;
      });
      Navigator.pop(context);
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
