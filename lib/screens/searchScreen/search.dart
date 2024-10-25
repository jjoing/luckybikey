import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:csv/csv.dart';
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

    @override
  Widget build(BuildContext context) {
      final Completer<NaverMapController> _mapControllerCompleter = Completer();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
          ),
          child: ListView(
            children: [
              SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 10,),
                  Column(
                    children: [
                      Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width*0.65,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.white70
                        ),
                        child: TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '출발지 입력',
                            )
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 50,
                        width: MediaQuery.of(context).size.width*0.65,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: Colors.white70
                        ),
                        child: TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: '도착지 입력',
                            )
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    width: 10,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      onPressed: () => {},
                      icon: const Icon(Icons.swap_vert),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: IconButton(
                      onPressed: () async {

                      },
                      icon: Image.asset('assets/images/share_bike_logo.jpeg'),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                height: MediaQuery.of(context).size.height*0.6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10)
                ),
                child: NaverMap(
                    options: const NaverMapViewOptions(
                        mapType: NMapType.basic,
                        activeLayerGroups: [
                          NLayerGroup.bicycle,
                          // NLayerGroup.traffic,
                          // NLayerGroup.transit,
                        ],
                        initialCameraPosition: NCameraPosition(
                            target: NLatLng(37.525313, 126.9226753),
                            zoom: 12,
                            bearing: 0,
                            tilt: 0
                        ),
                        locationButtonEnable: true,
                        contentPadding: EdgeInsets.all(10)// default : [NLayerGroup.building]
                    ),
                    forceGesture: true,
                    onMapReady: (controller) {
                      _mapControllerCompleter.complete(controller);

                      final path = NPathOverlay(
                        id: 'samplePath2',
                        coords: sampleData2Coords,  // NLatLng로 변환된 좌표 리스트
                        color: Colors.lightGreen,
                        width: 5,
                      );

                      const LatLng1 = NLatLng(37.525313, 126.9226753);

                      final marker = NMarker(
                        id: 'testMarker',
                        position: LatLng1,  // 서울 좌표
                      );

                      controller.addOverlay(marker);
                      controller.addOverlay(path);

                    }
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Center(child: ModalContent())),
      ],
    );
  }
}
