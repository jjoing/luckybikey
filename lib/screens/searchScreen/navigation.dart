import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'navigation_utils.dart';

class Navigation extends StatefulWidget {
  const Navigation({
    Key? key,
    required this.route,
    required this.fullDistance,
    required this.start,
    required this.end,
    required this.tts,
  }) : super(key: key);

  final List<Map<String, dynamic>> route;
  final double fullDistance;
  final Map<String, dynamic> start;
  final Map<String, dynamic> end;
  final FlutterTts tts;

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  final Key _mapKey = UniqueKey();
  Map<String, dynamic> navState = {};
  NaverMapController? ct;
  Timer? timer;

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    navState = {
      'Route': widget.route,
      "Start": widget.start,
      "End": widget.end,
      "CurrentPosition": {
        "latitude": widget.start["NLatLng"].latitude,
        "longitude": widget.start["NLatLng"].longitude
      },
      "CurrentIndex": 0,
      "ProjectedPosition": {},
      "Angle": 0,
      "ttsFlag": [false, false, false],
      "finishFlag": false,
    };

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      print('timer');

      setState(() {
        navState = updateNavState(navState, ct, widget.tts);
        NMarker marker1 = NMarker(
          id: 'test1',
          position: NLatLng(
            navState['ProjectedPosition']['latitude'],
            navState['ProjectedPosition']['longitude'],
          ),
        );
        NMarker marker2 = NMarker(
          id: 'test2',
          position: NLatLng(
            navState['CurrentPosition']['latitude'],
            navState['CurrentPosition']['longitude'],
          ),
        );
        NMarker marker3 = NMarker(
          id: 'test3',
          position: NLatLng(
            navState['Route'][navState['CurrentIndex']]['NLatLng'].latitude,
            navState['Route'][navState['CurrentIndex']]['NLatLng'].longitude,
          ),
        );
        ct?.addOverlayAll({marker1, marker2, marker3});
        ct?.updateCamera(NCameraUpdate.withParams(
          target: NLatLng(
            navState['ProjectedPosition']['latitude'],
            navState['ProjectedPosition']['longitude'],
          ),
          zoom: 17,
          bearing: navState['Angle'],
          tilt: 45,
        ));
      });
      // print("navState['Angle']: ${navState['Angle']}");
      // print("navState['CurrentPosition']: ${navState['CurrentPosition']}");
      // print("navState['CurrentIndex']: ${navState['CurrentIndex']}");

      if (navState['finishFlag']) {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return Navigationend(
                  fullDistance: widget.fullDistance, tick: t.tick.toDouble());
            });
        timer?.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Completer<NaverMapController> mapControllerCompleter = Completer();
    return Dialog(
      insetPadding: const EdgeInsets.all(0),
      child: Stack(
        children: <Widget>[
          NaverMap(
            key: _mapKey,
            options: NaverMapViewOptions(
              mapType: NMapType.navi,
              initialCameraPosition: NCameraPosition(
                target: widget.start['NLatLng'], // NLatLng로 변환된 출발지 좌표
                zoom: 17,
                bearing: calculateBearing(
                  widget.start['NLatLng'].latitude,
                  widget.start['NLatLng'].longitude,
                  widget.route[1]['NLatLng'].latitude,
                  widget.route[1]['NLatLng'].longitude,
                ),
                tilt: 45,
              ),
              locationButtonEnable: true,
              contentPadding: const EdgeInsets.all(10),
            ),
            forceGesture: true,
            onMapTapped: (point, latLng) {
              setState(() {
                navState['CurrentPosition'] = {
                  'latitude': latLng.latitude,
                  'longitude': latLng.longitude,
                };
              });
            },
            onMapReady: (controller) {
              mapControllerCompleter.complete(controller);
              setState(() {
                ct = controller;
              });
              // ct?.setLocationTrackingMode(NLocationTrackingMode.follow);
              final path1 = NPathOverlay(
                id: 'route',
                coords: List<NLatLng>.from(widget.route
                    .map((e) => e["NLatLng"])), // NLatLng로 변환된 좌표 리스트
                color: const Color.fromARGB(255, 119, 201, 27),
                width: 5,
              );
              controller.addOverlay(path1);
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
        ],
      ),
    );
  }
}
