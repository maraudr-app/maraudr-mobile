import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart'; // Import flutter_map
import 'package:latlong2/latlong.dart'; // Import latlong2 for LatLng

import '../../association/bloc/association_selector_bloc.dart';
import '../../association/bloc/association_selector_state.dart';

class GeoScreen extends StatefulWidget {
  const GeoScreen({super.key});

  @override
  State<GeoScreen> createState() => _GeoScreenState();
}

class _GeoScreenState extends State<GeoScreen> {
  Position? _position;
  bool _loading = false; // For fetching location
  bool _sending = false; // For sending location data to backend
  final TextEditingController _descriptionController = TextEditingController();
  static const int _maxDescriptionLength = 300;

  final MapController _mapController = MapController(); // Controller for flutter_map

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermission();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _checkAndRequestPermission() async {
    setState(() {
      _loading = true; // Set loading state when checking/requesting permission
      _position = null; // Clear previous position
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
    Position? pos;
    try {
      pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur de localisation : ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _position = pos;
          _loading = false; // Set loading to false regardless of success
        });
        if (_position != null) {
          _mapController.move(
            LatLng(_position!.latitude, _position!.longitude),
            15.0, // Zoom level adjusted for better visibility of a local area
          );
        }
      }
    }
  }

  Future<void> _sendLocation() async {
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune position disponible à envoyer.')),
      );
      return;
    }

    if (_sending) return; // Prevent multiple taps

    setState(() => _sending = true);

    final dio = Dio(BaseOptions(baseUrl: 'http://10.66.125.76:8084'));
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
          'notes': description.isNotEmpty ? description : 'Emplacement signalé depuis l\'app',
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Position envoyée (status: ${response.statusCode})')),
      );
      _descriptionController.clear();
    } on DioException catch (e) {
      if (!mounted) return;
      String message = 'Erreur d\'envoi: ${e.message}';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        message = e.response?.data['message'];
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur inattendue: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default camera position if _position is null (e.g., initial load)
    // Using Paris, France coordinates as a sensible default since you're in France
    final initialCenter = _position != null
        ? LatLng(_position!.latitude, _position!.longitude)
        : const LatLng(48.8566, 2.3522); // Default to Paris, France

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
            // Map Section
            Container(
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: showOverallLoading
                  ? const Center(child: CircularProgressIndicator()) // Spinner for map area
                  : _position == null
                  ? const Center(child: Text('Impossible d\'afficher la carte sans position.'))
                  : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 15.0, // Zoom level on map initialization
                  maxZoom: 18.0,
                  minZoom: 2.0,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.yourcompany.maraudr_app',
                  ),
                  if (_position != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(_position!.latitude, _position!.longitude),
                          width: 80,
                          height: 80,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Main content section (position details, description, buttons)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Votre position actuelle:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    // Show position or a loading/unavailable message
                    if (showOverallLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_position != null) ...[
                      Text('Latitude : ${_position!.latitude}', style: Theme.of(context).textTheme.bodyLarge),
                      Text('Longitude : ${_position!.longitude}', style: Theme.of(context).textTheme.bodyLarge),
                    ] else ...[
                      const Text('Position non disponible.', style: TextStyle(fontStyle: FontStyle.italic)),
                    ],
                    const SizedBox(height: 30),
                    Text(
                      'Ajouter une description (optionnel):',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      maxLength: _maxDescriptionLength,
                      decoration: InputDecoration(
                        hintText: 'Ex: "Bénévole rencontré à ce point"',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton.icon(
                      onPressed: (showOverallLoading || _position == null) ? null : _sendLocation,
                      icon: const Icon(Icons.send),
                      label: const Text('Envoyer la localisation'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Refresh Button (always visible at the bottom)
            ElevatedButton.icon(
              onPressed: showOverallLoading ? null : _checkAndRequestPermission,
              icon: const Icon(Icons.refresh),
              label: const Text('Rafraîchir la position'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}