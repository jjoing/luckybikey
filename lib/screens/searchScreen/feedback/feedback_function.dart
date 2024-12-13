import 'package:cloud_functions/cloud_functions.dart';

void feedback(navState, userGroup, featureIndex) {
  print('node1 : ${navState['Route'][navState['CurrentIndex']]["id"]}');
  print('node2 : ${navState['Route'][navState['CurrentIndex'] + 1]["id"]}');
  print('label : $userGroup');

  List pref = [0, 0, 0, 0, 0, 0, 0, 0];
  pref[featureIndex] = 1;

  FirebaseFunctions.instance.httpsCallable('update_feedback')({
    "connection": {
      "node1": '${navState['Route'][navState['CurrentIndex']]["id"]}',
      "node2": '${navState['Route'][navState['CurrentIndex'] + 1]["id"]}',
      "lat":
          '${navState['Route'][navState['CurrentIndex'] + 1]["NLatLng"].latitude}',
      "lon":
          '${navState['Route'][navState['CurrentIndex'] + 1]["NLatLng"].longitude}',
    },
    "label": userGroup,
    "pref": pref,
  });
}
