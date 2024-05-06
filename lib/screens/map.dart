import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odyssey_flutter_app/providers/spot_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}


class _MapScreenState extends State<MapScreen> {
  final Completer<NaverMapController> _mapControllerCompleter = Completer();
  //late NaverMapViewModel viewModel;

  @override
  void initState() {
    super.initState();
  }

  /**
   * TODO
   * - mapControllerComplete 시, 카메라를 gps 위치로 이동
   * - 경로 추가할 때마다
   *   - (초보) 선을 긋기
   *   - (중급) 연결을 업데이트 하기
   * - 마커 클릭 시 contextMenu 띄워서 관리할 수 있도록 함
   *   - 삭제 / 연결업데이트 등.
   */
  /**
   * 하려는 것 :
   * - 마커를 추가해야 할 때에는, 로직상에서는, provider.addMarker만 한다. UI를 업데이트 하지 않는다.
   * - UI는, controller와 provider가 알아서 잘 연결된 상태를 유지(또는 유연하게 해제하도록 한다.)
   */
  Future<void> moveMapToCurrentSpot(NaverMapController controller) async {
    final NLatLng spot = await getCurrentSpot();
    controller.updateCamera(NCameraUpdate.scrollAndZoomTo(target: spot, zoom: 18));
  }

  // FIXME
  void updateMap(NaverMapController controller) {
    final provider = Provider.of<SpotProvider>(context, listen: false);
    provider.spots.forEach((spot) {
      final NMarker marker = NMarker(id: spot.id, position: spot.position);
      // final infoWindow = NInfoWindow.onMarker(id: marker.info.id, text: spot.memo ?? "메모가 없습니다.");
      // marker.setOnTapListener((marker1) => marker1.openInfoWindow(infoWindow));
    
      marker.setOnTapListener((marker1) {
        showModalBottomSheet(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    children: <Widget>[
                      TextFormField(
                        initialValue: spot.memo,
                        decoration: const InputDecoration(
                          hintText: '메모를 입력하세요'
                        ),
                        onChanged: (value) {
                          provider.updateMemo(spot.id, value);
                        },
                      ),
                      Expanded(
                        child: Stack(
                          children: <Widget>[
                            ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(top: 50),  // 버튼 높이만큼 패딩을 주어 버튼과 겹치지 않도록 합니다.
                              children: spot.photos!.map((photo) => Image.file(
                                File(photo),
                                width: MediaQuery.of(context).size.width / 3,
                                fit: BoxFit.fitWidth,
                              )).toList(),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final imagePath = await pickImage();
                                  if (imagePath != null) {
                                    provider.addPhoto(spot.id, imagePath);
                                    setState(() {});  // 상태가 변경되었음을 알립니다.
                                  }
                                },
                                child: const Text('사진 추가'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      });
      controller.addOverlay(marker);
    });

    if (provider.spots.length >= 2) {
      final path = NPathOverlay(
        id: "path",
        coords: provider.spots.map((spot) => spot.position).toList()
      );
      controller.addOverlay(path);
    }
  }
  Future<NLatLng> getCurrentSpot() async {
    final Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return NLatLng(position.latitude, position.longitude);
  }

  Future<void> addCurrentLocation() async {
    final String spotId = Uuid().v1();
    final spotProvider = Provider.of<SpotProvider>(context, listen: false);
    spotProvider.addSpot(Spot(id: spotId, position: await getCurrentSpot(), memo: null));
  }

  Future<String?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('나의 여정'),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 8,
            child: NaverMap(
              onMapReady: (controller) async {
                _mapControllerCompleter.complete(controller);
                final spotProvider = Provider.of<SpotProvider>(context, listen: false);
                spotProvider.addListener(() {
                  updateMap(controller);
                });
                moveMapToCurrentSpot(controller);
                updateMap(controller);
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
                  onPressed: addCurrentLocation,
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
                                Provider.of<SpotProvider>(context, listen: false).clearSpots();
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}