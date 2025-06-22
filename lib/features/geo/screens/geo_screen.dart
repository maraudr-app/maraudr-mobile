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

  Future<void> _checkAndRequestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La localisation est désactivée.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission refusée.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission refusée définitivement. Activez-la dans les réglages.')),
      );
      return;
    }

    await _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() => _loading = true);

    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de localisation : ${e.toString()}')),
      );
    }

    if (!mounted) return;
    setState(() {
      _position = pos;
      _loading = false;
    });
  }

  Future<void> _sendLocation() async {
    if (_position == null) return;

    final dio = Dio(BaseOptions(baseUrl: 'http://localhost:8000'));
    const storage = FlutterSecureStorage();
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Position envoyée (status: ${response.statusCode})')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'envoi : ${e.toString()}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
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
              onPressed: _checkAndRequestPermission,
              icon: const Icon(Icons.refresh),
              label: const Text('Rafraîchir'),
            ),
          ],
        ),
      ),
    );
  }
}
