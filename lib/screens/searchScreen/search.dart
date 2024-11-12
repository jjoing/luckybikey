import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:luckybiky/screens/searchScreen/modal.dart';
import 'package:luckybiky/contents/way_sample_data.dart';

import 'package:cloud_functions/cloud_functions.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

Future<Map<String, dynamic>> _testting(req) async {
  final results =
      await FirebaseFunctions.instance.httpsCallable('testting').call(req);
  return results.data;
}

Future<Map<String, dynamic>> _request_route(req) async {
  final results =
      await FirebaseFunctions.instance.httpsCallable('request_route').call(req);

  List<NLatLng> route = List<NLatLng>.from(results.data['route'].map((point) {
    return NLatLng(point['lat'], point['lon']);
  }));

  return {"route": route, "full_distance": results.data['full_distance']};
}

class _SearchState extends State<Search> {
  void _permission() async {
    var requestStatus = await Permission.location.request();
    var status = await Permission.location.status;
    if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  void initState() {
    _permission();
    super.initState();
  }

  List<NLatLng> sampleData2Coords = Sample_Data_2.map((point) {
    return NLatLng(point['lat'], point['lon']);
  }).toList();

  List<NLatLng> route = [];

  Key _mapKey = UniqueKey(); // 지도 리로드를 위한 Key
  bool _showMarker = false; // 마커 표시 여부
  bool _showPath = false; // 경로 표시 여부

  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> mapControllerCompleter = Completer();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: ListView(
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      const SizedBox(
                        width: 5,
                      ),
                      Column(
                        children: [
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white70,
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '출발지 입력',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white70,
                            ),
                            child: const TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '도착지 입력',
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(
                        width: 20,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => {},
                          icon: const Icon(Icons.swap_vert),
                        ),
                      ),
                      SizedBox(
                        width: 20,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          onPressed: () {
                            // 버튼을 눌렀을 때 _showPath 상태를 토글하고 지도를 리로드
                            setState(() {
                              _mapKey = UniqueKey();
                              _showPath = !_showPath; // 상태를 토글하여 경로 표시 여부 변경
                            });
                            _testting({"text": "text"}).then((value) {
                              print(value);
                              print(value['data']);
                              print(value['data'].runtimeType);
                              print(value['message']);
                              print(value['message'].runtimeType);
                            }, onError: (error) {
                              print(error);
                            });
                            _request_route({
                              "StartPoint": {
                                "lat": 37.5322857,
                                "lon": 126.9131594
                              },
                              "EndPoint": {
                                "lat": 37.5214849,
                                "lon": 126.9298773
                              },
                              "UseSharing": false,
                              "UserTaste": false,
                            }).then((result) {
                              setState(() {
                                _mapKey = UniqueKey();
                                route = result['route'];
                              });
                              print(result['route']);
                              print(result['route'].runtimeType);
                              print(result['full_distance']);
                              print(result['full_distance'].runtimeType);
                            }, onError: (error, stackTrace) {
                              print(error);
                            });
                          },
                          icon: const Icon(Icons.search),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: NaverMap(
                      key: _mapKey, // 지도 리로드를 위한 Key
                      options: const NaverMapViewOptions(
                        mapType: NMapType.basic,
                        activeLayerGroups: [
                          NLayerGroup.bicycle,
                        ],
                        initialCameraPosition: NCameraPosition(
                          target: NLatLng(37.525313, 126.9226753),
                          zoom: 12,
                          bearing: 0,
                          tilt: 0,
                        ),
                        locationButtonEnable: true,
                        contentPadding: EdgeInsets.all(10),
                      ),
                      forceGesture: true,
                      onMapReady: (controller) {
                        mapControllerCompleter.complete(controller);

                        // _showPath 상태에 따라 경로 오버레이 추가
                        if (_showPath) {
                          final path = NPathOverlay(
                            id: 'samplePath2',
                            coords: sampleData2Coords, // NLatLng로 변환된 좌표 리스트
                            color: Colors.lightGreen,
                            width: 5,
                          );
                          controller.addOverlay(path);
                          final path2 = NPathOverlay(
                            id: 'samplePath3',
                            coords: route, // NLatLng로 변환된 좌표 리스트
                            color: Colors.lightGreen,
                            width: 5,
                          );
                          controller.addOverlay(path2);
                        }

                        // _showMarker 상태에 따라 마커 추가
                        if (_showMarker) {
                          const LatLng1 = NLatLng(37.525313, 126.9226753);
                          final marker = NMarker(
                            id: 'testMarker',
                            position: LatLng1, // 마커 위치
                          );
                          controller.addOverlay(marker);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 170,
              left: 20,
              child: SizedBox(
                width: 50,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    // 버튼을 눌렀을 때 _showMarker 상태를 토글하고 지도를 리로드
                    setState(() {
                      _mapKey = UniqueKey();
                      _showMarker = !_showMarker; // 상태를 토글하여 마커 표시 여부 변경
                    });
                  },
                  icon: Image.asset('assets/images/share_bike_logo.jpeg'),
                ),
              ),
            ),
            const Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(child: ModalContent()),
            ),
          ],
        ),
      ),
    );
  }
}
