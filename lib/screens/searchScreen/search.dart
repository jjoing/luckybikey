import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_naver_map/flutter_naver_map.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../screens/searchScreen/modal.dart';
import '../../contents/way_sample_data.dart';
import '../../utils/mapAPI.dart';
import '../../components/bottomNaviBar.dart';

enum TtsState { playing, stopped, paused, continued }

class Search extends StatefulWidget {
  const Search({super.key});

  @override
  State<Search> createState() => _SearchState();
}

Future<Map<String, dynamic>> _request_route(req) async {
  final results =
      await FirebaseFunctions.instance.httpsCallable('request_route').call(req);

  List<NLatLng> route = List<NLatLng>.from(results.data['route'].map((point) {
    return NLatLng(point['lat'], point['lon']);
  }));

  return {"route": route, "full_distance": results.data['full_distance']};
}

Future<List<Map<String, dynamic>>> _search_request(req) async {
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

class _SearchState extends State<Search> {
  void _permission() async {
    var requestStatus = await Permission.location.request();
    var status = await Permission.location.status;
    if (requestStatus.isPermanentlyDenied || status.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  final FlutterTts tts = FlutterTts();

  @override
  void initState() {
    _permission();
    super.initState();
    tts.setLanguage("ko-KR"); //언어설정
    tts.setSpeechRate(0.5); //말하는 속도(0.1~2.0)
    tts.setVolume(0.6); //볼륨(0.0~1.0)
    tts.setPitch(1); //음높이(0.5~2.0)
  }

  List<NLatLng> sampleData2Coords = Sample_Data_2.map((point) {
    return NLatLng(point['lat'], point['lon']);
  }).toList();

  List<NLatLng> route = [];
  List<Map<String, dynamic>> searchResult = [{}, {}];
  List<Map<String, dynamic>> searchSuggestions = [];

  Key _mapKey = UniqueKey(); // 지도 리로드를 위한 Key
  bool _showMarker = false; // 마커 표시 여부
  bool _showPath = false; // 경로 표시 여부

  var txt_start = TextEditingController();
  var txt_end = TextEditingController();

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
                            child: SearchAnchor(builder: (BuildContext context,
                                SearchController controller) {
                              return TextField(
                                controller: controller,
                                onChanged: (value) {
                                  searchResult[0] = {};
                                },
                                textInputAction: TextInputAction.go,
                                onSubmitted: (value) async {
                                  await _search_request({"query": value}).then(
                                      (result) {
                                    setState(() {
                                      _mapKey = UniqueKey();
                                      searchSuggestions = result;
                                    });
                                    controller.openView();
                                  }, onError: (error, stackTrace) {
                                    print(error);
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: '출발지 입력',
                                ),
                              );
                            }, suggestionsBuilder: (BuildContext context,
                                SearchController controller) {
                              return List<ListTile>.generate(
                                searchSuggestions.length,
                                (index) {
                                  return ListTile(
                                    title:
                                        Text(searchSuggestions[index]['title']),
                                    onTap: () {
                                      setState(() {
                                        _mapKey = UniqueKey();
                                        searchResult[0] =
                                            searchSuggestions[index];
                                        controller.closeView(
                                            searchSuggestions[index]['title']);
                                      });
                                    },
                                  );
                                },
                              );
                            }),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            height: 50,
                            width: MediaQuery.of(context).size.width * 0.72,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white70,
                            ),
                            child: SearchAnchor(builder: (BuildContext context,
                                SearchController controller) {
                              return TextField(
                                controller: controller,
                                onChanged: (value) {
                                  searchResult[1] = {};
                                },
                                textInputAction: TextInputAction.go,
                                onSubmitted: (value) async {
                                  await _search_request({"query": value}).then(
                                      (result) {
                                    setState(() {
                                      _mapKey = UniqueKey();
                                      searchSuggestions = result;
                                    });
                                    controller.openView();
                                  }, onError: (error, stackTrace) {
                                    print(error);
                                  });
                                },
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: '도착지 입력',
                                ),
                              );
                            }, suggestionsBuilder: (BuildContext context,
                                SearchController controller) {
                              return List<ListTile>.generate(
                                searchSuggestions.length,
                                (index) {
                                  return ListTile(
                                    title:
                                        Text(searchSuggestions[index]['title']),
                                    onTap: () {
                                      setState(() {
                                        _mapKey = UniqueKey();
                                        searchResult[1] =
                                            searchSuggestions[index];
                                        controller.closeView(
                                            searchSuggestions[index]['title']);
                                      });
                                    },
                                  );
                                },
                              );
                            }),
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
                            tts.speak("경로를 찾는 중입니다.");
                            route = [];
                            print("speak");
                            if (searchResult[0].isEmpty ||
                                searchResult[1].isEmpty) {
                              print("searchResult is empty");
                              return;
                            }
                            _request_route({
                              "StartPoint": {
                                "lat": searchResult[0]['mapy'],
                                "lon": searchResult[0]['mapx']
                              },
                              "EndPoint": {
                                "lat": searchResult[1]['mapy'],
                                "lon": searchResult[1]['mapx']
                              },
                              "UseSharing": false,
                              "UserTaste": false,
                            }).then((result) {
                              setState(() {
                                print("request_route done");
                                _mapKey = UniqueKey();
                                route = result['route'];
                              });
                              // print(result['route']);
                              // print(result['route'].runtimeType);
                              // print(result['full_distance']);
                              // print(result['full_distance'].runtimeType);
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

                        for (var i = 0; i < searchResult.length; i++) {
                          if (searchResult[i].isEmpty) {
                            continue;
                          }
                          final marker = NMarker(
                            id: 'testMarker$i',
                            position: searchResult[i]['NLatLng'],
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
              bottom: 200,
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
      bottomNavigationBar: BottomNavigation(),
    );
  }
}
