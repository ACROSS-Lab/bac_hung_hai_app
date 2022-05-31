

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:bac_hung_hai_app/socket_listener.dart';
import "package:collection/collection.dart";
import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:flutter/material.dart';

class CommandPage extends StatefulWidget {

  final SocketListener  socketListener;
  final String  player_name;
  final int     init_budget;
  final dynamic init_data;

  CommandPage({Key? key, required this.socketListener, required this.init_data}) :
      player_name = init_data['player_name'],
      init_budget = init_data['budget'],
      super(key: key)
  ;


  @override
  State<StatefulWidget> createState() {
    return _CommandPageState(total: init_budget, socketListener: socketListener);
  }
  
}


class _CommandPageState extends State<CommandPage> {

  _CommandPageState({required this.total, required this.socketListener}) : super() {
    socketListener.waterPollutionFc = read_water_pollution;
    socketListener.solidPollutionFc = read_solid_pollution;

  }

  void read_water_pollution(String line, SocketListener socketListener) {
    var data = jsonDecode(line.replaceAll("_WATER_:", ''));
    setState(() {
      water_pollution = data;
    });
  }


  void read_solid_pollution(String line, SocketListener socketListener) {
    var data = jsonDecode(line.replaceAll("_SOLID_:", ''));
    setState(() {var tmp = <LinearData>[];
      var i = 0;
      for (var datum in data) {
        tmp.add(LinearData(i, datum));
        i++;
      }
      solid_pollution = [charts.Series<LinearData, int>(
        id: 'Solid',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (LinearData datum, _) => datum.i,
        measureFn: (LinearData datum, _) => datum.v,
        data: tmp,
      )];
    });
  }


  int total             = 0;
  bool wasteCollection  = false;
  bool drainDredge      = false;
  int rest              =  0;
  SocketListener socketListener;
  List<charts.Series<LinearData, int>> water_pollution = [];
  List<charts.Series<LinearData, int>> solid_pollution = [];


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
    for(var groups in actionGroups.entries) {

      // For groups containing more than one item, we create a radio button
      if (groups.value.length > 1){
        print(groups.value);
        var choices = <Widget>[];
        for (var action in groups.value){
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
        choices.add(Image.asset('assets/waste-collection.png'));

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
                          '${groups.value.first['name']}',
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
        var action = groups.value.first;
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
                          Image.asset('assets/waste-collection.png'),
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
                        ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          children: actions,
                        ),
                        ListView(
                          shrinkWrap: true,
                          padding: const EdgeInsets.all(8),
                          children: [
                          charts.LineChart(
                            solid_pollution,
                            animate: true,
                          )
                          ],

                        )
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
                  Center(child: ElevatedButton(child:const Text('Valider le tour'), onPressed: validate,))
                ],
              ),
            ),
          )
    );




  }

}

class LinearData {

  int i;
  double v;

  LinearData(this.i, this.v);

}