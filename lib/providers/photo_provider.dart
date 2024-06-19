import 'package:flutter/foundation.dart';
import 'package:odyssey_flutter_app/models/photo.dart';

class PhotoProvider with ChangeNotifier {
  final List<Photo> _photos = [];
  List<Photo> get photos => _photos;

  void addPhoto(Photo photo) {
    _photos.add(photo);
    notifyListeners();
  }
}
