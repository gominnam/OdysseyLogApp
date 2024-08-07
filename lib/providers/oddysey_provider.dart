import 'package:flutter/material.dart';
import 'package:odyssey_flutter_app/models/odyssey.dart';
import 'package:http/http.dart' as http;
import 'package:odyssey_flutter_app/config/constants.dart';
import 'dart:convert';

class OdysseyProvider with ChangeNotifier {
  List<Odyssey> _odysseys = [];

  List<Odyssey> get odysseys => _odysseys;

  Future<void> fetchOdysseyData(int id) async {
    // Check if the data is already fetched
    if (_odysseys.any((odyssey) => odyssey.route.id == id)) {
      return;
    }

    // Fetch data from API
    final odyssey = await fetchFromApi(id);
    _odysseys.add(odyssey);
    notifyListeners();
  }

  Odyssey? getOdysseyById(int id) {
    try {
      return _odysseys.firstWhere((odyssey) => odyssey.route.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<Odyssey> fetchFromApi(int id) async {
    print('_fetchOdysseyData: $id');
    final url = '$baseUrl/api/routes/$id';
    final response = await http.get(Uri.parse(url)); // HTTP GET 요청
    if (response.statusCode == 200) {
      print('utf8: ${jsonDecode(utf8.decode(response.bodyBytes))}');
      final odyssey = Odyssey.fromRouteResponseJson(jsonDecode(utf8.decode(response.bodyBytes)));
      return odyssey;
    } else {
      throw Exception('Failed to load data');
    }
  }
}