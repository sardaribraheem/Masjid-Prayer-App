import 'dart:math' as math;

/// Shared distance calculation utilities
/// Consolidates the Haversine formula that was duplicated in
/// firebase_service.dart and location_service.dart
class DistanceUtils {
  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  static double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  /// Format distance for display
  /// Returns "Xm" if < 1km, "X.Xkm" otherwise
  static String formatDistance(double? distance) {
    if (distance == null) return 'Unknown';
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    }
    return '${distance.toStringAsFixed(1)}km';
  }

  static double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }
}
