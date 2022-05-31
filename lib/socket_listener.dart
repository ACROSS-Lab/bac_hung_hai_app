

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

typedef dataFc = Future<void> Function(String, SocketListener);

class SocketListener {

  final Socket socket;
  dataFc initialDataFc = (ev,s)async {print("default");};
  dataFc waterPollutionFc = (ev,s)async {print("default");};
  dataFc solidPollutionFc = (ev,s)async {print("default");};

  SocketListener({required this.socket});

  Future<void> startListening() async {
    socket.listen((event) async{
      print(event);
      await listenMethod(event);
    });
  }


  Future<void> listenMethod(event) async {
    var mess = utf8.decode(event);
    print(mess);

    for (var line in mess.split("\n").where((element) => element.trim() != '')) {
      if (line.startsWith("_INIT_DATA_")) {
          await initialDataFc(line, this);
      }
      else if (line.startsWith("_WATER_")) {
        await waterPollutionFc(line, this);
      }
      else if (line.startsWith("_SOLID_")) {
        await solidPollutionFc(line, this);
      }
    }
  }


  Future<void> send_line(String message) async{
    socket.add(utf8.encode('$message\n'));
    await socket.flush();
  }


}