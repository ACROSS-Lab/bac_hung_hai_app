

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class CommandPage extends StatefulWidget {

  final Socket  socket;
  final String  player_name;
  final int     init_budget;
  final dynamic init_data;
  final StreamSubscription<Uint8List> subscription;

  CommandPage({Key? key, required this.socket, required this.init_data, required this.subscription}) :
      player_name = init_data['player_name'],
      init_budget = init_data['budget'],
      super(key: key)
  ;


  @override
  State<StatefulWidget> createState() {
    return _CommandPageState(total: init_budget, socket: socket, subscription: subscription);
  }
  
}


class _CommandPageState extends State<CommandPage> {



  final StreamSubscription<Uint8List> subscription;

  _CommandPageState({required this.total, required this.socket, required this.subscription}) : super() {
      //socket.listen(listenSocket);
    subscription.onData(listenSocket);
  }

  void listenSocket(dynamic event) {


    var mess = utf8.decode(event);
    // ScaffoldMessenger.of(context).showSnackBar(
    //   SnackBar(content: Text(mess),),
    // );
    print(mess);
    for(var line in mess.split("\n").where((element) => element.trim().replaceAll('\r', '') != '')){
      line = line.trim().replaceAll('\r', '');
      if (line.startsWith("_WATER_")) {
        List<num> data = jsonDecode(line.replaceAll("_WATER_:", '')).cast<num>();
        print(data);

        setState((){
          water_pollution = charts.Series(
              id: 'water pollution',
              colorFn: (_, __) => charts.MaterialPalette.deepOrange.shadeDefault,
              data: data.mapIndexed((i, v) => LinearData(i, v)).toList(),
              domainFn: (ld,_) => ld.i,
              measureFn: (ld, _) => ld.v
            );
        });

      }
      else if (line.startsWith("_SOLID_")){
        List data = jsonDecode(line.replaceAll("_SOLID_:", '')).cast<num>();
        print(data);
        setState(() {
          solid_pollution = charts.Series<LinearData, int>(
            id: 'Solid pollution',
            colorFn: (_, __) => charts.MaterialPalette.teal.shadeDefault,
            domainFn: (LinearData datum, _) => datum.i,
            measureFn: (LinearData datum, _) => datum.v,
            data: data.mapIndexed((i, v) => LinearData(i, v)).toList(),
          );
        });
      }
      else if (line.startsWith("_PRODUCTIVITY_")) {
        List<num> data = jsonDecode(line.replaceAll("_PRODUCTIVITY_:", '')).cast<num>();
        print(data);
        setState(() {
          productivity = charts.Series<LinearData, int>(
              id: 'Productivity',
              colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
              domainFn: (LinearData datum, _) => datum.i,
              measureFn: (LinearData datum, _) => datum.v,
              data: data.mapIndexed((i, v) => LinearData(i, v)).toList(),
          );
        });
      }

    }
  }

  int total             = 0;
  bool wasteCollection  = false;
  bool drainDredge      = false;
  int rest              =  0;
  Socket socket;
  charts.Series<LinearData, int> water_pollution = charts.Series(
      id: "Water pollution",
      data: [],
      domainFn: (ld,_) => ld.i,
      measureFn: (ld, _) => ld.v
  );
  charts.Series<LinearData, int> solid_pollution = charts.Series(
      id: "Solid pollution",
      data: [],
      domainFn: (ld,_) => ld.i,
      measureFn: (ld, _) => ld.v
  );

  charts.Series<LinearData, int> productivity = charts.Series(
      id: "Productivity",
      data: [],
      domainFn: (ld,_) => ld.i,
      measureFn: (ld, _) => ld.v
  );


  void radioChanged(dynamic value) {
    print(value);
    if (value != null) {
      setState() {
        rest += 40 * (value ? -1 : 1);
        wasteCollection = value;
      }
    }
  }

  void checkboxChanged(bool? value) {
    print('coucou');
    if (value != null) {
      setState() {
        rest += 50 * (value ? -1 : 1);
        drainDredge = value;
      }
    }
  }
  void validate() {

  }


  @override
  Widget build(BuildContext context) {
    var actions = <Widget>[];

    var actionGroups = groupBy(widget.init_data['actions'], (dynamic action) => action['name']);
    var background_colors = [Colors.grey[300], Colors.white];
    var i = 0;
    for(var group in actionGroups.entries) {

      // For groups containing more than one item, we create a radio button
      if (group.value.length > 1){
        print(group.value);
        var choices = <Widget>[];
        for (var action in group.value){
          choices.add(
            Column(
              children: [
                Radio(value: false, groupValue: action['name'], onChanged: radioChanged),
                Text('${action['cost']}\$'),
              ],
            )
          );
        }

        choices.add(const Spacer());
        choices.add(
            Image.asset('assets/${group.value.first['asset_name']}', height: 100, width: 100,
                        errorBuilder: (context, obj, stack) => Image.asset('assets/waste-collection.png', height: 100, width: 100),)
        );

        actions.add(
            Container(
              color: background_colors[i%2],
              child:
              Padding(
                padding: EdgeInsets.all(8),
                child: Column(
                    children: [
                      Padding(padding: EdgeInsets.all(3),
                        child: Text(
                          '${group.value.first['name']}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ),
                      Row(
                        children: choices
                        ,
                      ),
                    ]
                ),
              ),
            )
        );
      }
      else {
        var action = group.value.first;
        actions.add(
            Container(
              color: background_colors[i%2],
              child:
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(3),
                        child: Text(
                          '${action['name']}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ),
                      Row(
                        children: [
                          Checkbox(value: false, onChanged: checkboxChanged),
                          Text('${action['cost']}\$'),
                          const Spacer(),
                          Image.asset('assets/${action['asset_name']}', height: 100, width: 100,
                                      errorBuilder: (_context, obj, stack) => Image.asset('assets/waste-collection.png', height: 100, width: 100),)
                          //Image.asset('assets/drain-dredge.png', height: 100, width: 100,),
                        ],
                      ),
                    ]
                ),
              ),
            )
        );
      }
      i++;
    }

    return Scaffold(

      body:
          DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text('${widget.player_name}: $total\$'),
                bottom: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.list), text: 'Actions',),
                    Tab(icon: Icon(Icons.show_chart), text: 'Statistiques',),
                  ],
                ),
              ),
              body: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children:[
                        Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: ListView(
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(8),
                            children: actions,
                          ),
                        ),
                        Expanded(
                            child:
                            Padding(
                              padding:
                              const EdgeInsets.all(8.0),
                              child: charts.LineChart(
                                [
                                  solid_pollution,
                                  water_pollution,
                                  productivity,
                                ],
                                animate: true,
                              ),
                            )
                        ),

                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5),
                    child: Row(
                      children: [
                        Text(
                          'Reste:',
                          style: Theme.of(context).textTheme.headline4,
                        ),
                        const Spacer(),
                        Text(
                          '${rest}\$',
                          style: Theme.of(context).textTheme.headline4,
                        )
                      ],
                    ),
                  ),
                  Center(child: ElevatedButton(child: const Text('Valider le tour'), onPressed: validate,))
                ],
              ),
            ),
          )
    );




  }

}

class LinearData {

  int i;
  num v;

  LinearData(this.i, this.v);

}