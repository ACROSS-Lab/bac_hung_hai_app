
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'command_page.dart';
import 'package:wakelock/wakelock.dart';


class MyHomePage extends StatefulWidget {

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();

}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin{

  Socket? socket      = null;
  var ipController    = TextEditingController(text:'192.168.0.195');
  var portController  = TextEditingController(text:'8989');
  late AnimationController controller;
  bool loading        = false;

  @override
  void initState() {
    // Prevent screen from going into sleep mode:
    Wakelock.enable();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..addListener(() {
      setState(() {});
    });
    controller.repeat(reverse: true);
    super.initState();
  }
  Future<void> _try_join() async {

    try{
      setState(() {
        loading = true;
      });

      print('trying to join the game');
      if (socket != null){
        socket?.close();
      }
      socket = await Socket.connect(ipController.text, int.parse(portController.text));

      await push_command_page();

    }
    catch (exception) {
      print(exception.toString());
      setState(() {
        controller.stop();
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exception.toString()),
        ),
      );
    }


  }

  StreamSubscription<Uint8List>? subscription;
  Future<void> push_command_page() async {

    // listen to the received data event stream
    subscription = socket?.listen((event)  {
      try {
        var mess = utf8.decode(event, allowMalformed: true);
        print(mess);
        for (var line in mess.split("\n").where((element) =>
        element.trim() != '')) {
          //If we receive the "init" data, it means we are accepted as a player and thus can push the game page
          if (line.startsWith("_INIT_DATA_")) {
            var data = jsonDecode(line.replaceAll("_INIT_DATA_:", ''));
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => CommandPage(
                  socket: socket!,
                  subscription: subscription!,
                  init_data: data)),
            );
            setState(() {
              loading = false;
            });
          }
        }
      }
      catch (exception) {
        print(exception.toString());
        setState(() {
        controller.stop();
        loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(exception.toString()),
          ),
        );
      }
    });

    // Send request for connection
    socket?.add(utf8.encode('_AFC_:${socket?.address.address}\n'));
    await socket?.flush();

  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: loading,
            child: CircularProgressIndicator(
              value: controller.value,
              semanticsLabel: 'Linear progress indicator',
            ),
          ),
            Row(
              children: [
                Flexible(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      controller: ipController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'IP',
                      ),
                    ),
                  ),
                ),
                Flexible(child:
                Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                  controller: portController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Port',
                  ),
                ))
                )
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: _try_join,
                    child: Text(
                        'Join the game !',
                      style: Theme.of(context).textTheme.headline5,
                    ),
                  ),
                )
              ],
            ),
          ]),
      );
  }
}
