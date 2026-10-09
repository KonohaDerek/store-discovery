import 'package:geolocator/geolocator.dart';

class LocationPoint {
  const LocationPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

enum LocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unknown,
}

class LocationException implements Exception {
  const LocationException(this.failure, [this.message]);

  final LocationFailure failure;
  final String? message;
}

abstract interface class LocationService {
  Future<LocationPoint> currentLocation();
}

class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<LocationPoint> currentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw const LocationException(LocationFailure.servicesDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw const LocationException(LocationFailure.permissionDenied);
      }

      if (permission == LocationPermission.deniedForever) {
        throw const LocationException(LocationFailure.permissionDeniedForever);
      }

      final position = await Geolocator.getCurrentPosition();
      return LocationPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on LocationException {
      rethrow;
    } catch (_) {
      throw const LocationException(LocationFailure.unknown);
    }
  }
}
