import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationState {
  final bool hasAsked;
  final bool hasConsent;
  final double? latitude;
  final double? longitude;
  final String? errorMessage;
  final bool isLoading;

  LocationState({
    this.hasAsked = false,
    this.hasConsent = false,
    this.latitude,
    this.longitude,
    this.errorMessage,
    this.isLoading = false,
  });

  LocationState copyWith({
    bool? hasAsked,
    bool? hasConsent,
    double? latitude,
    double? longitude,
    String? errorMessage,
    bool? isLoading,
  }) {
    return LocationState(
      hasAsked: hasAsked ?? this.hasAsked,
      hasConsent: hasConsent ?? this.hasConsent,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState()) {
    _initLocationState();
  }

  Future<void> _initLocationState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAsked = prefs.getBool('location_asked') ?? false;
    final hasConsent = prefs.getBool('location_consent') ?? false;

    state = LocationState(hasAsked: hasAsked, hasConsent: hasConsent);

    if (hasConsent) {
      await fetchCoordinates();
    }
  }

  Future<bool> requestConsent() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    
    try {
      // Check if location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await prefs.setBool('location_asked', true);
        await prefs.setBool('location_consent', false);
        state = state.copyWith(
          hasAsked: true,
          hasConsent: false,
          isLoading: false,
          errorMessage: 'Location services are disabled on this device.',
        );
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        await prefs.setBool('location_asked', true);
        await prefs.setBool('location_consent', true);
        state = state.copyWith(hasAsked: true, hasConsent: true, isLoading: false);
        await fetchCoordinates();
        return true;
      } else {
        await prefs.setBool('location_asked', true);
        await prefs.setBool('location_consent', false);
        state = state.copyWith(
          hasAsked: true,
          hasConsent: false,
          isLoading: false,
          errorMessage: 'Location permission was denied.',
        );
        return false;
      }
    } catch (e) {
      await prefs.setBool('location_asked', true);
      await prefs.setBool('location_consent', false);
      state = state.copyWith(
        hasAsked: true,
        hasConsent: false,
        isLoading: false,
        errorMessage: 'Location error: $e',
      );
      return false;
    }
  }

  Future<void> fetchCoordinates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(errorMessage: 'Location services are disabled.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 5), // Prevent hanging indefinitely
        ),
      );
      
      state = state.copyWith(
        latitude: position.latitude,
        longitude: position.longitude,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to fetch coordinates: $e');
    }
  }

  Future<void> revokeConsent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('location_asked', true);
    await prefs.setBool('location_consent', false);
    state = LocationState(hasAsked: true, hasConsent: false);
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
