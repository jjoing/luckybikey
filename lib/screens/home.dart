import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_naver_map/flutter_naver_map.dart';

import 'package:luckybiky/contents/way_sample_data.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  List<NLatLng> sampleData3Coords = Sample_Data_3.map((point) {
    return NLatLng(point['lat'], point['lon']);
  }).toList();


  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> _mapControllerCompleter = Completer();

    return NaverMap(
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
        onMapReady: (controller) async {
          _mapControllerCompleter.complete(controller);

          final path = NPathOverlay(
            id: 'samplePath3',
            coords: sampleData3Coords,  // NLatLng로 변환된 좌표 리스트
            color: Colors.blue,
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
    );
  }
}
