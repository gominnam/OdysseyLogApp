// import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:odyssey_flutter_app/models/photo.dart';
import 'package:uuid/uuid.dart';

class Spot {
  final String id;
  final NLatLng position;

  String? memo;
  List<Photo>? photos;

  Spot({
    required this.position,
    this.memo,
    this.photos,
  }) : id = const Uuid().v4() {
    photos ??= [];
  }

  // JSON 객체를 Dart 객체로 변환
  Spot.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      position = NLatLng(json['latitude'], json['longitude']),
      memo = json['memo'],
      photos = (json['photos'] as List<dynamic>?)
          ?.map((item) => Photo.fromJson(item as Map<String, dynamic>))
          .toList();
  
  // Dart 객체를 JSON 객체로 변환
  Map<String, dynamic> toJson() => {
    'id': id,
    'latitude': position.latitude,
    'longitude': position.longitude,
    'memo': memo,
    'photoSize': photos!.length,
  };
}