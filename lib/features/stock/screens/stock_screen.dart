import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String? _lastCode;
  bool _sending = false;

  Future<void> _sendToApi(String code) async {
    setState(() => _sending = true);
    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    try {
      final response = await dio.post(
        '/associations/1/stock/items',
        data: {'barcode': code},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Code envoyé : ${response.statusCode}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${e.toString()}')),
      );
    }

    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner un article')),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null && barcode.rawValue != _lastCode && !_sending) {
                  _lastCode = barcode.rawValue!;
                  _sendToApi(_lastCode!);
                }
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(),
          const SizedBox(height: 12),
          if (_lastCode != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Dernier code : $_lastCode'),
            ),
        ],
      ),
    );
  }
}
