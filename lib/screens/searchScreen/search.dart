import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:luckybiky/screens/searchScreen/modal.dart';
import 'package:luckybiky/contents/way_sample_data.dart';

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
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

  Key _mapKey = UniqueKey();
  bool _showMarker = false;
  bool _showPath = false;
  String _stationName = "정류장 이름"; // 예시 정보
  int _bikeCount = 5; // 예시 남은 자전거 수

  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> _mapControllerCompleter = Completer();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white),
              child: ListView(
                children: [
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(width: 5),
                      Column(
                        children: [
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white70,
                            ),
                            child: TextField(
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: '출발지 입력',
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white70,
                            ),
                            child: TextField(
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
                            setState(() {
                              _mapKey = UniqueKey();
                              _showPath = !_showPath;
                            });
                          },
                          icon: Icon(Icons.search),
                        ),
                      ),
                      SizedBox(width: 5),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: NaverMap(
                      key: _mapKey,
                      options: const NaverMapViewOptions(
                        mapType: NMapType.basic,
                        activeLayerGroups: [NLayerGroup.bicycle],
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
                        _mapControllerCompleter.complete(controller);

                        if (_showPath) {
                          final path = NPathOverlay(
                            id: 'samplePath2',
                            coords: sampleData2Coords,
                            color: Colors.lightGreen,
                            width: 5,
                          );
                          controller.addOverlay(path);
                        }

                        if (_showMarker) {
                          const target = NLatLng(37.525313, 126.9226753);
                          final marker = NMarker(
                            id: 'testMarker',
                            position: target,
                          );

                          // 정보 창 설정
                          final infoWindow = NInfoWindow.onMarker(
                            id: marker.info.id,
                            text: "정류장 이름: $_stationName\n 남은 자전거 수: $_bikeCount대",
                          );

                          controller.addOverlay(marker);

                          marker.setOnTapListener((NMarker marker) {
                            marker.openInfoWindow(infoWindow);
                          });// 마커 클릭 시 정보 창 열기
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
                    setState(() {
                      _mapKey = UniqueKey();
                      _showMarker = !_showMarker;
                    });
                  },
                  icon: Image.asset('assets/images/share_bike_logo.jpeg'),
                ),
              ),
            ),
            Positioned(
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