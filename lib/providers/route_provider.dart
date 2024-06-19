import 'dart:convert';

import 'package:odyssey_flutter_app/models/route.dart';
import 'package:flutter/foundation.dart';

class RouteProvider with ChangeNotifier {
  String? _routeTitle;
  String? _routePhotoUrl;

  String? get routeTitle => _routeTitle;
  String? get routePhotoUrl => _routePhotoUrl;

  void updateRouteTitle(String? newTitle) {
    _routeTitle = newTitle;
    notifyListeners();
  }

  void updateRoutePhotoUrl(String? newUrl) {
    _routePhotoUrl = newUrl;
    notifyListeners();
  }

  List<Route> _routes = [];

  List<Route> get routes => _routes;

  void addRoute(Route route) {
    _routes.add(route);
    notifyListeners();
  }

  void removeRoute(Route route) {
    _routes.remove(route);
    notifyListeners();
  }

  Route getRoute(int index) {
    return _routes[index];
  }

  void loadRoutesFromJson(String jsonString) {
    List<dynamic> jsonData = jsonDecode(jsonString);
    _routes = jsonData.map((json) => Route.fromJson(json)).toList();
    notifyListeners();
  }

  String saveRoutesToJson() {
    List<Map<String, dynamic>> jsonData = _routes.map((route) => route.toJson()).toList();
    return jsonEncode(jsonData);
  }
}
