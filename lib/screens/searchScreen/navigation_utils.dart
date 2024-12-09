import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../utils/mapAPI.dart';

Map<String, dynamic> updateNavState(
    Map<String, dynamic> navState, NaverMapController? ct, FlutterTts tts) {
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

  final currentNode = navState['Route'][navState['CurrentIndex']];
  final nextNode = navState['Route'][navState['CurrentIndex'] + 1];

  final distance = calculateDistance(
    navState['ProjectedPosition']['latitude'],
    navState['ProjectedPosition']['longitude'],
    nextNode['NLatLng'].latitude,
    nextNode['NLatLng'].longitude,
  );

  final distanceToEnd = calculateDistance(
    navState['ProjectedPosition']['latitude'],
    navState['ProjectedPosition']['longitude'],
    navState['Route'][navState['Route'].length - 1]['NLatLng'].latitude,
    navState['Route'][navState['Route'].length - 1]['NLatLng'].longitude,
  );

  navState['Angle'] = calculateBearing(
    currentNode['NLatLng'].latitude,
    currentNode['NLatLng'].longitude,
    nextNode['NLatLng'].latitude,
    nextNode['NLatLng'].longitude,
  );

  print('current index: ${navState["CurrentIndex"]} distance: $distance');

  if (distanceToEnd < 50) {
    tts.speak('목적지에 도착했습니다');
    print('목적지에 도착했습니다');
    navState['finishFlag'] = true;
    return navState;
  }
  if (navState['CurrentIndex'] == navState['Route'].length - 2) {
    if (distance < 50) {
      tts.speak('목적지에 도착했습니다');
      print('목적지에 도착했습니다');
      navState['finishFlag'] = true;
      return navState;
    } else if (navState['ttsFlag'][0] == false) {
      tts.speak('목적지까지 ${(distance / 10).floor() * 10}미터 남았습니다');
      print('목적지까지 ${distance.round()}미터 남았습니다');
      navState['ttsFlag'][0] = true;
    }
  } else {
    var ttsMessage = '';
    if (distance < 50) {
      if (navState['ttsFlag'][0] == false) {
        ttsMessage = '${(distance / 10).floor() * 10}미터 앞 ';
        if (currentNode['angle'] > 45) {
          switch (currentNode['isleft']) {
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
      }
    } else if (distance < 100) {
      if (navState['ttsFlag'][1] == false) {
        ttsMessage = '${(distance / 10).floor() * 10}미터 후 ';
        if (currentNode['angle'] > 45) {
          switch (currentNode['isleft']) {
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
      }
    } else if (navState['ttsFlag'][2] == false) {
      ttsMessage = '${(distance / 10).floor() * 10}미터동안 직진입니다';
      tts.speak(ttsMessage);
      print(ttsMessage);
      navState['ttsFlag'][2] = true;
    }
  }
  return navState;
}

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
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
  int startIndex = lastIndex;

  if (lastIndex > 2) {
    startIndex -= 2;
  }

  for (int i = startIndex; i < route.length - 1; i++) {
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
    double distance = calculateDistance(
        currentLatitude, currentLongitude, pointLatitude, pointLongitude);
    double nextDistance = calculateDistance(currentLatitude, currentLongitude,
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
  double lastNodeDistance = calculateDistance(
      currentLatitude,
      currentLongitude,
      route[lastIndex]['NLatLng'].latitude,
      route[lastIndex]['NLatLng'].longitude);
  double lastNodetoNextDistance = calculateDistance(
      route[lastIndex]['NLatLng'].latitude,
      route[lastIndex]['NLatLng'].longitude,
      route[lastIndex + 1]['NLatLng'].latitude,
      route[lastIndex + 1]['NLatLng'].longitude);

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

  double nextNodeDistance = calculateDistance(
      currentLatitude,
      currentLongitude,
      route[lastIndex + 1]['NLatLng'].latitude,
      route[lastIndex + 1]['NLatLng'].longitude);

  print('minDistance: $minDistance');
  print('lastNodeDistance: $lastNodeDistance');
  print('lastNodetoNextDistance: $lastNodetoNextDistance');
  print('nextNodeDistance: $nextNodeDistance');
  print('lastIndex: $lastIndex');
  print('projectionNodeIndex: $projectionNodeIndex');

  // 이전 노드에 계속 머물러 있지만, 다음 노드와 거리가 가까워져 다음 노드로 이동되는 것 방지
  // minDistance가 5보다 크고 lastIndex 노드와 다음 노드 사이의 거리보다 현 위치에서 last Index Node까지의 거리가 더 작을 경우 lastIndex 반환
  if (nextNodeDistance > 10 && lastNodeDistance < lastNodetoNextDistance + 10) {
    projectionNodeIndex = lastIndex;
  }
  // ProjectionNodeList 반환
  return projectionNodeIndex;
}

Future<Position> _determinePosition() async {
  return await Geolocator.getCurrentPosition();
}

double calculateBearing(double lat1, double lon1, double lat2, double lon2) {
  return (450 - 180 / pi * atan2(lat2 - lat1, lon2 - lon1)) % 360;
}

Future<List<Map<String, dynamic>>> pulicBike() async {
  final results = await http.get(Uri.parse(
      'http://openapi.seoul.go.kr:8088/$public_bike_key/json/bikeList/1/1000/'));
  List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      jsonDecode(results.body)['rentBikeStatus']["row"].map((item) => {
            "NLatLng": NLatLng(double.parse(item['stationLatitude']),
                double.parse(item['stationLongitude'])),
            "StationName": item['stationName'],
            "ParkingBikeTotCnt": item['parkingBikeTotCnt'],
            "RackTotCnt": item['rackTotCnt'],
            "Shared": item['shared'],
            "StationId": item['stationId'],
          }));
  return result;
}

//길찾기 3번 연결하기

void searchRoute(searchResult, usePublicBike, publicBikes, firestore,
    authentication, routeSelectorProvider) async {
  String userGroup = await firestore
      .collection('users')
      .doc(authentication.currentUser!.uid)
      .get()
      .then((value) => value.data()!['label'].toString());
  List<double> groupPreference = await firestore
      .collection('Clusters')
      .doc(userGroup)
      .get()
      .then((value) => List<double>.from(value.data()!['centroid']));
  if (usePublicBike) {
    Map<String, dynamic> startStation = _getClosestPublicBikeStation(
        searchResult[0]['mapy'], searchResult[0]['mapx'], publicBikes);
    Map<String, dynamic> endStation = _getClosestPublicBikeStation(
        searchResult[1]['mapy'], searchResult[1]['mapx'], publicBikes);
    final toStationResults = await _requestRoute({
      "StartPoint": {
        "lat": searchResult[0]['mapy'],
        "lon": searchResult[0]['mapx']
      },
      "EndPoint": {
        "lat": startStation['NLatLng'].latitude,
        "lon": startStation['NLatLng'].longitude
      },
      "UserTaste": false,
      "UserGroup": userGroup,
      "GroupPreference": groupPreference,
    }, routeSelectorProvider);
    final fromStationResults = await _requestRoute({
      "StartPoint": {
        "lat": startStation['NLatLng'].latitude,
        "lon": startStation['NLatLng'].longitude
      },
      "EndPoint": {
        "lat": endStation['NLatLng'].latitude,
        "lon": endStation['NLatLng'].longitude
      },
      "UserTaste": false,
      "UserGroup": userGroup,
      "GroupPreference": groupPreference,
    }, routeSelectorProvider);
    final toEndResults = await _requestRoute({
      "StartPoint": {
        "lat": endStation['NLatLng'].latitude,
        "lon": endStation['NLatLng'].longitude
      },
      "EndPoint": {
        "lat": searchResult[1]['mapy'],
        "lon": searchResult[1]['mapx']
      },
      "UserTaste": false,
      "UserGroup": userGroup,
      "GroupPreference": groupPreference,
    }, routeSelectorProvider);

    // // 모든 route 정보 합치기
    // List<List<Map<String, dynamic>>> combinedRoute = [
    //   ...toStationResults['route'],
    //   ...fromStationResults['route'].sublist(1),
    //   ...toEndResults['route'].sublist(1)
    // ];

    // // full_distance 계산
    // double combinedFullDistance = toStationResults['full_distance'] +
    //     fromStationResults['full_distance'] +
    //     toEndResults['full_distance'];

    // return {
    //   "route": combinedRoute,
    //   "full_distance": combinedFullDistance,
    // };
  } else {
    final results = await _requestRoute({
      "StartPoint": {
        "lat": searchResult[0]['mapy'],
        "lon": searchResult[0]['mapx']
      },
      "EndPoint": {
        "lat": searchResult[1]['mapy'],
        "lon": searchResult[1]['mapx']
      },
      "UserTaste": false,
      "UserGroup": userGroup,
      "GroupPreference": groupPreference,
    }, routeSelectorProvider);
  }
}

//get closest 비어있지 않은 public bike
Map<String, dynamic> _getClosestPublicBikeStation(
    curLat, curLng, List<Map<String, dynamic>> publicBikes) {
  double? closestDistance;
  Map<String, dynamic> nearestStation = {};

  for (var station in publicBikes) {
    // 자전거 수가 0인 대여소는 제외
    if (int.parse(station['ParkingBikeTotCnt']) > 0) {
      // 대여소 위치
      double stationLat = station['NLatLng'].latitude;
      double stationLng = station['NLatLng'].longitude;

      // 두 지점 간의 거리 계산 (하버사인 공식 사용)
      double distance =
          calculateDistance(curLat, curLng, stationLat, stationLng);

      // 가장 가까운 대여소 업데이트
      if (closestDistance == null || distance < closestDistance) {
        closestDistance = distance;
        nearestStation = station;
      }
    }
  }

  return nearestStation;
}

Future<List<Map<String, dynamic>>> _requestRoute(
    req, routeSelectorProvider) async {
  // final List<Map<String, dynamic>> calls = List.generate(8, (index) {
  //   final List<double> groupPrefernce = List<double>.generate(8, (i) {
  //     if (i == index) {
  //       return req['GroupPreference'][i];
  //     } else {
  //       return 0.0;
  //     }
  //   });
  //   return {
  //     "Index": index + 2,
  //     "StartPoint": {
  //       "lat": req['StartPoint']['lat'],
  //       "lon": req['StartPoint']['lon']
  //     },
  //     "EndPoint": {
  //       "lat": req['EndPoint']['lat'],
  //       "lon": req['EndPoint']['lon']
  //     },
  //     "UserTaste": true,
  //     "UserGroup": req['UserGroup'],
  //     "GroupPreference": groupPrefernce,
  //   };
  // });
  // // All preferences route
  // calls.insert(0, {
  //   "Index": 1,
  //   "StartPoint": {
  //     "lat": req['StartPoint']['lat'],
  //     "lon": req['StartPoint']['lon'],
  //   },
  //   "EndPoint": {
  //     "lat": req['EndPoint']['lat'],
  //     "lon": req['EndPoint']['lon'],
  //   },
  //   "UserTaste": true,
  //   "UserGroup": req['UserGroup'],
  //   "GroupPreference": req['GroupPreference'],
  // });
  // // Fastest route
  // calls.insert(0, {
  //   "Index": 0,
  //   "StartPoint": {
  //     "lat": req['StartPoint']['lat'],
  //     "lon": req['StartPoint']['lon'],
  //   },
  //   "EndPoint": {
  //     "lat": req['EndPoint']['lat'],
  //     "lon": req['EndPoint']['lon'],
  //   },
  //   "UserTaste": false,
  //   "UserGroup": req['UserGroup'],
  //   "GroupPreference": req['GroupPreference'],
  // });

  // print([calls[0]]);

  // List<Map<String, dynamic>> resultRoute = [
  //   {},
  //   {},
  //   {},
  //   {},
  //   {},
  //   {},
  //   {},
  //   {},
  //   {},
  //   {}
  // ];

  final List<Map<String, dynamic>> calls = [];
  // 자전거 길
  calls.add({
    "Index": 4,
    "StartPoint": {
      "lat": req['StartPoint']['lat'],
      "lon": req['StartPoint']['lon'],
    },
    "EndPoint": {
      "lat": req['EndPoint']['lat'],
      "lon": req['EndPoint']['lon'],
    },
    "UserTaste": true,
    "UserGroup": req['UserGroup'],
    "GroupPreference": List<double>.generate(8, (i) {
      if (i == 7) {
        return req['GroupPreference'][i];
      } else {
        return 0.0;
      }
    }),
  });

  // 큰 길
  calls.add({
    "Index": 3,
    "StartPoint": {
      "lat": req['StartPoint']['lat'],
      "lon": req['StartPoint']['lon'],
    },
    "EndPoint": {
      "lat": req['EndPoint']['lat'],
      "lon": req['EndPoint']['lon'],
    },
    "UserTaste": true,
    "UserGroup": req['UserGroup'],
    "GroupPreference": List<double>.generate(8, (i) {
      if (i == 1 || i == 6) {
        return req['GroupPreference'][i];
      } else {
        return 0.0;
      }
    }),
  });

  // 풍경 좋은 경로
  calls.add({
    "Index": 2,
    "StartPoint": {
      "lat": req['StartPoint']['lat'],
      "lon": req['StartPoint']['lon'],
    },
    "EndPoint": {
      "lat": req['EndPoint']['lat'],
      "lon": req['EndPoint']['lon'],
    },
    "UserTaste": true,
    "UserGroup": req['UserGroup'],
    "GroupPreference": List<double>.generate(8, (i) {
      if (i == 0) {
        return req['GroupPreference'][i];
      } else {
        return 0.0;
      }
    }),
  });

  // Fastest route
  calls.insert(0, {
    "Index": 1,
    "StartPoint": {
      "lat": req['StartPoint']['lat'],
      "lon": req['StartPoint']['lon'],
    },
    "EndPoint": {
      "lat": req['EndPoint']['lat'],
      "lon": req['EndPoint']['lon'],
    },
    "UserTaste": false,
    "UserGroup": req['UserGroup'],
    "GroupPreference": req['GroupPreference'],
  });

  // All preferences route
  calls.insert(0, {
    "Index": 0,
    "StartPoint": {
      "lat": req['StartPoint']['lat'],
      "lon": req['StartPoint']['lon'],
    },
    "EndPoint": {
      "lat": req['EndPoint']['lat'],
      "lon": req['EndPoint']['lon'],
    },
    "UserTaste": true,
    "UserGroup": req['UserGroup'],
    "GroupPreference": req['GroupPreference'],
  });

  List<Map<String, dynamic>> resultRoute = [
    {},
    {},
    {},
    {},
    {},
  ];

  await Future.forEach(calls, (call) async {
    // Remove [calls[0]] to use all preferences route
    final results = await FirebaseFunctions.instance
        .httpsCallable('request_route_debug')
        .call(call);
    print('results ${call['Index']}: ${results.data['full_distance']}');
    routeSelectorProvider.setRoute({
      "route": _preprocessRoute(
        List<Map<String, dynamic>>.from(
          results.data['path'].map((point) {
            return {
              "NLatLng": NLatLng(point['lat'], point['lon']),
              "distance": point['distance']
            };
          }),
        ),
      ),
      "full_distance": results.data['full_distance'],
    }, call['Index']);
  });

  return resultRoute;
}

// final results = await FirebaseFunctions.instance
//     .httpsCallable('request_route_debug')
//     .call(req);

// List<Map<String, dynamic>> route =
//     List<Map<String, dynamic>>.from(results.data['path'].map((point) {
//   return {
//     "NLatLng": NLatLng(point['lat'], point['lon']),
//     // "distance": point['distance']
//   };
// }));

List<Map<String, dynamic>> _preprocessRoute(List<Map<String, dynamic>> route) {
  List<Map<String, dynamic>> routeInfo = [];

  for (var i = 0; i < route.length - 2; i++) {
    final Map<String, dynamic> currentNode = route[i];
    final Map<String, dynamic> nextNode = route[i + 1];
    final Map<String, dynamic> nextNextNode = route[i + 2];

    final link1 = [
      nextNode["NLatLng"].longitude - currentNode["NLatLng"].longitude,
      nextNode["NLatLng"].latitude - currentNode["NLatLng"].latitude,
      0.0,
    ];
    final link1Norm = sqrt(pow(link1[0], 2) + pow(link1[1], 2));
    final link2 = [
      nextNextNode["NLatLng"].longitude - nextNode["NLatLng"].longitude,
      nextNextNode["NLatLng"].latitude - nextNode["NLatLng"].latitude,
      0.0,
    ];
    final link2Norm = sqrt(pow(link2[0], 2) + pow(link2[1], 2));
    final crossProduct = [
      link1[1] * link2[2] - link1[2] * link2[1],
      link1[2] * link2[0] - link1[0] * link2[2],
      link1[0] * link2[1] - link1[1] * link2[0],
    ];
    final dotProduct =
        link1[0] * link2[0] + link1[1] * link2[1] + link1[2] * link2[2];
    routeInfo.add({
      "NLatLng": currentNode["NLatLng"], // 현재 노드의 좌표
      "distance": nextNode['distance'], // 다음 노드까지의 거리
      "isleft": crossProduct[2] > 0, // 다음 노드에서 좌회전인지 우회전인지 여부
      "angle": acos(dotProduct / (link1Norm * link2Norm)) *
          180 /
          pi, // 다음 노드에서의 회전각도
    });
  }
  routeInfo.add({
    "NLatLng": route[route.length - 2]["NLatLng"],
    "distance": route[route.length - 1]['distance'],
    "isleft": null,
    "angle": null,
  });
  routeInfo.add({
    "NLatLng": route[route.length - 1]["NLatLng"],
    "distance": null,
    "isleft": null,
    "angle": null,
  });

  return routeInfo;
}

Future<List<Map<String, dynamic>>> searchRequest(req) async {
  String query = req['query'];
  final results = await http.get(
    Uri.parse(
        'https://openapi.naver.com/v1/search/local.json?query=$query&display=100&start=1&sort=random'),
    headers: {
      "X-Naver-Client-Id": client_id,
      "X-Naver-Client-Secret": client_secret,
    },
  );
  List<Map<String, dynamic>> result = List<Map<String, dynamic>>.from(
      jsonDecode(results.body)['items'].map((item) {
    return {
      "title": item['title'].replaceAll(RegExp(r'<[^>]*>'), ''),
      "link": item['link'],
      "category": item['category'],
      "description": item['description'],
      "telephone": item['telephone'],
      "address": item['address'],
      "roadAddress": item['roadAddress'],
      "NLatLng": NLatLng(
          double.parse(item['mapy']) / 10e6, double.parse(item['mapx']) / 10e6),
      "mapx": double.parse(item['mapx']) / 10e6,
      "mapy": double.parse(item['mapy']) / 10e6,
    };
  }));
  return result;
}

class Navigationend extends StatefulWidget {
  const Navigationend({
    Key? key,
    required this.fullDistance,
    required this.tick,
    required this.firestore,
    required this.authentication,
  }) : super(key: key);

  final double fullDistance;
  final double tick;
  final FirebaseFirestore firestore;
  final FirebaseAuth authentication;

  @override
  NavigationendState createState() => NavigationendState();
}

class NavigationendState extends State<Navigationend> {
  int rating = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('안내 종료'),
      content: SizedBox(
        height: 400,
        child: Column(
          children: <Widget>[
            const Text('목적지에 도착했습니다'),
            Text('총 이동거리: ${widget.fullDistance.round()}m'),
            Text('총 소요시간: ${(widget.tick * 3 / 60).round()}분'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(rating > index ? Icons.star : Icons.star_border,
                      color: Colors.amber, size: 40.0),
                  onPressed: () {
                    setState(() {
                      rating = index + 1;
                      print(rating);
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
            widget.firestore //TODO: Better Feedback
                .collection('users')
                .doc(widget.authentication.currentUser!.uid)
                .update({
              'rating': rating,
            });
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}

// class RouteProvider with ChangeNotifier {
//   List<Map<String, dynamic>> routeResult = [{}, {}, {}, {}, {}, {}, {}];

//   final FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final FirebaseAuth authentication = FirebaseAuth.instance;

//   void setRouteResult(Map<String, dynamic> result, index) {
//     routeResult[index] = result;
//     notifyListeners();
//   }
// }

// class RouteResult extends StatefulWidget {
//   const RouteResult({
//     Key? key,
//     required this.searchResult,
//     required this.usePublicBike,
//     required this.publicBikes,
//     required this.firestore,
//     required this.authentication,
//   }) : super(key: key);

//   final List<Map<String, dynamic>> searchResult;
//   final bool usePublicBike;
//   final List<Map<String, dynamic>> publicBikes;
//   final FirebaseFirestore firestore;
//   final FirebaseAuth authentication;

//   @override
//   RouteResultState createState() => RouteResultState();
// }

// class RouteResultState extends State<RouteResult> {
//   @override
//   void initState() {
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         height: 200,
//         child: ListView(
//           scrollDirection: Axis.horizontal,
//           children: <Widget>[
//             for (var i = 0; i < widget.searchResult.length - 1; i++)
//               FutureBuilder(
//                 future: searchRoute(
//                   widget.searchResult.sublist(i, i + 2),
//                   widget.usePublicBike,
//                   widget.publicBikes,
//                   widget.firestore,
//                   widget.authentication,
//                 ),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.done) {
//                     return RouteCard(
//                       route: snapshot.data?['route'],
//                       fullDistance: snapshot.data?['full_distance'],
//                       index: i,
//                     );
//                   } else {
//                     return const CircularProgressIndicator();
//                   }
//                 },
//               ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class RouteCard extends StatelessWidget {
//   const RouteCard({
//     Key? key,
//     required this.route,
//     required this.fullDistance,
//     required this.index,
//   }) : super(key: key);

//   final List<Map<String, dynamic>> route;
//   final double fullDistance;
//   final int index;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       child: Column(
//         children: <Widget>[
//           Text('Route $index'),
//           Text('Distance: ${fullDistance.round()}m'),
//           for (var i = 0; i < route.length; i++)
//             ListTile(
//               title: Text('Node $i'),
//               subtitle: Text(
//                   'Lat: ${route[i]['NLatLng'].latitude}, Lon: ${route[i]['NLatLng'].longitude}'),
//             ),
//         ],
//       ),
//     );
//   }
// }

// class RouteProvider with ChangeNotifier {
//   // Map to store the fetched route data
//   List<Map<String, String>> _routeData = {};

//   // Getter for route data
//   List<Map<String, String>> get routeData => _routeData;

//   // Function to fetch route data and store it
//   Future<void> fetchAllRoutes(searchResult, usePublicBike, publicBikes, firestore, authentication) async {
//     // Create a list of futures to fetch data for all routes
//     List<Future> routeFutures = routeIds.map((routeId) => searchRoute(searchResult, usePublicBike, publicBikes, firestore, authentication).then((data) {
//       _routeData[routeId] = data;
//       notifyListeners(); // Notify listeners when data is updated
//     })).toList();

//     // Wait for all futures to complete
//     await Future.wait(routeFutures);
//   }
// }