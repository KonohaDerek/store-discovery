import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../api/discovery_api_client.dart';

class StoreMapView extends StatelessWidget {
  const StoreMapView({
    super.key,
    required this.coordinates,
    required this.markerId,
    required this.markerTitle,
    required this.semanticsLabel,
  });

  final StoreCoordinates coordinates;
  final String markerId;
  final String markerTitle;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final target = LatLng(coordinates.latitude, coordinates.longitude);
    return Semantics(
      label: semanticsLabel,
      image: true,
      child: SizedBox(
        height: 240,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(target: target, zoom: 15),
            markers: {
              Marker(
                markerId: MarkerId(markerId),
                position: target,
                infoWindow: InfoWindow(title: markerTitle),
              ),
            },
            compassEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
        ),
      ),
    );
  }
}
