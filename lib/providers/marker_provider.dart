// lib/providers/marker_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class MarkerProvider with ChangeNotifier {
  final List<NLatLng> _locations = [];
  final List<NMarker> _markers = [];

  List<NLatLng> get locations => _locations;
  List<NMarker> get markers => _markers;

  void addLocation(NLatLng location) {
    _locations.add(location);
    notifyListeners();
  }

  void addMarker(NMarker marker) {
    _markers.add(marker);
    notifyListeners();
  }

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }
}