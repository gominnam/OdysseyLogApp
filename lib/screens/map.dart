import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:odyssey_flutter_app/config/constants.dart';
import 'package:odyssey_flutter_app/main.dart';
import 'package:odyssey_flutter_app/models/route.dart' as app_route;
import 'package:odyssey_flutter_app/models/spot.dart';
import 'package:odyssey_flutter_app/models/photo.dart';
import 'package:odyssey_flutter_app/models/odyssey.dart';
import 'package:odyssey_flutter_app/providers/route_provider.dart';
import 'package:odyssey_flutter_app/providers/spot_provider.dart';
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

  bool _isPosting = false;

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
    final routeProvider = Provider.of<RouteProvider>(context, listen: false);
    final spotProvider = Provider.of<SpotProvider>(context, listen: false);
    Map<String, dynamic> responseJson = jsonDecode(responseBody);
    Map<String, dynamic> responseRoute = responseJson['route'];
    List<dynamic> responseSpots = responseJson['spots'];

    // route photo upload
    if (responseRoute['photoUrl'] != null) {
      String presignedUrl = responseRoute['photoUrl'];
      await uploadImageToS3(presignedUrl, File(routeProvider.routePhotoUrl!)); 
    }
      
    // spot photos upload
    for (var s in responseSpots) {
      Spot? spot = spotProvider.getSpot(s['id']);

      if (spot.photos != null) {
        var responsePhotos = s['photos'];
        for(var indexAndPhoto in spot.photos!.asMap().entries) {
          var index = indexAndPhoto.key;
          var photo = indexAndPhoto.value;
          var responsePhoto = responsePhotos[index];
          if (responsePhoto['presignedUrl'] != null) {
            String presignedUrl = responsePhoto['presignedUrl'];
            await uploadImageToS3(presignedUrl, File(photo.path!));
          } else {
            print('presignedUrl is null for photo: ${photo.path}');
          }
        }
      }
    }
  }

  Map<String, dynamic> validatePosting(SpotProvider spotProvider, RouteProvider routeProvider) {
    if(spotProvider.spots.length <= 2) {
      return {'isValid': false, 'message': '최소 2개의 경로를 추가해야 합니다.'};
    }
    if(routeProvider.routePhotoUrl == null) {
      return {'isValid': false, 'message': '메인사진을 등록하세요.'};
    }
    if(routeProvider.routeTitle == null || routeProvider.routeTitle == '') {
      return {'isValid': false, 'message': '제목이 필요합니다.'};
    }
    return {'isValid': true, 'message': ''};
  }

  void savePosting(BuildContext context, SpotProvider spotProvider, RouteProvider routeProvider) async {
    if(_isPosting) {
      return;
    }

    _isPosting = true;
    
    try {
      // await Future.delayed(const Duration(seconds: 1));

      List<Spot> spots = spotProvider.getAllSpots(); 
      final route = app_route.Route(title: routeProvider.routeTitle!,
                          startLatitude: spots.first.position.latitude,
                          startLongitude: spots.first.position.longitude,
                          endLatitude: spots.last.position.latitude,
                          endLongitude: spots.last.position.longitude,
                          );

      // 2. Mark된 Spot point 데이터를 가공합니다. 여기서는 처음과 끝을 제외한 메모 또는 사진이 있는 Spot만 선택
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
        Uri.parse('$baseUrl/api/odyssey/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(odyssey.toJson()),
      );

      if (response.statusCode == 200) {
        await uploadImages(response.body);

        final result = await showDialog(
          context: context,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              title: Text('업로드 완료'),
              content: Text('이미지 업로드가 완료되었습니다.'),
              actions: <Widget>[
                TextButton(
                  child: Text('확인'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop(true);
                  },
                ),
              ],
            );
          },
        );

        print('show dialog result: $result');
        print('mounted: $mounted');
        if(result == true){
          spotProvider.reset();
          routeProvider.reset();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MyApp()),
          );
        }

      } else {
        _isPosting = false;

        Navigator.of(context).pop(); 

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('등록에 실패했습니다.'),
          ),
        );
      }
    } catch (e) {

      Navigator.of(context).pop(); 

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('등록에 실패했습니다.'),
        ),
      );
    } finally {
      _isPosting = false;
    }
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
                              padding: const EdgeInsets.only(top: 50),
                              children: spot.photos!.map((photo) => Image.file(
                                File(photo.path!),
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
                                    setState(() {});
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
    final spotProvider = Provider.of<SpotProvider>(context, listen: false);
    spotProvider.addSpot(Spot(position: await getCurrentSpot(), memo: null, photos: []));
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
                  onPressed: () async {
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Title and Photo'),
                          content: Consumer<RouteProvider>(
                            builder: (context, routeProvider, child) {
                              return Column(
                                children: <Widget>[
                                  TextFormField(
                                    initialValue: routeProvider.routeTitle,
                                    decoration: const InputDecoration(
                                      hintText: '제목을 입력하세요',
                                    ),
                                    onChanged: (value) {
                                      routeProvider.updateRouteTitle(value);
                                    },
                                  ),
                                  Expanded(
                                    child: Stack(
                                      children: <Widget>[
                                        if(routeProvider.routePhotoUrl != null)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 50),
                                            child: Image.file(
                                              File(routeProvider.routePhotoUrl!),
                                              width: MediaQuery.of(context).size.width,
                                              fit: BoxFit.fitWidth,
                                              key: UniqueKey(),  // 새로운 키를 생성합니다.
                                            ),
                                          ),
                                        Positioned(
                                          top: 0,
                                          left: 0,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              final imagePath = await pickImage();
                                              if (imagePath != null) {
                                                routeProvider.updateRoutePhotoUrl(imagePath);
                                              }
                                            },
                                            child: const Text('사진 추가'),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          actions: <Widget>[
                            ElevatedButton(
                              child: const Text('등록'),
                              onPressed: () {
                                final spotProvider = Provider.of<SpotProvider>(context, listen: false);
                                final routeProvider = Provider.of<RouteProvider>(context, listen: false);
                                Map<String, dynamic> validation = validatePosting(spotProvider, routeProvider);
                                if (!validation['isValid']) {
                                  OverlayEntry overlayEntry = OverlayEntry(
                                    builder: (context) => Align(
                                      alignment: Alignment.center,
                                      child: Material(
                                        color: Colors.blue,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            validation['message'],
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );

                                  Overlay.of(context).insert(overlayEntry);

                                  // 일정 시간 후에 메시지를 자동으로 제거
                                  Future.delayed(const Duration(seconds: 3), () {
                                    overlayEntry.remove();
                                  });
                                } else {
                                  savePosting(context, spotProvider, routeProvider);
                                  // Navigator.of(context).pop();  // 대화 상자를 닫습니다.
                                } 
                              },
                            ),
                          ],
                        );
                      },
                    ); 
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