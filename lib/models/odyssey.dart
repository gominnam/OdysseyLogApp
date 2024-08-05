import 'package:odyssey_flutter_app/models/route.dart';
import 'package:odyssey_flutter_app/models/spot.dart';

class Odyssey {
  final Route route;
  final List<Spot> spots;

  Odyssey({
    required this.route,
    required this.spots,
  });

  Map<String, dynamic> toJson() => {
    'route': route.toJson(),
    'spots': spots.map((spot) => spot.toJson()).toList(),
  };

  factory Odyssey.fromJson(Map<String, dynamic> json) {
    return Odyssey(
      route: Route.fromJson(json['route']),
      spots: (json['spots'] as List<dynamic>)
          .map((item) => Spot.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  factory Odyssey.fromRouteResponseJson(Map<String, dynamic> json) {
    return Odyssey(
      route: Route.fromJson(json),
      spots: (json['spots'] as List<dynamic>)
          .map((item) => Spot.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
