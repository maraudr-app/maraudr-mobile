import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maraudr_app/features/association/bloc/association_selector_bloc.dart';
import 'package:maraudr_app/features/association/bloc/association_selector_state.dart';

import '../../../config.dart';

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  String? _lastCode;
  bool _sending = false;

  Future<void> _sendToApi(String code, String? token) async {
    setState(() => _sending = true);

    final associationBloc = context.read<AssociationSelectorBloc>();
    final associationState = associationBloc.state;
    String? associationId;

    if (associationState is AssociationSelectorLoaded) {
      associationId = associationState.selectedId;
    }

    if (token == null || associationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue, veuillez réessayer'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),      );
      setState(() => _sending = false);
      return;
    }

    final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrlStock));

    try {
      await dio.post(
        '/item/$code',
        data: {
          'associationId': associationId,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item ajouté au stock'),
          backgroundColor: Colors.green,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.data is Map && e.response?.data['message'] != null) {
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue, veuillez réessayer'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue, veuillez réessayer'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),      );
    }

    setState(() => _sending = false);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un article'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              onDetect: (capture) async {
                final barcode = capture.barcodes.first;
                if (barcode.rawValue != null &&
                    barcode.rawValue != _lastCode &&
                    !_sending) {
                  _lastCode = barcode.rawValue!;

                  const storage = FlutterSecureStorage();
                  final token = await storage.read(key: 'jwt_token');

                  await _sendToApi(_lastCode!, token);

                  await Future.delayed(const Duration(seconds: 1));
                  setState(() {
                    _lastCode = null;
                  });
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