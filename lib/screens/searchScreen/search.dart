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

  Key _mapKey = UniqueKey();  // 지도 리로드를 위한 Key
  bool _showMarker = false;  // 마커 표시 여부
  bool _showPath = false;    // 경로 표시 여부

  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> _mapControllerCompleter = Completer();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white,),
              child: ListView(
                children: [
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      SizedBox(width: 5,),
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
                            // 버튼을 눌렀을 때 _showPath 상태를 토글하고 지도를 리로드
                            setState(() {
                              _mapKey = UniqueKey();
                              _showPath = !_showPath; // 상태를 토글하여 경로 표시 여부 변경
                            });
                          },
                          icon: Icon(Icons.search),
                        ),
                      ),
                      SizedBox(width: 5,),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: NaverMap(
                      key: _mapKey,  // 지도 리로드를 위한 Key
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
                        _mapControllerCompleter.complete(controller);

                        // _showPath 상태에 따라 경로 오버레이 추가
                        if (_showPath) {
                          final path = NPathOverlay(
                            id: 'samplePath2',
                            coords: sampleData2Coords, // NLatLng로 변환된 좌표 리스트
                            color: Colors.lightGreen,
                            width: 5,
                          );
                          controller.addOverlay(path);
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
