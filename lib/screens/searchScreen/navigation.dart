import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';

enum TtsState { playing, stopped, paused, continued }

class Navigation extends StatefulWidget {
  const Navigation({
    Key? key,
    required this.route,
    required this.fullDistance,
    required this.start,
    required this.end,
  }) : super(key: key);

  final List<Map<String, dynamic>> route;
  final double fullDistance;
  final Map<String, dynamic> start;
  final Map<String, dynamic> end;

  @override
  State<Navigation> createState() => _NavigationState();
}

Future<Position> _determinePosition() async {
  return await Geolocator.getCurrentPosition();
}

// 두 좌표 사이의 거리 계산 함수 (단위: 미터)
double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // 지구 반경 (미터)
  double phi1 = lat1 * (3.141592653589793 / 180);
  double phi2 = lat2 * (3.141592653589793 / 180);
  double deltaPhi = (lat2 - lat1) * (3.141592653589793 / 180);
  double deltaLambda = (lon2 - lon1) * (3.141592653589793 / 180);

  double a = (sin(deltaPhi / 2) * sin(deltaPhi / 2)) +
      cos(phi1) * cos(phi2) * (sin(deltaLambda / 2) * sin(deltaLambda / 2));
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c; // 거리 (미터 단위)
}

double _calculateTriangleDistance(double pointLat, double pointLon, double lat1,
    double lon1, double lat2, double lon2) {
  // // 두 점을 연결하는 직선의 기울기와 절편 계산 (y = mx + b 형태)

  // // 경위도 차이를 단순화해서 기하학적으로 다룬다
  // double deltaLat1 = lat1 - pointLat;
  // double deltaLon1 = lon1 - pointLon;
  // double deltaLat2 = lat2 - pointLat;
  // double deltaLon2 = lon2 - pointLon;

  // // 직선의 방향 벡터를 사용해 점과 직선 사이의 최소 거리를 계산
  // double A = lat2 - lat1; // 직선의 A 값 (y = Ax + B 형태의 기울기)
  // double B = lon1 - lon2; // 직선의 B 값

  // // 직선과 점 사이의 거리 계산 (y = mx + b 형식의 수직 거리 공식)
  // double distance =
  //     (A * pointLon - B * pointLat + lon2 * lat1 - lat2 * lon1).abs() /
  //         (sqrt(A * A + B * B)); // 수직 거리 계산
  double distance = 99999999999;
  double projectionFactor =
      ((pointLat - lat1) * (lat2 - lat1) + (pointLon - lon1) * (lon2 - lon1)) /
          ((lat2 - lat1) * (lat2 - lat1) + (lon2 - lon1) * (lon2 - lon1));
  if (projectionFactor >= -0.5 && projectionFactor <= 1.5) {
    distance =
        ((lon2 - lon1) * (lat1 - pointLat) - (lon1 - pointLon) * (lat2 - lat1))
                .abs() /
            sqrt(pow(lon2 - lon1, 2) + pow(lat2 - lat1, 2));
  } else if (projectionFactor < -0.5) {
    distance = sqrt((pointLat - lat1) * (pointLat - lat1) +
        (pointLon - lon1) * (pointLon - lon1));
  } else if (projectionFactor > 1.5) {
    distance = sqrt((pointLat - lat2) * (pointLat - lat2) +
        (pointLon - lon2) * (pointLon - lon2));
  }

  return distance;
}

