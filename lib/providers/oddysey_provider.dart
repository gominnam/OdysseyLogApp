import 'package:flutter/material.dart';
import 'package:odyssey_flutter_app/models/odyssey.dart';

class OdysseyProvider with ChangeNotifier {
  Odyssey? _odyssey;

  Odyssey? get odyssey => _odyssey;

  void setOdyssey(Odyssey odyssey) {
    _odyssey = odyssey;
    notifyListeners();
  }
}