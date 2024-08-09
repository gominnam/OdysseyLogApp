import 'package:flutter/material.dart';
import 'package:odyssey_flutter_app/models/odyssey.dart';
import 'package:http/http.dart' as http;
import 'package:odyssey_flutter_app/config/constants.dart';
import 'dart:convert';

import 'package:odyssey_flutter_app/models/spot.dart';

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

    // Fetch presigned URL for spots images
    final presignedUrls = await fetchPresignedUrls(odyssey.spots);

    for (var spot in odyssey.spots) {
      if (spot.photos != null) {
        final spotPresignedUrls = presignedUrls[spot.id];
        if (spotPresignedUrls != null) {
          for (var i = 0; i < spot.photos!.length; i++) {
            spot.photos![i].presignedUrl = spotPresignedUrls[i];
          }
        }
      }
    }

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
    final url = '$baseUrl/api/routes/$id';
    final response = await http.get(Uri.parse(url)); // HTTP GET 요청
    if (response.statusCode == 200) {
      final odyssey = Odyssey.fromRouteResponseJson(jsonDecode(utf8.decode(response.bodyBytes)));
      return odyssey;
    } else {
      throw Exception('Failed to load data');
    }
  }

  Future<Map<String, List<String?>?>> fetchPresignedUrls(List<Spot> spots) async {
    final spotRequests = spots.map((spot) {
      return {
        'id': spot.id,
        'photos': spot.photos?.map((photo) => {
          'url': photo.url,
        }).toList() ?? [],
      };
    }).toList();

    final response = await http.post(
      Uri.parse('$baseUrl/api/spots/photos'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(spotRequests),
    );

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = jsonDecode(response.body);
      final List<Spot> responseData = jsonData.map((json) => Spot.fromJson(json)).toList();

      return {
        for (var item in responseData)
          item.id: item.photos?.map((photo) => photo.presignedUrl).toList()
      };
    } else {
      throw Exception('Failed to fetch presigned URLs');
    }
  }
}