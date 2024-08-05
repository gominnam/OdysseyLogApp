import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:odyssey_flutter_app/config/constants.dart';
import 'dart:convert';

import 'package:odyssey_flutter_app/models/routeImage.dart';

import '../models/odyssey.dart';

class RoutePage extends StatefulWidget {
  final RouteImage routeImage;

  const RoutePage({super.key, required this.routeImage});

  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  final Completer<NaverMapController> _mapControllerCompleter = Completer<NaverMapController>();
  late Future<Odyssey> _apiResponse;

  @override
  void initState() {
    super.initState();
    _apiResponse = fetchApiData(widget.routeImage.id);
    print("_apiResponse: $_apiResponse");
  }

  Future<Odyssey> fetchApiData(int routeId) async {
    print('fetchApiData: $routeId');
    final url = '$baseUrl/api/routes/$routeId'; // API URL
    final response = await http.get(Uri.parse(url)); // HTTP GET 요청
    if (response.statusCode == 200) {
      print('jsonEncode(response.body): ${jsonEncode(response.body)}');
      print('please...');
      final odyssey = Odyssey.fromRouteResponseJson(jsonDecode(response.body));
      print('odyssey: $odyssey');
      return odyssey;
    } else {
      throw Exception('Failed to load data'); // 실패 시 예외 발생
    }
  }

  // void _addMarkers(NaverMapController controller, List<dynamic> spots) {
  //   List<Marker> markers = [];
  //   todo: start route -> spots -> end route rendering
  //   //Future<NPoint> latLngToScreenLocation(NLatLng latLng);
  //   var marker = new naver.maps.Marker({
  //       position: new naver.maps.LatLng(37.3595704, 127.105399),
  //       map: map
  //   });
  //   for (var spot in spots) {
  //     final marker = Marker(
  //       position: LatLng(spot['latitude'], spot['longitude']),
  //       infoWindow: InfoWindow(title: spot['name']),
  //     );
  //     markers.add(marker);
  //   }
  //   controller.addMarkers(markers);
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Detail'), // route 데이터의 title 값으로 세팅
      ),
      body: FutureBuilder<Odyssey>(
        future: _apiResponse,
        builder: (context, snapshot) {
          print('snapshot: $snapshot');
          print('snapshot.data: ${jsonEncode(snapshot.data)}');
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            final odyssey = snapshot.data!;
            return NaverMap(
              onMapReady: (controller) {
                _mapControllerCompleter.complete(controller);
                _addMarkers(controller, odyssey);
              },
            );
          }
        },
      ),
    );
  }

  void _addMarkers(NaverMapController controller, Odyssey odyssey) {
    // for (final spot in spots) {
    //   final marker = Marker(
    //     markerId: MarkerId(spot['id'].toString()),
    //     position: LatLng(spot['latitude'], spot['longitude']),
    //     infoWindow: InfoWindow(title: spot['name']),
    //   );
    //   controller.addMarker(marker);
    // }
    print('!!');
    print(odyssey);
    print(odyssey.route);
    print(odyssey.spots);
  }
}