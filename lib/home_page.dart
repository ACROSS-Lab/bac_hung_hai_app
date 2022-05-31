
import 'package:flutter/material.dart';

import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'command_page.dart';

class MyHomePage extends StatefulWidget {

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();

}

class _MyHomePageState extends State<MyHomePage> {

  Socket? socket      = null;
  var ipController    = TextEditingController(text:'192.168.0.195');
  var portController  = TextEditingController(text:'8989');

  Future<void> _try_join() async {


    try{

      /*
      final channel = IOWebSocketChannel.connect(
      Uri.parse('ws://192.168.98.118:8989'),
      );
      */

      print('trying to join the game');
      if (socket != null){
        socket?.close();
      }
      socket = await Socket.connect(ipController.text, int.parse(portController.text));

      print("connected");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connected !'),
        ),
      );

      await push_command_page();



    }
    catch (exception) {
      print(exception.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exception.toString()),
        ),
      );
    }


  }

  Future<void> push_command_page() async {
    // listen to the received data event stream
    socket?.listen((List<int> event) {

      var mess = utf8.decode(event);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mess),),
      );
      print(mess);
      for(var line in mess.split("\n").where((element) => element.trim() != '')){

        if (line.startsWith("_INIT_DATA_")) {
          var data = jsonDecode(line.replaceAll("_INIT_DATA_:", ''));
          print("player_name:" + data['player_name']);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CommandPage(socket: socket!,init_data: data)),
          );


        }

      }

      print(mess);

    });

    // channel.stream.listen((message) {
    //   print(message);
    // });
    //
    // channel.sink.add('_AFC_:192.168.98.110\n');

    // send hello
    socket?.add(utf8.encode('_AFC_:${socket?.address.address}\n'));
    await socket?.flush();

  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.title}'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
                ElevatedButton(onPressed: _try_join, child: const Text('Join the game !'),)
              ],
            ),
          ]),
      );
  }
}
