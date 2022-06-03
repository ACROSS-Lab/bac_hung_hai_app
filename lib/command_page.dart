

import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:bac_hung_hai_app/GameAction.dart';
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
    return _CommandPageState(init_data: init_data, socket: socket, subscription: subscription);
  }
  
}


class _CommandPageState extends State<CommandPage> {



  final StreamSubscription<Uint8List> subscription;
  final dynamic init_data;



  _CommandPageState({required this.init_data, required this.socket, required this.subscription}) : super() {
    init();
  }

  void init() async {

    total = init_data['budget'];

    //Add a listener function to the socket to process received data
    subscription.onData(listenSocket);

    //Process initial data to create the list of possible actions
    gameActions = { for (var action in init_data['actions'].map<GameAction>(
                (action) => GameAction(
                id: action['id'],
                name: action['name'],
                cost: num.parse(action['cost']),
                once_per_game: action['once_per_game'] == 'true',
                mandatory: action['mandatory'] == 'true',
                asset_name: action['asset_name'])
        ).toList()) action.id : action };
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
  Map<String, bool> selectedActions   = {};
  Map<String, GameAction> gameActions = {};

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

  void validate() {
    var takenActions = <String>[];
    for(var choice in  activated_switches.keys) {
      if (activated_switches[choice]!){
        if (group_choices.containsKey(choice)){
          takenActions.add(group_choices[choice]!);
        }
        else{
          takenActions.add(choice);
        }

      }

    }
    print(takenActions);
    socket.add(utf8.encode('_AFEOT_:$takenActions\n'));
  }

  //TODO: refactor in a map of pair, or null string for false
  Map<String, bool>   activated_switches  = {};
  Map<String, String> group_choices       = {};
  bool alone = false;
  @override
  Widget build(BuildContext context) {
    var actions = <Widget>[];

    //Initializes all actions as not selected
    gameActions.keys.forEach((element) {
      if (! selectedActions.containsKey(element)) {
        selectedActions[element] = false;
      }
    });

    var actionGroups = groupBy(gameActions.values, (GameAction action) => action.name);
    var background_colors = [Colors.grey[300], Colors.white];
    var i = 0;
    for (var group in actionGroups.entries) {
      var first = group.value.first;
      if (group.value.length > 1){

        List<Widget> choices = [];
        if (! group_choices.containsKey(first.id)) {
          group_choices[first.id] = first.id;
        }
        if (! first.mandatory) {
          if (! activated_switches.containsKey(first.id)) {
            activated_switches[first.id] = false;
          }
          choices.add(
            Switch(value: activated_switches[first.id]!, onChanged: (value){
              setState((){
                activated_switches[first.id] = value;
              });

            })
          );
        }
        else {
            activated_switches[first.id] = true;
        }
        choices.addAll(
          group.value.mapIndexed<Widget>((index, action) =>
            Expanded(
              child:
              Column(
                children: [
                  Radio<String>(
                    value: action.id,
                    groupValue: group_choices[first.id]!,
                    onChanged:
                    activated_switches[first.id]??false
                        ? (value){
                          setState(() {
                            group_choices[first.id] = value!;
                          });
                      }
                    : null
                  ),
                  Text('${action.cost}\$'),
                ],
              ),
            )
          ).toList()
        );

        choices.add(const Spacer());
        choices.add(
          Image.asset('assets/${first.asset_name}', height: 100, width: 100,
          errorBuilder: (context, obj, stack) => Image.asset('assets/waste-collection.png', height: 100, width: 100),)
        );
      // choicesValues.add(0);
      // var choices = <Widget>[];
      //
      //
      // // For groups containing more than one item, we create a radio button
      // if (group.value.length > 1){
      //   var switchEnabled = true;
      //   int j = 0;
      //   if (first['mandatory'] == 'true') {
      //     choices.add(
      //       Switch(value: switchEnabled, onChanged: checkboxChanged)
      //     );
      //   }
      //   for (var action in group.value){
      //     choices.add(
      //       Column(
      //         children: [
      //           Radio(
      //               value: j,
      //               groupValue: choicesValues[i],
      //               onChanged: switchEnabled ? (int? value) {
      //                 setState(() {
      //                   print(choicesValues);
      //                   choicesValues[i] = value!;
      //                 });
      //               } : null,
      //           ),
      //           Text('${action['cost']}\$'),
      //         ],
      //       )
      //     );
      //     j++;
      //   }



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
                          '${first.name}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ),
                      Row(
                        children:
                          choices

                        ,
                      ),
                    ]
                ),
              ),
            )
        );
      }
      else {
        if (! activated_switches.containsKey(first.id)) {
          activated_switches[first.id] = false;
        }
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
                          '${action.name}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ),
                      Row(
                        children: [
                          Switch(
                              value: activated_switches[action.id]!,
                              onChanged: (value){
                                setState((){
                                    activated_switches[first.id] = value;
                                });
                              }),
                          Text('${action.cost}\$'),
                          const Spacer(),
                          Image.asset('assets/${action.asset_name}', height: 100, width: 100,
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
                  Center(child: ElevatedButton(onPressed: validate,child: const Text('Valider le tour'),))
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