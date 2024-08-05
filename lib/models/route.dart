
class Route {
  final int? id;
  final String title;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final double totalDuration = 0;
  final double totalDistance = 0;
  String? photoUrl;

  Route({
    this.id, 
    required this.title,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    this.photoUrl,
  });

  Route.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      title = json['title'],
      startLatitude = json['startLatitude'],
      startLongitude = json['startLongitude'],
      endLatitude = json['endLatitude'],
      endLongitude = json['endLongitude'],
      photoUrl = json['photoUrl'];

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'startLatitude': startLatitude,
    'startLongitude': startLongitude,
    'endLatitude': endLatitude,
    'endLongitude': endLongitude,
    'photoUrl': photoUrl,
  };
}