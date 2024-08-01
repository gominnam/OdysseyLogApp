import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:odyssey_flutter_app/config/constants.dart';
import 'dart:convert';

import 'package:odyssey_flutter_app/models/routeImage.dart';

class RoutePage extends StatefulWidget {
  final RouteImage routeImage;

  const RoutePage({super.key, required this.routeImage});

  @override
  _RoutePageState createState() => _RoutePageState();
}

class _RoutePageState extends State<RoutePage> {
  late Future<dynamic> _apiResponse;

  @override
  void initState() {
    super.initState();
    _apiResponse = fetchApiData(widget.routeImage.id);
  }

  Future<dynamic> fetchApiData(int routeId) async {
    print('fetchApiData: $routeId');
    final url = '$baseUrl/api/routes/$routeId'; // API URL
    final response = await http.get(Uri.parse(url)); // HTTP GET 요청
    if (response.statusCode == 200) {
      return jsonDecode(response.body); // 성공 시 JSON 파싱
    } else {
      throw Exception('Failed to load data'); // 실패 시 예외 발생
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route Page'),
      ),
      body: FutureBuilder<dynamic>(
        future: _apiResponse,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return Center(child: Text('Data: ${snapshot.data}'));
          }
        },
      ),
    );
  }
}