// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_naver_map/flutter_naver_map.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:odyssey_flutter_app/providers/marker_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:uuid/uuid.dart';

// class MapScreen extends StatefulWidget {
//   const MapScreen({super.key});

//   @override
//   _MapScreenState createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   final Completer<NaverMapController> _mapControllerCompleter = Completer();

//   @override
//   void initState() {
//     super.initState();  
//   }

//   /**
//    * TODO
//    * - mapControllerComplete 시, 카메라를 gps 위치로 이동
//    * - 경로 추가할 때마다
//    *   - (초보) 선을 긋기
//    *   - (중급) 연결을 업데이트 하기
//    * - 마커 클릭 시 contextMenu 띄워서 관리할 수 있도록 함
//    *   - 삭제 / 연결업데이트 등.
//    */
//   /**
//    * 하려는 것 :
//    * - 마커를 추가해야 할 때에는, 로직상에서는, provider.addMarker만 한다. UI를 업데이트 하지 않는다.
//    * - UI는, controller와 provider가 알아서 잘 연결된 상태를 유지(또는 유연하게 해제하도록 한다.)
//    */

//   Future<void> _addCurrentLocation() async {
//     final Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     );
//     final NLatLng spot = NLatLng(position.latitude, position.longitude);
//     final String markerId = Uuid().v1();
//     final NMarker marker = NMarker(id: markerId, position: spot);

//     Provider.of<MarkerProvider>(context, listen: false).addLocation(spot);
//     Provider.of<MarkerProvider>(context, listen: false).addMarker(marker);

//     _mapControllerCompleter.future.then((controller) {
//       controller.addOverlay(marker);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final markerProvider = Provider.of<MarkerProvider>(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('나의 여정'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Expanded(
//             flex: 8,
//             child: NaverMap(
//               onMapReady: (controller) {
//                 _mapControllerCompleter.complete(controller);
//                 markerProvider.markers.forEach((marker) { // 저장된 모든 마커를 맵에 추가
//                   controller.addOverlay(marker);
//               });
//               },
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Row(
//               children: <Widget>[
//                 ElevatedButton(
//                   child: const Text('back'),
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                 ),
//                 ElevatedButton(
//                   onPressed: _addCurrentLocation,
//                   child: const Text('경로 추가'),
//                 ),
//                 ElevatedButton(
//                   child: const Text('초기화'),
//                   onPressed: () {
//                     showDialog(
//                       context: context,
//                       builder: (BuildContext context) {
//                         return AlertDialog(
//                           title: Text('마커 삭제'),
//                           content: Text('모든 마커를 삭제하시겠습니까?'),
//                           actions: <Widget>[
//                             TextButton(
//                               child: Text('아니오'),
//                               onPressed: () {
//                                 Navigator.of(context).pop();
//                               },
//                             ),
//                             TextButton(
//                               child: Text('예'),
//                               onPressed: () async {
//                                 Provider.of<MarkerProvider>(context, listen: false).clearMarkers();
//                                 final controller = await _mapControllerCompleter.future;
//                                 controller.clearOverlays();
//                                 Navigator.of(context).pop();
//                               },
//                             ),
//                           ],
//                         );
//                       },
//                     );
//                   },
//                 )
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }