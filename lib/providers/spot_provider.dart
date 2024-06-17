// lib/providers/spot_provider.dart

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:odyssey_flutter_app/models/spot.dart';
import 'package:odyssey_flutter_app/models/photo.dart';
// import 'package:flutter_naver_map/flutter_naver_map.dart';

// class Spot {
//   final String id;
//   final NLatLng position;
//   String? memo;
//   List<String>? photos;

//   Spot({
//     required this.id, 
//     required this.position, 
//     this.memo,
//     this.photos,
//   }){
//     photos ??= [];
//   }
// }

class SpotProvider with ChangeNotifier {
  
  final List<Spot> _spots = [];

  List<Spot> get spots => _spots;

  void addSpot(Spot spot) {
    _spots.add(spot);
    notifyListeners();
  }

  void removeSpot(String id) {
    _spots.removeWhere((spot) => spot.id == id);
    notifyListeners();
  }

  void clearSpots() {
    _spots.clear();
    notifyListeners();
  }

  void updateMemo(String id, String memo) {
    final spot = _spots.firstWhere((spot) => spot.id == id);
    spot.memo = memo;
    notifyListeners();
  }

  void addPhoto(String id, Photo photo) {
    final spot = _spots.firstWhere((spot) => spot.id == id);
    spot.photos!.add(photo);
    notifyListeners();
  }

  void removePhoto(String id, Photo photo) {
    final spot = _spots.firstWhere((spot) => spot.id == id);
    spot.photos!.remove(photo);
    notifyListeners();
  }

  Spot getSpot(String id) {
    return _spots.firstWhere((spot) => spot.id == id);
  }

  List<Spot> getAllSpots() {
    return _spots;
  }

  List<Photo> getAllPhotos() {
    final photos = <Photo>[];
    for (final spot in _spots) {
      photos.addAll(spot.photos!);
    }
    return photos;
  }

  File? getPhotoFile(String id, int index) {
    final spot = _spots.firstWhere((spot) => spot.id == id);
    final photo = spot.photos![index];
    return File(photo.path);
  }
}
