import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:odyssey_flutter_app/providers/route_provider.dart';
import 'package:odyssey_flutter_app/providers/spot_provider.dart';
import 'package:odyssey_flutter_app/screens/map.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeNaverMap();
  await requestLocationPermission();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => SpotProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => RouteProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> requestLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      // 권한이 영구적으로 거부된 경우
    } else if (permission == LocationPermission.denied) {
      // 권한이 거부된 경우
    }
  }

  if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
    // 권한이 허용된 경우
  }
}

// 지도 초기화하기
Future<void> initializeNaverMap() async {
  await NaverMapSdk.instance.initialize(
    clientId: dotenv.env['NAVER_CLIENT_ID'],
    onAuthFailed: (e) => log("네이버맵 인증오류 : $e", name: "onAuthFailed")
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oddyssey Log',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Oddyssey Log'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Text('Menu'),
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
            ),
            ListTile(
              title: Text('여정'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MapScreen()),
                );
              },
            ),
            ListTile(
              title: Text('개인정보'),
              onTap: () {
                // 개인정보 버튼이 클릭되었을 때의 동작
              },
            ),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(10.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10.0,
          mainAxisSpacing: 10.0,
        ),
        itemCount: 15, // 표시할 이미지의 총 수
        itemBuilder: (context, index) {
          return Image.network('https://example.com/image${index}.jpg');
          // 실제 이미지 URL로 변경해야 합니다.
        },
      )
    );
  }
}

void showCustomDialog(BuildContext context, String message, Function action) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("알림"),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              action();
              Navigator.pop(context);
            },
            child: const Text("설정"),
          ),
        ],
      );
    },
  );
}

Future<List<String>> fetchImages() async {
  final response = await http.get(
    Uri.parse('https://tf-mauritius-techrepublic-wn.trycloudflare.com/api/odyssey/'));
  //https://nasdaq-dial-raised-deployment.trycloudflare.com/api/odyssey/
  if (response.statusCode == 200) {
    // 서버가 성공적으로 응답하면, JSON을 파싱합니다.
    var jsonResponse = jsonDecode(response.body);
    List<String> imageUrls = jsonResponse.map((item) => item['presignedUrl']).toList();
    return imageUrls;
  } else {
    // 서버가 실패로 응답하면, 예외를 던집니다.
    throw Exception('Failed to load images');
  }
}
