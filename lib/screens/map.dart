import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odyssey_flutter_app/models/route.dart' as app_route;
import 'package:odyssey_flutter_app/models/spot.dart';
import 'package:odyssey_flutter_app/models/photo.dart';
import 'package:odyssey_flutter_app/models/odyssey.dart';
import 'package:odyssey_flutter_app/providers/spot_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:screenshot/screenshot.dart';



class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<NaverMapController> _mapControllerCompleter = Completer();

  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> uploadImageToS3(String presignedUrl, File imageFile) async {
    final response = await http.put(
      Uri.parse(presignedUrl),
      headers: <String, String>{
        'Content-Type': 'application/octet-stream',
      },
      body: await imageFile.readAsBytes(),
    );

    if (response.statusCode != 200) {
      throw Exception('Image upload failed: ${response.statusCode}');
    }
  }

  Future<void> uploadImages(String responseBody) async {
    final provider = Provider.of<SpotProvider>(context, listen: false);
    Map<String, dynamic> responseJson = jsonDecode(responseBody);
    Map<String, dynamic> responseRoute = responseJson['route'];
    List<dynamic> responseSpots = responseJson['spots'];

    print('responseRoute: $responseRoute');
    if (responseRoute['photoUrl'] != null) {
      String presignedUrl = responseRoute['photoUrl'];
      await captureAndSaveScreenshot(presignedUrl);
    }
      
    // spot photos upload
    for (var s in responseSpots) {
      Spot? spot = provider.getSpot(s['id']);

      if (spot.photos != null) {
        var responsePhotos = s['photos'];
        for(var indexAndPhoto in spot.photos!.asMap().entries) {
          var index = indexAndPhoto.key;
          var photo = indexAndPhoto.value;
          var responsePhoto = responsePhotos[index];
          if (responsePhoto['presignedUrl'] != null) {
            // presigned URL을 가져옵니다.
            String presignedUrl = responsePhoto['presignedUrl'];

            // presigned URL에 이미지를 업로드합니다.
            await uploadImageToS3(presignedUrl, File(photo.path));
          } else {
            print('presignedUrl is null for photo: ${photo.path}');
          }
        }
      }
    }
  }

  void saveMark(List<Spot> spots) async {
    if(spots.length < 2) {
      throw Exception('최소 2개의 경로를 추가해야 합니다.');
    }

    // todo: 저장하기 버튼 크릭하면 toast title 적는 화면 띄우고 title 값 세팅하기
    final route = app_route.Route(title: "title",
                        startLatitude: spots.first.position.latitude,
                        startLongitude: spots.first.position.longitude,
                        endLatitude: spots.last.position.latitude,
                        endLongitude: spots.last.position.longitude
                        );

    // 2. Mark된 Spot point 데이터를 가공합니다. 여기서는 메모 또는 사진이 있는 Spot만 선택합니다.
    final spotsWithMemoAndPhoto = [
      spots.first,
      ...spots.sublist(1, spots.length - 1).where((spot) => spot.memo != null || spot.photos != null),
      spots.last,
    ].toList();

    final odyssey = Odyssey(
      route: route,
      spots: spotsWithMemoAndPhoto,
    );

    final response = await http.post(
      Uri.parse('https://called-contemporary-hughes-lands.trycloudflare.com/api/odyssey/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(odyssey.toJson()),
    );

    if (response.statusCode == 200) {
      print('response.body: ${response.body}');
      await uploadImages(response.body);
    } else {
      throw Exception('저장에 실패했습니다.');
    }
  }

  Future<void> captureAndSaveScreenshot(presignedUrl) async {
    await screenshotController.capture(delay: const Duration(milliseconds: 10))
        .then((Uint8List? image) async {
          if(image != null) {
            final directory = (await getTemporaryDirectory()).path;
            File imgFile = File('$directory/screenshot.png');
            await imgFile.writeAsBytes(image);
            await uploadImageToS3(presignedUrl, imgFile); 
          }
        }
    );
  }

  Future<void> moveMapToCurrentSpot(NaverMapController controller) async {
    final NLatLng spot = await getCurrentSpot();
    controller.updateCamera(NCameraUpdate.scrollAndZoomTo(target: spot, zoom: 18));
  }

  void updateMap(NaverMapController controller) {
    final provider = Provider.of<SpotProvider>(context, listen: false);
    for (var spot in provider.spots) {
      final NMarker marker = NMarker(id: spot.id, position: spot.position);
    
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
                                File(photo.path),
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
                                    provider.addPhoto(spot.id, Photo(path: imagePath));
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
    }

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
    // final String spotId = Uuid().v1();
    final spotProvider = Provider.of<SpotProvider>(context, listen: false);
    spotProvider.addSpot(Spot(position: await getCurrentSpot(), memo: null, photos: []));
    // spotProvider.addSpot(Spot(id: spotId, position: await getCurrentSpot(), memo: null));
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
            child: Screenshot(
              controller: screenshotController,
                child:NaverMap(
                  onMapReady: (controller) async {
                    _mapControllerCompleter.complete(controller);
                    final spotProvider = Provider.of<SpotProvider>(context, listen: false);
                    spotProvider.addListener(() {
                      updateMap(controller);
                    });
                    moveMapToCurrentSpot(controller);
                    updateMap(controller);
                  }
                )
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: <Widget>[
                ElevatedButton(
                  child: const Text('메인'),
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
                          title: const Text('마커 삭제'),
                          content: const Text('모든 마커를 삭제하시겠습니까?'),
                          actions: <Widget>[
                            TextButton(
                              child: const Text('아니오'),
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
                ),
                ElevatedButton(
                  child: const Text('저장하기'),
                  onPressed: () {
                    final spotProvider = Provider.of<SpotProvider>(context, listen: false);
                    saveMark(spotProvider.getAllSpots());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}