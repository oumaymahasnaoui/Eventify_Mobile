// lib/modules/events/widgets/location_picker.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPicker extends StatefulWidget {
  final TextEditingController locationController;
  final Function(String location, double? lat, double? lng) onLocationPicked;

  const LocationPicker({
    Key? key,
    required this.locationController,
    required this.onLocationPicked,
  }) : super(key: key);

  @override
  _LocationPickerState createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  LatLng? _selectedLocation;
  String _currentAddress = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.locationController,
          decoration: InputDecoration(
            labelText: 'Localisation',
            border: OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(Icons.map),
              onPressed: _openMapPicker,
            ),
          ),
          readOnly: true,
          onTap: _openMapPicker,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner une localisation';
            }
            return null;
          },
        ),
        SizedBox(height: 8),

        if (_selectedLocation != null)
          Text(
            'Position: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
            style: TextStyle(fontSize: 12, color: Colors.green),
          ),

        SizedBox(height: 16),

        ElevatedButton.icon(
          icon: _isLoading
              ? SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.my_location),
          label: Text('Utiliser ma position actuelle'),
          onPressed: _isLoading ? null : _getCurrentLocation,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue[50],
            foregroundColor: Colors.blue,
            minimumSize: Size(double.infinity, 50),
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Permission de localisation refusée');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showError('Permission définitivement refusée. Activez-la dans les paramètres.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _selectedLocation = LatLng(position.latitude, position.longitude);
      });

      // SIMPLIFICATION : Utiliser directement les coordonnées
      await _useCoordinatesDirectly(position.latitude, position.longitude);

    } catch (e) {
      _showError('Erreur: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openMapPicker() async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPickerScreen(
          initialLocation: _selectedLocation,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
      });
      await _useCoordinatesDirectly(result.latitude, result.longitude);
    }
  }

  // NOUVELLE MÉTHODE SIMPLIFIÉE (sans géocodage)
  Future<void> _useCoordinatesDirectly(double lat, double lng) async {
    String coordinates = '${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

    setState(() {
      _currentAddress = coordinates;
      widget.locationController.text = coordinates;
    });

    widget.onLocationPicked(coordinates, lat, lng);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }
}

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const MapPickerScreen({Key? key, this.initialLocation}) : super(key: key);

  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      _markers.add(
        Marker(
          markerId: MarkerId('selected_location'),
          position: _selectedLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sélectionner la localisation'),
        backgroundColor: Color(0xFFCE1126),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: _selectedLocation != null ? Colors.white : Colors.grey),
            onPressed: _selectedLocation != null
                ? () => Navigator.pop(context, _selectedLocation)
                : null,
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: (controller) {
          _mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: widget.initialLocation ?? LatLng(36.8065, 10.1815), // Tunis par défaut
          zoom: 12,
        ),
        onTap: (LatLng location) {
          _setSelectedLocation(location);
        },
        markers: _markers,
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        zoomControlsEnabled: true,
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.my_location),
        backgroundColor: Color(0xFFCE1126),
        onPressed: _goToCurrentLocation,
      ),
    );
  }

  void _setSelectedLocation(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId('selected_location'),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Localisation sélectionnée',
            snippet: '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
          ),
        ),
      );
    });
  }

  Future<void> _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final currentLocation = LatLng(position.latitude, position.longitude);

      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15),
      );

      _setSelectedLocation(currentLocation);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de récupérer la position actuelle')),
      );
    }
  }
}