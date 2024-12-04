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
    required this.start,
    required this.end,
  }) : super(key: key);

  final List<Map<String, dynamic>> route;
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
  double distance =
      ((lon2 - lon1) * (lat1 - pointLat) - (lon1 - pointLon) * (lat2 - lat1))
              .abs() /
          sqrt(pow(lon2 - lon1, 2) + pow(lat2 - lat1, 2));

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

  // 투영된 점 계산
  double projectionLatitude = point['NLatLng'].latitude + projectionFactor * dx;
  double projectionLongitude =
      point['NLatLng'].longitude + projectionFactor * dy;

  return {
    'latitude': projectionLatitude,
    'longitude': projectionLongitude,
  };
}

int _getProjectionNodes(List<Map<String, dynamic>> route,
    double currentLatitude, double currentLongitude, int lastIndex) {
  List<int> closeNodeIndexList = []; //index 쌍 출발점 Index 저장
  int projectionNodeIndex = -1;

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
    if (distance < 50 ||
        (distance < nextDistance && projectionNodeIndex == -1)) {
      closeNodeIndexList.add(i);
    }

    // 3개 이상의 노드가 추가되었고, 현재 노드와 다음 노드의 거리가 다르면 종료 ???
    if (closeNodeIndexList.length > 3 && distance > nextDistance) {
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

Map<String, dynamic> _updateNavState(Map<String, dynamic> navState) {
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

  return navState;
}

Timer? timer;
final FlutterTts tts = FlutterTts();

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
      "ttsFlag": [false, false, false],
      "testPosition": NLatLng(37.5666102, 126.9783881),
    };
    tts.setLanguage("ko-KR"); //언어설정
    tts.setSpeechRate(0.5); //말하는 속도(0.1~2.0)
    tts.setVolume(0.6); //볼륨(0.0~1.0)
    tts.setPitch(1); //음높이(0.5~2.0)
    timer = Timer.periodic(const Duration(seconds: 3), (t) {
      print('timer');
      setState(() {
        navState = _updateNavState(navState);
        print(navState['CurrentPosition']);
        print(navState['CurrentIndex']);
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
                zoom: 16,
                bearing: 0,
                tilt: 0,
              ),
              locationButtonEnable: true,
              contentPadding: const EdgeInsets.all(10),
            ),
            forceGesture: true,
            onMapTapped: (point, latLng) {
              print('onMapTapped: latLng: $latLng');

              setState(() {
                _mapKey = UniqueKey();
                navState['CurrentPosition'] = {
                  'latitude': latLng.latitude,
                  'longitude': latLng.longitude,
                };
                final projectedPosition = _getProjectedPosition(
                  navState['Route'],
                  navState['CurrentPosition']['latitude'],
                  navState['CurrentPosition']['longitude'],
                  navState['CurrentIndex'],
                );
                navState['testPosition'] = NLatLng(
                  projectedPosition['latitude'],
                  projectedPosition['longitude'],
                );
              });
            },
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
              final marker2 = NMarker(
                id: 'test',
                position: navState['testPosition'], // NLatLng로 변환된 도착지 좌표
              );
              controller.addOverlay(marker2);
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
