

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

typedef dataFc = void Function(String, SocketListener);

class SocketListener {

  final Socket socket;
  dataFc initialDataFc = (ev,s){print("default");};
  dataFc waterPollutionFc = (ev,s){print("default");};
  dataFc solidPollutionFc = (ev,s){print("default");};

  SocketListener({required this.socket}) {
    socket.listen(listenMethod);
  }

  void listenMethod(event) {
    var mess = utf8.decode(event);
    print(mess);

    for (var line in mess.split("\n").where((element) => element.trim() != '')) {
      if (line.startsWith("_INIT_DATA_")) {
          initialDataFc(line, this);
      }
      else if (line.startsWith("_WATER_")) {
          waterPollutionFc(line, this);
      }
      else if (line.startsWith("_SOLID_")) {
          solidPollutionFc(line, this);
      }
    }
  }


  void send_line(String message) async{
    socket.add(utf8.encode('$message\n'));
    await socket.flush();
  }


}