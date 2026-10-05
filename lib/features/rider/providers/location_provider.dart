import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../services/api_client.dart';

class RiderLocationState {
  final double latitude;
  final double longitude;
  final double heading;
  final double speedKmh;
  final bool isTracking;
  final String currentStreet;
  final double distanceRemainingKm;
  final int etaMinutes;
  final List<Map<String, double>> routePoints;

  const RiderLocationState({
    this.latitude = 6.9034,
    this.longitude = 79.8546,
    this.heading = 45.0,
    this.speedKmh = 28.5,
    this.isTracking = false,
    this.currentStreet = 'Galle Road, Kollupitiya',
    this.distanceRemainingKm = 2.4,
    this.etaMinutes = 11,
    this.routePoints = const [
      {'lat': 6.9034, 'lng': 79.8546},
      {'lat': 6.9060, 'lng': 79.8570},
      {'lat': 6.9085, 'lng': 79.8600},
      {'lat': 6.9110, 'lng': 79.8625},
      {'lat': 6.9128, 'lng': 79.8653},
    ],
  });

  RiderLocationState copyWith({
    double? latitude,
    double? longitude,
    double? heading,
    double? speedKmh,
    bool? isTracking,
    String? currentStreet,
    double? distanceRemainingKm,
    int? etaMinutes,
    List<Map<String, double>>? routePoints,
  }) {
    return RiderLocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speedKmh: speedKmh ?? this.speedKmh,
      isTracking: isTracking ?? this.isTracking,
      currentStreet: currentStreet ?? this.currentStreet,
      distanceRemainingKm: distanceRemainingKm ?? this.distanceRemainingKm,
      etaMinutes: etaMinutes ?? this.etaMinutes,
      routePoints: routePoints ?? this.routePoints,
    );
  }
}

class LocationNotifier extends StateNotifier<RiderLocationState> {
  final ApiClient _client;
  Timer? _trackingTimer;
  int _simulationStep = 0;

  LocationNotifier(this._client) : super(const RiderLocationState());

  void startLiveTracking() {
    if (state.isTracking) return;
    state = state.copyWith(isTracking: true);

    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      _simulateMovement();
    });
  }

  void stopLiveTracking() {
    _trackingTimer?.cancel();
    _trackingTimer = null;
    state = state.copyWith(isTracking: false);
  }

  Future<void> updateCoordinates(double lat, double lng, {String? street}) async {
    state = state.copyWith(
      latitude: lat,
      longitude: lng,
      currentStreet: street ?? state.currentStreet,
    );
    await reportLocationToBackend(lat, lng);
  }

  Future<void> reportLocationToBackend(double lat, double lng) async {
    try {
      await _client.dio.patch(
        '/rider/location',
        data: {
          'latitude': lat,
          'longitude': lng,
        },
      );
    } catch (_) {
      // Quiet fail for live location updates
    }
  }

  void _simulateMovement() {
    final points = state.routePoints;
    if (points.isEmpty) return;

    _simulationStep = (_simulationStep + 1) % points.length;
    final next = points[_simulationStep];

    final remaining = (points.length - _simulationStep) * 0.6;
    final eta = ((remaining / 25) * 60).round().clamp(1, 45);

    state = state.copyWith(
      latitude: next['lat']!,
      longitude: next['lng']!,
      distanceRemainingKm: double.parse(remaining.toStringAsFixed(1)),
      etaMinutes: eta,
      speedKmh: 24.0 + (_simulationStep % 3) * 4.5,
    );

    reportLocationToBackend(next['lat']!, next['lng']!);
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, RiderLocationState>((ref) {
  return LocationNotifier(ApiClient());
});
