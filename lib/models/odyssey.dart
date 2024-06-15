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
}