Map<String, dynamic> _getProjectedPosition(List<Map<String, dynamic>> route,
    double currentLatitude, double currentLongitude, int projectionNodeIndex) {
  var point = route[projectionNodeIndex];
  var nextPoint = route[projectionNodeIndex + 1];

  // 직선의 두 점 (point)과 (nextPoint) 사이에서 currentPosition을 투영
  double dx = nextPoint['NLatLng'].latitude - point['NLatLng'].latitude;
  double dy = nextPoint['NLatLng'].longitude - point['NLatLng'].longitude;
  double dotProduct = (currentLatitude - point['NLatLng'].latitude) * dx +
      (currentLongitude - point['NLatLng'].longitude) * dy;
  double lineLengthSquare = dx * dx + dy * dy;
  double projectionFactor = dotProduct / lineLengthSquare;

  double projectionLatitude = 0;
  double projectionLongitude = 0;

  // 투영된 점 계산
  if (projectionFactor < 0) {
    projectionLatitude = point['NLatLng'].latitude;
    projectionLongitude = point['NLatLng'].longitude;
  } else if (projectionFactor > 1) {
    projectionLatitude = nextPoint['NLatLng'].latitude;
    projectionLongitude = nextPoint['NLatLng'].longitude;
  } else {
    projectionLatitude = point['NLatLng'].latitude + projectionFactor * dx;
    projectionLongitude = point['NLatLng'].longitude + projectionFactor * dy;
  }

  return {
    'latitude': projectionLatitude,
    'longitude': projectionLongitude,
  };
}

int _getProjectionNodes(List<Map<String, dynamic>> route,
    double currentLatitude, double currentLongitude, int lastIndex) {
  List<int> closeNodeIndexList = []; //index 쌍 출발점 Index 저장
  int projectionNodeIndex = -1;

  if (lastIndex > 2) {
    lastIndex -= 2;
  }

  for (int i = lastIndex; i < route.length - 1; i++) {
    // 현재 노드 (point)와 그 다음 노드 (nextPoint)
    var point = route[i];
    var nextPoint = route[i + 1];

    NLatLng latLng = point['NLatLng'];
    double pointLatitude = latLng.latitude;
    double pointLongitude = latLng.longitude;

    NLatLng nextLatLng = nextPoint['NLatLng'];
    double nextPointLatitude = nextLatLng.latitude;
    double nextPointLongitude = nextLatLng.longitude;

    // 두 점 사이의 거리 계산
    double distance = _calculateDistance(
        currentLatitude, currentLongitude, pointLatitude, pointLongitude);
    double nextDistance = _calculateDistance(currentLatitude, currentLongitude,
        nextPointLatitude, nextPointLongitude);

    // 가까운 노드들만 추가 (50미터 이내로)
    if (distance < 10 ||
        (distance < nextDistance && projectionNodeIndex == -1)) {
      closeNodeIndexList.add(i);
    }

    // 3개 이상의 노드가 추가되었고, 현재 노드와 다음 노드의 거리가 다르면 종료 ???
    if (closeNodeIndexList.length > 6 && distance > nextDistance) {
      break;
    }
  }

  double minDistance = 1000000000000;
  // 점과 직선 사이의 거리를 계산하여 가장 작은 pair를 선택
  for (int i in closeNodeIndexList) {
    // 점과 직선 사이의 최소 거리 계산 (여기서는 예시로 단순히 거리 계산)
    double projectionDistance = _calculateTriangleDistance(
        currentLatitude,
        currentLongitude,
        route[i]['NLatLng'].latitude,
        route[i]['NLatLng'].longitude,
        route[i + 1]['NLatLng'].latitude,
        route[i + 1]['NLatLng'].longitude);
    if (minDistance > projectionDistance) {
      minDistance = projectionDistance;
      projectionNodeIndex = i;
    }
    // 직선과 점 사이의 거리가 최소일 경우에 projectionNodeList에 추가
  }
  // ProjectionNodeList 반환
  return projectionNodeIndex;
}

double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
  // 라디안 단위로 변환
  final lat1Rad = lat1 * pi / 180;
  final lon1Rad = lon1 * pi / 180;
  final lat2Rad = lat2 * pi / 180;
  final lon2Rad = lon2 * pi / 180;

  // Δλ 계산
  final dLon = lon2Rad - lon1Rad;

  // 방향 벡터의 θ 계산
  final y = sin(dLon) * cos(lat2Rad);
  final x =
      cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLon);

  // θ를 도 단위로 변환 (북쪽 기준 0도)
  final bearingRad = atan2(y, x);
  final bearingDeg = (450 - bearingRad * 180 / pi) % 360; // 0~360도로 변환

  return bearingDeg;
}

