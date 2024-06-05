
class Spot {
  final double latitude;
  final double longitude;

  String? memo;
  List<String>? photos;

  Spot({
    required this.latitude,
    required this.longitude,
    this.memo,
    this.photos,
  }){
    photos ??= [];
  }

  // JSON 객체를 Dart 객체로 변환
  Spot.fromJson(Map<String, dynamic> json) // dynamic 변수는 런타임에 결정된다.
    : latitude = json['latitude'],
      longitude = json['longitude'],
      memo = json['memo'],
      photos = json['photos']?.cast<String>();
  
  // Dart 객체를 JSON 객체로 변환
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'memo': memo,
    'photos': photos,
  };
}