import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

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
  late Future<void> _apiResponse;
  Set<NMarker> _markers = {};
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    final odysseyProvider = Provider.of<OdysseyProvider>(context, listen: false);
    _apiResponse = odysseyProvider.fetchOdysseyData(widget.routeImage.id);
    
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _apiResponse,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Loading...',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Error',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
            body: Center(child: Text('Error loading data')),
          );
        } else {
          final odysseyProvider = Provider.of<OdysseyProvider>(context);
          final odyssey = odysseyProvider.getOdysseyById(widget.routeImage.id);
          return Scaffold(
            appBar: AppBar(
              title: Text(
                odyssey?.route.title ?? 'No Title',
                style: TextStyle(
                  fontFamily: 'NotoSansKR',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Colors.black,
                ),
              ),
            ),
            body: odyssey != null
                ? NaverMap(
                  onMapReady: (controller) {
                    _mapControllerCompleter.complete(controller);
                    _initializationMarker(odyssey);
                    controller.addOverlayAll(_markers);
                    _moveMapSpot(controller);
                    _addMarkerInfo(controller, _markers, odyssey);
                    _addPolylineToMap(controller);
                  },
                  // markers: _markers,
                )
                : Center(child: Text('Error loading data')),
          );
        }
      },
    );
  }

  void _initializationMarker(Odyssey odyssey){
    final route = odyssey.route;
    final NMarker startMarker = NMarker(
      id: 'start',
      position: NLatLng(route.startLatitude, route.startLongitude),
    );
    _markers.add(startMarker);

    for (final spot in odyssey.spots) {
      final NMarker marker = NMarker(id: spot.id, position: spot.position);
      _markers.add(marker);
    }

    final NMarker endMarker = NMarker(
      id: 'end',
      position: NLatLng(route.endLatitude, route.endLongitude)
    );
    _markers.add(endMarker); 
  }

  Future<void> _moveMapSpot(NaverMapController controller) async {
    final List<NMarker> markerList = _markers.toList();
    final int middleIndex = markerList.length ~/ 2;
    final NMarker middleMarker = markerList[middleIndex];
    controller.updateCamera(NCameraUpdate.scrollAndZoomTo(target: middleMarker.position, zoom: 16));
  }

  void _addMarkerInfo(NaverMapController controller, Set<NMarker> markers, Odyssey odyssey) {
    final List<NMarker> markerList = markers.toList();
    if (markerList.isEmpty) return;

    final NMarker startMarker = markerList.first;
    final onStartMarkerInfoWindow = NInfoWindow.onMarker(id: startMarker.info.id, text: 'Start');
    startMarker.openInfoWindow(onStartMarkerInfoWindow);

    // 끝 마커에 "End" 텍스트 추가
    final NMarker endMarker = markerList.last;
    final onEndMarkerInfoWindow = NInfoWindow.onMarker(id: endMarker.info.id, text: 'End');
    endMarker.openInfoWindow(onEndMarkerInfoWindow);

    // 중간 마커들에 대한 기존 로직 유지
    if (markerList.length <= 2) return; // 마커가 2개 이하인 경우 처리할 필요 없음
    final List<NMarker> filteredMarkers = markerList.sublist(1, markerList.length - 1);
    for (final marker in filteredMarkers) {

      marker.setOnTapListener((marker){
        _showMarkerDetail(context, marker);
      });

      final spot = odyssey.spots.firstWhere((spot) => spot.id == marker.info.id);
      if(spot.memo == null || spot.memo == '') {
        continue;
      }
      final onMarkerInfoWindow = NInfoWindow.onMarker(id: marker.info.id, text: spot.memo!);
      marker.openInfoWindow(onMarkerInfoWindow);
    }
  }

  void _showMarkerDetail(BuildContext context, NMarker marker) {
    final odysseyProvider = Provider.of<OdysseyProvider>(context, listen: false);
    final odyssey = odysseyProvider.getOdysseyById(widget.routeImage.id);
    final spot = odyssey?.getSpotById(marker.info.id);
    if (spot != null) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(spot.memo ?? ''),
            content: SizedBox(
              height: 300,
              width: double.maxFinite,
              child: spot.photos != null && spot.photos!.isNotEmpty
                ? Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        itemCount: spot.photos!.length,
                        itemBuilder: (context, index) {
                          final photo = spot.photos![index];
                          if (photo.presignedUrl != null) {
                            return Image.network(photo.presignedUrl!);
                          } else {
                            return Container(); // presignedUrl이 null인 경우 빈 컨테이너 반환
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(spot.photos!.length, (index) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 4.0),
                          width: 8.0,
                          height: 8.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentPage == index
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        );
                      }),
                    ),
                  ],
                )
                : Center(child: Text('No photos available')), // photos가 없을 경우 표시할 내용
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }
  }

  void _addPolylineToMap(NaverMapController controller) {
    final List<NLatLng> positions = _markers.map((marker) => marker.position).toList();
    final NPolylineOverlay polyline = NPolylineOverlay(
      id: 'route_polyline',
      coords: positions,
      color: Colors.blue,
      width: 5,
    );
    
    controller.addOverlay(polyline);
  }
}