Future<Map<String, dynamic>> _updateNavState(
    Map<String, dynamic> navState) async {
  // _determinePosition().then((value) {
  //   navState['CurrentPosition'] = {
  //     'latitude': value.latitude,
  //     'longitude': value.longitude,
  //   };
  // });
  //사정거리안에 들어오거나 가장 가까운 노드 찾기
  //그 노드가 연결한 Route들 중 점 직선 사이 거리가 가장 가까운 node 쌍 찾기_ (node1, node2) node1 to node2
  final newIndex = _getProjectionNodes(
    navState['Route'],
    navState['CurrentPosition']['latitude'],
    navState['CurrentPosition']['longitude'],
    navState['CurrentIndex'],
  );
  if (newIndex != navState['CurrentIndex']) {
    navState['CurrentIndex'] = newIndex;
    navState['ttsFlag'] = [false, false, false];
  }
  //투영한 위치 반환
  //이걸로 update

  navState['ProjectedPosition'] = _getProjectedPosition(
    navState['Route'],
    navState['CurrentPosition']['latitude'],
    navState['CurrentPosition']['longitude'],
    navState['CurrentIndex'],
  );

  //회전 정보 (State, 상수)
  //직진 => distance 몇까지 직진인지 확인()
  //=> 20m 이하 : []회전, 0m(후 []회전)
  //=> 20m 이상 50m 이하 직진 : 직진 후 []회전, 0m(후 []회전)
  //=> 50m 이상 직진 : 직진, 0m(동안 직진)
  //[]회전 => state는 항상 []회전
  //=> 회전 후 직진 : []회전, 0
  //=> []회전 후 []회전 : []회전, 1
  //=> []회전 후 {}회전 : []회전, 2

  final current_node = navState['Route'][navState['CurrentIndex']];
  final next_node = navState['Route'][navState['CurrentIndex'] + 1];

  final distance = _calculateDistance(
    navState['ProjectedPosition']['latitude'],
    navState['ProjectedPosition']['longitude'],
    next_node['NLatLng'].latitude,
    next_node['NLatLng'].longitude,
  );

  navState['Angle'] = calculateBearing(
    current_node['NLatLng'].latitude,
    current_node['NLatLng'].longitude,
    next_node['NLatLng'].latitude,
    next_node['NLatLng'].longitude,
  );

  if (navState['CurrentIndex'] == navState['Route'].length - 2) {
    if (distance < 20) {
      tts.speak('목적지에 도착했습니다');
      print('목적지에 도착했습니다');
      navState['finishFlag'] = true;
      return navState;
    } else if (navState['ttsFlag'][0] == false) {
      tts.speak('목적지까지 ${distance.round()}미터 남았습니다');
      print('목적지까지 ${distance.round()}미터 남았습니다');
      navState['ttsFlag'][0] = true;
    }
  } else {
    var ttsMessage = '';
    if (distance < 20 && navState['ttsFlag'][0] == false) {
      ttsMessage = '${distance.round()}미터 앞 ';
      if (current_node['angle'] > 45) {
        switch (current_node['isleft']) {
          case true:
            ttsMessage += '좌회전입니다';
          case false:
            ttsMessage += '우회전입니다';
        }
      } else {
        ttsMessage += '직진입니다';
      }
      tts.speak(ttsMessage);
      print(ttsMessage);
      navState['ttsFlag'][0] = true;
    } else if (distance < 50 && navState['ttsFlag'][1] == false) {
      ttsMessage = '${distance.round()}미터 후 ';
      if (current_node['angle'] > 45) {
        switch (current_node['isleft']) {
          case true:
            ttsMessage += '좌회전하세요';
          case false:
            ttsMessage += '우회전하세요';
        }
      } else {
        ttsMessage += '직진하세요';
      }
      tts.speak(ttsMessage);
      print(ttsMessage);
      navState['ttsFlag'][1] = true;
    } else if (navState['ttsFlag'][2] == false) {
      ttsMessage = '${distance.round()}미터동안 직진입니다';
      tts.speak(ttsMessage);
      print(ttsMessage);
      navState['ttsFlag'][2] = true;
    }
  }

  return navState;
}

