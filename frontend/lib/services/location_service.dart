import 'dart:async';
import 'dart:html' as html;

class UserLocation {
  final double latitude;
  final double longitude;

  const UserLocation(this.latitude, this.longitude);
}

class LocationException implements Exception {
  final String message;

  const LocationException(this.message);

  @override
  String toString() => message;
}

Future<UserLocation> getUserLocation() async {
  try {
    final position = await html.window.navigator.geolocation
        .getCurrentPosition()
        .timeout(const Duration(seconds: 8));
    final latitude = position.coords?.latitude;
    final longitude = position.coords?.longitude;
    if (latitude == null || longitude == null) {
      throw const LocationException('Location coordinates were not available.');
    }
    return UserLocation(latitude.toDouble(), longitude.toDouble());
  } on html.DomException {
    throw const LocationException(
        'Location permission is required to sign in. Please allow location access and try again.');
  } on TimeoutException {
    throw const LocationException(
        'Could not get your location. Please try signing in again.');
  }
}
