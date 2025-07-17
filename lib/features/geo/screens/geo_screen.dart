import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:maraudr_app/config.dart';

import '../../association/bloc/association_selector_bloc.dart';
import '../../association/bloc/association_selector_state.dart';

class GeoScreen extends StatefulWidget {
  const GeoScreen({super.key});

  @override
  State<GeoScreen> createState() => _GeoScreenState();
}

class _GeoScreenState extends State<GeoScreen> {
  Position? _position;
  bool _loading = false;
  bool _sending = false;
  final TextEditingController _descriptionController = TextEditingController();
  static const int _maxDescriptionLength = 300;
  final MapController _mapController = MapController();

  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestPermission() async {
    setState(() {
      _loading = true;
      _position = null;
    });

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La localisation est désactivée.')),
      );
      setState(() => _loading = false);
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
        setState(() => _loading = false);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Permission refusée définitivement. Activez-la dans les réglages.')),
      );
      setState(() => _loading = false);
      return;
    }

    await _getLocation();
  }

  Future<void> _getLocation() async {
    _timeoutTimer?.cancel();

    _timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_position == null && mounted) {
        _safeRedirectToHomeWithAlert();
      }
    });

    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _timeoutTimer?.cancel();

      if (!mounted) return;

      setState(() {
        _position = pos;
        _loading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          try {
            _mapController.move(
              LatLng(pos.latitude, pos.longitude),
              15.0,
            );
          } catch (e) {
            debugPrint('Erreur mapController.move : $e');
          }
        }
      });
    } catch (e) {
      _timeoutTimer?.cancel();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de localisation : $e')),
      );

      setState(() => _loading = false);
    }
  }

  void _safeRedirectToHomeWithAlert() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Localisation impossible'),
        content: const Text(
          'Impossible de récupérer votre position.\nVous allez être redirigé vers le menu.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              Future.microtask(() {
                if (mounted) {
                  _timeoutTimer?.cancel();
                  context.go('/home');
                }
              });
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendLocation() async {
    if (_position == null || _sending) return;

    setState(() => _sending = true);

    final dio = Dio(BaseOptions(baseUrl: AppConfig.baseUrlGeo));
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'jwt_token');

    try {
      final associationBloc = context.read<AssociationSelectorBloc>();
      final associationState = associationBloc.state;
      String? associationId;

      if (associationState is AssociationSelectorLoaded) {
        associationId = associationState.selectedId;
      }

      if (associationId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucune association sélectionnée.')),
        );
        setState(() => _sending = false);
        return;
      }

      final description = _descriptionController.text.trim();

      final response = await dio.post(
        '/geo',
        data: {
          'associationId': associationId,
          'latitude': _position!.latitude,
          'longitude': _position!.longitude,
          'notes': description.isNotEmpty
              ? description
              : 'Signalement depuis l\'app',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La position a bien été envoyée!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      _descriptionController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Une erreur est survenue, veuillez réessayer...'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : const LatLng(48.8566, 2.3522); // Paris

    final bool showOverallLoading = _loading || _sending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signalisation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: showOverallLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _position == null
                      ? const Center(child: Text('Position indisponible.'))
                      : FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: initialCenter,
                            initialZoom: 15.0,
                            interactionOptions: const InteractionOptions(
                              flags: InteractiveFlag.none,
                            ),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.yourcompany.maraudr_app',
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: initialCenter,
                                  width: 80,
                                  height: 80,
                                  child: const Icon(Icons.location_on,
                                      color: Colors.red, size: 40),
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Votre position actuelle:',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    if (showOverallLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_position != null) ...[
                      Text('Latitude : ${_position!.latitude}'),
                      Text('Longitude : ${_position!.longitude}'),
                    ] else ...[
                      const Text('Position non disponible.',
                          style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 30),
                    Text('Ajouter une description (optionnel):',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: _maxDescriptionLength,
                      decoration: InputDecoration(
                        hintText: 'Ex: "Bénévole rencontré à ce point"',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: (showOverallLoading || _position == null)
                          ? null
                          : _sendLocation,
                      icon: const Icon(Icons.send),
                      label: const Text('Envoyer la localisation'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: showOverallLoading ? null : _checkAndRequestPermission,
              icon: const Icon(Icons.refresh),
              label: const Text('Rafraîchir la position'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