Timer? timer;
final FlutterTts tts = FlutterTts();
NaverMapController? _ct;
int _rating = 0;

class _NavigationState extends State<Navigation> {
  Key _mapKey = UniqueKey();
  Map<String, dynamic> navState = {};

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
      "testPosition": NLatLng(37.5666102, 126.9783881),
    };
    tts.setLanguage("ko-KR"); //언어설정
    tts.setSpeechRate(0.5); //말하는 속도(0.1~2.0)
    tts.setVolume(0.6); //볼륨(0.0~1.0)
    tts.setPitch(1); //음높이(0.5~2.0)
    timer = Timer.periodic(const Duration(seconds: 3), (t) {
      print('timer');
      setState(() {
        _updateNavState(navState).then((value) {
          navState = value;
          print("navState['Angle']: ${navState['Angle']}");
          print("navState['CurrentPosition']: ${navState['CurrentPosition']}");
          print("navState['CurrentIndex']: ${navState['CurrentIndex']}");
          NMarker marker1 = NMarker(
            id: 'test1',
            position: NLatLng(
              navState['Route'][navState['CurrentIndex']]['NLatLng'].latitude,
              navState['Route'][navState['CurrentIndex']]['NLatLng'].longitude,
            ),
          );
          NMarker marker2 = NMarker(
            id: 'test2',
            position: NLatLng(
              navState['Route'][navState['CurrentIndex'] + 1]['NLatLng']
                  .latitude,
              navState['Route'][navState['CurrentIndex'] + 1]['NLatLng']
                  .longitude,
            ),
          );
          _ct?.addOverlayAll({marker1, marker2});

          print("current node: ${navState['Route'][navState['CurrentIndex']]}");
          print(
              "next node: ${navState['Route'][navState['CurrentIndex'] + 1]}");

          _ct?.updateCamera(NCameraUpdate.withParams(
            target: NLatLng(
              navState['ProjectedPosition']['latitude'],
              navState['ProjectedPosition']['longitude'],
            ),
            zoom: 17,
            bearing: navState['Angle'],
            tilt: 45,
          ));
        });

        if (navState['finishFlag']) {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('안내 종료'),
                  content: SizedBox(
                    height: 400,
                    child: Column(
                      children: <Widget>[
                        const Text('목적지에 도착했습니다'),
                        Text('총 이동거리: ${widget.fullDistance.round()}m'),
                        Text('총 소요시간: ${(t.tick * 3 / 60).round()}분'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                  _rating > index
                                      ? Icons.star
                                      : Icons.star_border,
                                  color: Colors.amber,
                                  size: 40.0),
                              onPressed: () {
                                setState(() {
                                  _rating = index + 1;
                                  print(_rating);
                                });
                              },
                            );
                          }),
                        )
                      ],
                    ),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                      },
                      child: const Text('확인'),
                    ),
                  ],
                );
              });
          timer?.cancel();
        }
      });
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
            key: _mapKey, // 지도 리로드를 위한 Key
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
              print('onMapTapped: latLng: $latLng');

              // _ct?.updateCamera(NCameraUpdate.withParams(
              //   target: latLng,
              //   zoom: 17,
              // ));

              setState(() {
                navState['CurrentPosition'] = {
                  'latitude': latLng.latitude,
                  'longitude': latLng.longitude,
                };
              });
              final projectedPosition = _getProjectedPosition(
                navState['Route'],
                navState['CurrentPosition']['latitude'],
                navState['CurrentPosition']['longitude'],
                navState['CurrentIndex'],
              );
              final marker2 = NMarker(
                id: 'test',
                position: NLatLng(
                  projectedPosition['latitude'],
                  projectedPosition['longitude'],
                ), // NLatLng로 변환된 도착지 좌표
              );
              _ct?.addOverlay(marker2);
            },
            onMapReady: (controller) {
              mapControllerCompleter.complete(controller);
              setState(() {
                _ct = controller;
              });
              // mapControllerCompleter.complete(controller);
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
