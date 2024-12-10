import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

void feedback(navState, userGroup) async {
  print('node1 : ${navState['Route'][navState['CurrentIndex']]["id"]}');
  print('node2 : ${navState['Route'][navState['CurrentIndex'] + 1]["id"]}');
  print('label : $userGroup');
  FirebaseFunctions.instance.httpsCallable('update_feedback')({
    "connection": {
      "node1": '${navState['Route'][navState['CurrentIndex']]["id"]}',
      "node2": '${navState['Route'][navState['CurrentIndex'] + 1]["id"]}',
    },
    "label": userGroup,
    "pref": [1, -1, 1, 0, 0, 0, 0, 0, 0, 0],
  });
}
