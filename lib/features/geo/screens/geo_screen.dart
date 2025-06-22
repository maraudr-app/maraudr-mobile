import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeoScreen extends StatefulWidget {
  const GeoScreen({super.key});

  @override
  State<GeoScreen> createState() => _GeoScreenState();
}

class _GeoScreenState extends State<GeoScreen> {
  Position? _position;
  bool _loading = false;

  Future<void> _getLocation() async {
    setState(() => _loading = true);
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La localisation est désactivée')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse && permission != LocationPermission.always) {
        return;
      }
    }

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _position = pos;
      _loading = false;
    });
  }

  Future<void> _sendLocation() async {
    if (_position == null) return;

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
    final storage = const FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    try {
      final response = await dio.post(
        '/geo/locations',
        data: {
          'latitude': _position!.latitude,
          'longitude': _position!.longitude,
          'description': 'Emplacement signalé depuis l\'app'
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Position envoyée (status: ${response.statusCode})')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'envoi : ${e.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Localisation')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_loading) const CircularProgressIndicator(),
            if (_position != null)
              Column(
                children: [
                  Text('Latitude : ${_position!.latitude}'),
                  Text('Longitude : ${_position!.longitude}'),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _sendLocation,
                    icon: const Icon(Icons.send),
                    label: const Text('Envoyer la localisation'),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _getLocation,
              icon: const Icon(Icons.refresh),
              label: const Text('Rafraîchir'),
            ),
          ],
        ),
      ),
    );
  }
}
