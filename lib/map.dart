import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  Future<void> _addCurrentLocation() async {
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final NLatLng spot = NLatLng(position.latitude, position.longitude);
    final NMarker marker = NMarker(id: "test", position: spot);
    _mapControllerCompleter.future.then((controller) {
      controller.addOverlay(marker);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Second Screen'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 8,
            child: NaverMap(
              onMapReady: (controller) {
                _mapControllerCompleter.complete(controller);
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: <Widget>[
                ElevatedButton(
                  child: const Text('Go back!'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  child: const Text('현재 위치를 경로에 추가하기'),
                  onPressed: _addCurrentLocation,
                ),
                ElevatedButton(
                  child: const Text('초기화'),
                  onPressed: () => {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}