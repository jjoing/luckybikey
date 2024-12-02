import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';

class Navigation extends StatefulWidget {
  const Navigation({
    Key? key,
    required this.route,
    required this.start,
    required this.end,
  }) : super(key: key);

  final List<Map<String, dynamic>> route;
  final Map<String, dynamic> start;
  final Map<String, dynamic> end;

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  Key _mapKey = UniqueKey();
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> mapControllerCompleter = Completer();
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      print('timer');
      setState(() {});
    });
    return Dialog(
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: <Widget>[
          NaverMap(
            key: _mapKey, // 지도 리로드를 위한 Key
            options: NaverMapViewOptions(
              mapType: NMapType.navi,
              initialCameraPosition: NCameraPosition(
                target: widget.start['NLatLng'], // NLatLng로 변환된 출발지 좌표
                zoom: 16,
                bearing: 0,
                tilt: 0,
              ),
              locationButtonEnable: true,
              contentPadding: const EdgeInsets.all(10),
            ),
            forceGesture: true,
            onMapReady: (controller) {
              mapControllerCompleter.complete(controller);
              final path1 = NPathOverlay(
                id: 'route',
                coords: List<NLatLng>.from(widget.route
                    .map((e) => e["NLatLng"])), // NLatLng로 변환된 좌표 리스트
                color: const Color.fromARGB(255, 119, 201, 27),
                width: 5,
              );
              controller.addOverlay(path1);
              final marker1 = NMarker(
                id: 'start',
                // icon:
                //     NOverlayImage.fromFile(File('assets/images/nav_icon.png')),
                position: widget.start['NLatLng'], // NLatLng로 변환된 출발지 좌표
              );
              controller.addOverlay(marker1);
            },
          ),
          Positioned(
            top: 10,
            right: 10,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('닫기'),
            ),
          ),
          Positioned(
            top: 60,
            right: 10,
            child: ElevatedButton(
              onPressed: () => setState(() {
                _mapKey = UniqueKey();
              }),
              child: const Text('지도 리로드'),
            ),
          ),
        ],
      ),
    );
  }
}
