import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:odyssey_flutter_app/providers/marker_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<NaverMapController> _mapControllerCompleter = Completer();
  // final List<NLatLng> _locations = []; // 과거 위치들을 저장할 리스트
  // final List<NMarker> _markers = []; // 마커들을 저장할 리스트

  Future<void> _addCurrentLocation() async {
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    final NLatLng spot = NLatLng(position.latitude, position.longitude);
    final String markerId = Uuid().v1();
    final NMarker marker = NMarker(id: markerId, position: spot);

    // _locations.add(spot); // 현재 위치를 리스트에 추가
    // _markers.add(marker); // 마커를 리스트에 추가

    Provider.of<MarkerProvider>(context, listen: false).addLocation(spot);
    Provider.of<MarkerProvider>(context, listen: false).addMarker(marker);

    _mapControllerCompleter.future.then((controller) {
      controller.addOverlay(marker);
    });
  }

  @override
  Widget build(BuildContext context) {
    final markerProvider = Provider.of<MarkerProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 여정'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 8,
            child: NaverMap(
              onMapReady: (controller) {
                _mapControllerCompleter.complete(controller);
                markerProvider.markers.forEach((marker) { // 저장된 모든 마커를 맵에 추가
                  controller.addOverlay(marker);
              });
              },
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                ElevatedButton(
                  child: const Text('back'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                ElevatedButton(
                  onPressed: _addCurrentLocation,
                  child: const Text('경로 추가'),
                ),
                ElevatedButton(
                  child: const Text('초기화'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('마커 삭제'),
                          content: Text('모든 마커를 삭제하시겠습니까?'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('아니오'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text('예'),
                              onPressed: () async {
                                Provider.of<MarkerProvider>(context, listen: false).clearMarkers();
                                final controller = await _mapControllerCompleter.future;
                                controller.clearOverlays();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                )
                // ElevatedButton(
                //   child: const Text('초기화'),
                //   onPressed: () async {
                //     Provider.of<MarkerProvider>(context, listen: false).clearMarkers();
                //     final controller = await _mapControllerCompleter.future;
                //     controller.clearOverlays();
                //   },
                // )
              ],
            ),
          ),
        ],
      ),
    );
  }
}