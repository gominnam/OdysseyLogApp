import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:http/http.dart' as http;
import 'package:odyssey_flutter_app/config/constants.dart';
import 'dart:convert';

import 'package:odyssey_flutter_app/models/routeImage.dart';
import 'package:odyssey_flutter_app/providers/oddysey_provider.dart';
import 'package:provider/provider.dart';

import '../models/odyssey.dart';

class RoutePage extends StatefulWidget {
  final RouteImage routeImage;

  const RoutePage({Key? key, required this.routeImage}) : super(key: key);

  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  final Completer<NaverMapController> _mapControllerCompleter = Completer<NaverMapController>();
  late Future<Odyssey> _apiResponse;

  @override
  void initState() {
    super.initState();
    final odysseyProvider = Provider.of<OdysseyProvider>(context, listen: false);
    if (odysseyProvider.odyssey == null) {
      _apiResponse = _fetchOdysseyData(widget.routeImage.id);
      _apiResponse.then((odyssey) {
        odysseyProvider.setOdyssey(odyssey);
      });
    } else {
      _apiResponse = Future.value(odysseyProvider.odyssey);
    }
  }

  Future<Odyssey> _fetchOdysseyData(int routeId) async {
    print('_fetchOdysseyData: $routeId');
    final url = '$baseUrl/api/routes/$routeId'; // API URL
    final response = await http.get(Uri.parse(url)); // HTTP GET 요청
    if (response.statusCode == 200) {
      print('utf8: ${jsonDecode(utf8.decode(response.bodyBytes))}');
      final odyssey = Odyssey.fromRouteResponseJson(jsonDecode(utf8.decode(response.bodyBytes)));
      return odyssey;
    } else {
      throw Exception('Failed to load data'); // 실패 시 예외 발생
    }
  }

  @override
  Widget build(BuildContext context) {
    final odysseyProvider = Provider.of<OdysseyProvider>(context);
    final odyssey = odysseyProvider.odyssey;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          odyssey?.route.title ?? 'Loading...',
          style: TextStyle(fontFamily: 'NotoSansKR',
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: FutureBuilder<Odyssey>(
        future: _apiResponse,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.connectionState == ConnectionState.done) {
            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: Text('No data available'));
            } else {
              final odyssey = snapshot.data!;
              Provider.of<OdysseyProvider>(context, listen: false).setOdyssey(odyssey);
              return NaverMap(
                onMapReady: (controller) {
                  _mapControllerCompleter.complete(controller);
                  _addMarkers(controller, odyssey);
                },
              );
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  void _addMarkers(NaverMapController controller, Odyssey odyssey) {
    // List<NMarker> markers = [];
    Set<NMarker> markers = {};
    
    final route = odyssey.route;
    final NMarker startMarker = NMarker(
      id: 'start',
      position: NLatLng(route.startLatitude, route.startLongitude)
    );
    markers.add(startMarker);

    for (final spot in odyssey.spots) {
      final NMarker marker = NMarker(id: spot.id, position: spot.position);
      markers.add(marker);
      // controller.addOverlay(marker);
    }

    final NMarker endMarker = NMarker(
      id: 'end',
      position: NLatLng(route.endLatitude, route.endLongitude)
    );
    markers.add(endMarker);

    controller.addOverlayAll(markers);
    moveMapSpot(controller, markers);
    addPolylineToMap(markers, controller);

    print(odyssey.route);
    print(odyssey.spots);
  }

  Future<void> moveMapSpot(NaverMapController controller, Set<NMarker> markers) async {
    final List<NMarker> markerList = markers.toList();
    final int middleIndex = markerList.length ~/ 2;
    final NMarker middleMarker = markerList[middleIndex];
    controller.updateCamera(NCameraUpdate.scrollAndZoomTo(target: middleMarker.position, zoom: 18));
  }

  void addPolylineToMap(Set<NMarker> markers, NaverMapController controller) {
    final List<NLatLng> positions = markers.map((marker) => marker.position).toList();
    final NPolylineOverlay polyline = NPolylineOverlay(
      id: 'route_polyline',
      coords: positions,
      color: Colors.blue,
      width: 5,
    );
    
    controller.addOverlay(polyline);
  }
}