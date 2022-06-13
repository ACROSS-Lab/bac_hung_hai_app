

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
 // final int     init_budget;
  final dynamic init_data;
  final StreamSubscription<Uint8List> subscription;

  CommandPage({Key? key, required this.socket, required this.init_data, required this.subscription}) :
      player_name = init_data['player_name'],
   //   init_budget = init_data['budget'],
      super(key: key)
  ;


  @override
  State<StatefulWidget> createState() {
    return _CommandPageState(init_data: init_data, socket: socket, subscription: subscription);
  }
  
}


class _CommandPageState extends State<CommandPage> {



  StreamSubscription<Uint8List> subscription;
  final dynamic init_data;
  final Color? positiveRestColor = const Color.fromARGB(255, 18, 114, 18);
  final Color? negativeRestColor = const Color.fromARGB(255, 236, 9, 9);
  dynamic turnData;
  int turnNumber              = 0;
  bool canPlay                = false;


  _CommandPageState({required this.init_data, required this.socket, required this.subscription}) : super() {
    init();
  }

  void _tryReconnect() async {
    try {
      print("trying to reconnect to the server");
      socket = await Socket.connect(socket.address, socket.remotePort);
      subscription = socket.listen((event)=>{});

      init_subscription();

      print("sending reconnection message");
      socket.add(utf8.encode("_AFC_:player_name:\"${widget.player_name}\"\n"));
      socket.flush();

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


  void init_subscription() async {
    //Add exception handling for the connection
    subscription.onError((error) => showDialog(
      context: context,
      builder: (BuildContext context) =>
        AlertDialog(
          title: const Text('Error'),
          content: Text(error.toString()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Ok'),
            ),
            TextButton(
              onPressed: () {
                _tryReconnect();
                Navigator.pop(context, 'OK');
              },
              child: const Text('Try reconnect'),
            ),
          ],
        ),
      )
    );


    subscription.onDone(() => showDialog(
      context: context,
      builder: (BuildContext context) =>
        AlertDialog(
          title: const Text('Done'),
          content: const Text('Connection closed'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, 'Cancel'),
              child: const Text('Ok'),
            ),
            TextButton(
              onPressed: () {
                _tryReconnect();
                Navigator.pop(context, 'OK');
              },
              child: const Text('Try reconnect'),
            ),
          ],
        ),
      )
    );

    //Add a listener function to the socket to process received data
    subscription.onData(listenSocket);
  }

  void init() async {

    total                   = 0;
    canPlay                 = false;
    turnBudget              = init_data['budget'];
    turnNumber              = 1;

    init_subscription();


    //Process initial data to create the list of possible actions
    gameActions = { for (var action in init_data['actions'].map<GameAction>(
            (action) => GameAction(
            id: action['id'],
            name: action['name'],
            cost: num.parse(action['cost']),
            once_per_game: action['once_per_game'] == 'true',
            mandatory: action['mandatory'] == 'true',
            asset_name: action['asset_name'],
            description:  action.containsKey('description')
                        ? action['description']
                        : ''
        )
    ).toList()) action.id : action };
  }

  String currentBuffer = '';
  void listenSocket(dynamic event) {

    var mess = utf8.decode(event, allowMalformed: true);
    print("received: " + mess);

    mess = currentBuffer + mess;
    currentBuffer = "";
    var lines = mess  .split("\n")
                      .where((element) => element.trim().replaceAll('\r', '') != '')
                      .toList();
    if (!mess.endsWith('\n')){
      print("buffered: " + currentBuffer);
      currentBuffer = lines.last;
      lines.removeLast();
    }
    for(var line in lines){
      line = line.trim().replaceAll('\r', '');
      if (line.startsWith("_WATER_")) {
        List<num> data = jsonDecode(line.replaceAll("_WATER_:", '')).cast<num>();
        // print(data);
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
        // print(data);
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
        // print(data);
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
      else if (line.startsWith("_START_TURN_")) {
        var turnData = jsonDecode(line.replaceAll("_START_TURN_:", ''));
        setState(() {
          canPlay = true;
          turnBudget = turnData['budget'];
          turnNumber = turnData['turn'];
        });
      }
    }
  }

  num turnBudget        = 0;
  num total             = 0;
  bool wasteCollection  = false;
  bool drainDredge      = false;
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

  //Process the total cost of the actions taken and returns the corresponding list of ids
  List<String> _processTotal() {
    var takenActions = <String>[];
    total = 0;
    for(var choice in  activated_switches.keys) {
      if (activated_switches[choice]!){
        String id =   group_choices.containsKey(choice)
                    ? group_choices[choice]!
                    : choice;
        takenActions.add(id);
        setState(() {
          total += gameActions[id]!.cost;
        });
      }

    }
    return takenActions;
  }

  //Sends the selected actions to the server (and thus ends the turn)
  void validate() async {
    try {

      canPlay = false;
      var takenActions = _processTotal();
      socket.add(utf8.encode('_AFEOT_:$takenActions\n'));
      await socket.flush();

      //Deleting the actions only available once per game and resetting the others
      for(var id in takenActions) {
        if (gameActions[id]!.once_per_game) {
          gameActions.remove(id);
          activated_switches.remove(id);
          group_choices.remove(id);
        }
      }
      setState((){
        for (var k in activated_switches.keys){
          activated_switches[k] = false;
        }
      });
    }
    catch(exception) {
      canPlay =  true;
      print("erreur pendant l'envoie");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(exception.toString()),
        ),
      );
    }
  }

  //Returns the difference between chosen actions costs and the budget
  num getRest(){
    return turnBudget - total;
  }

  //TODO: refactor those two maps in a map of pairs
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
    var backgroundColors = [Colors.grey[300], Colors.white];
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
          choices.add(Switch(value: activated_switches[first.id]!, onChanged: (value){

                  setState((){
                    activated_switches[first.id] = value;
                    _processTotal();
                  });

                }));
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
                          group_choices[first.id] = value!;
                          _processTotal();
                      }
                    : null
                  ),
                  Text('${action.cost}\$',
                      style: Theme.of(context).textTheme.headline6
                  ),
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

        actions.add(
          Container(
            color:  first.mandatory
                ? Colors.red
                : backgroundColors[i%2],
            child:
            Padding(
                padding: const EdgeInsets.all(3.0),
                child:
                    Container(
              color: backgroundColors[i%2],
              child:
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                    children: [
                      Padding(padding: const EdgeInsets.all(3),
                        child: Text(
                          first.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ),
                      Row(
                        children:
                          choices

                        ,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          first.description,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      )
                    ]
                ),
              ),
            )
        ),
            )
            ,);
      }
      else {
        if (! activated_switches.containsKey(first.id)) {
          activated_switches[first.id] = false;
        }
        var action = group.value.first;
        actions.add(
            Container(
              color: backgroundColors[i%2],
              child:
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(3),
                        child: Text(
                          action.name,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headline4,
                        ),
                      ),
                      Row(
                        children: [
                          Switch(
                              value: activated_switches[first.id]!,
                              onChanged: (value){
                                activated_switches[first.id] = value;
                                _processTotal();
                              }),
                          Text( action.cost > 0
                              ? '${action.cost}\$'
                              : '',
                              style: Theme.of(context).textTheme.headline6),
                          const Spacer(),
                          Image.asset('assets/${action.asset_name}', height: 100, width: 100,
                                      errorBuilder: (_context, obj, stack) => Image.asset('assets/waste-collection.png', height: 100, width: 100),)
                          //Image.asset('assets/drain-dredge.png', height: 100, width: 100,),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          action.description,
                          textAlign: TextAlign.left,
                          style: Theme.of(context).textTheme.headline6,
                        ),
                      )
                    ]
                ),
              ),
            )
        );
      }
      i++;
    }

    _processTotal(); //To get the first total right

    return WillPopScope(
        onWillPop: () async {
      bool willLeave = false;
      // show the confirm dialog
      await showDialog(
          context: context,
          builder: (_) => AlertDialog(
        title: const Text('Êtes-vous sûr de vouloir quitter?'),
        actions: [
          ElevatedButton(
              onPressed: () {
                willLeave = true;
                Navigator.of(context).pop();
              },
              child: const Text('Oui')),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Non'))
        ],
      ));
    return willLeave;
    },
    child:
      Scaffold(

      body:
          DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  '${widget.player_name} \t Tour $turnNumber \t $turnBudget\$',
                  style: Theme.of(context).appBarTheme.titleTextStyle?.apply(
                  ),
                ),
                actions: [
                  Padding(
                      padding: EdgeInsets.only(right: 20.0),
                      child: GestureDetector(
                        onTap: _tryReconnect,
                        child: const Icon(
                          Icons.loop,
                          size: 26.0,
                        ),
                      )
                  )
                ],
                bottom: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.list), text: 'Actions',),
                    Tab(icon: Icon(Icons.show_chart), text: 'Statistiques',),
                  ],
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        Padding(
                          padding:
                          const EdgeInsets.all(8.0),
                          child: ListView(
                            children:
                            [
                              //TODO: change for a flexible layout
                              Column(
                                children: [
                                  Text("Productivité",style: Theme.of(context).textTheme.headline3,),
                                  SizedBox(
                                    height: 100,
                                    child: charts.LineChart(
                                      [
                                        productivity,
                                      ],
                                      animate: true,
                                    ),
                                  ),
                                  const SizedBox(height: 50,),
                                  Text("Pollution",style: Theme.of(context).textTheme.headline3,),
                                  SizedBox(
                                    height: 400,
                                    child: charts.LineChart(
                                    [
                                      solid_pollution,
                                      water_pollution,
                                    ],
                                    animate: true,
                                  )
                                )

                                ],
                              ),
                            ]

                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.lime[50],
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child:
                          Column(
                            children: [
                              // SizedBox(height: 3,),
                              Row(
                                children: [
                                  Text(
                                    'Reste:',
                                    style: Theme.of(context).textTheme.headline4?.apply(
                                        color:  getRest() < 0
                                            ? negativeRestColor
                                            : positiveRestColor
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                      '${getRest()}\$',
                                      style: Theme.of(context).textTheme.headline4?.apply(
                                          color:  getRest() < 0
                                              ? negativeRestColor
                                              : positiveRestColor
                                      )
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        Center(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed:  getRest() >= 0 && canPlay
                                    ? validate
                                    : null,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text('Valider le tour', style: Theme.of(context).textTheme.headline5),
                                ),
                              ),
                            )
                        )
                      ],
                    ),
                  )

                ],
              ),
            ),
          )
      )
    );
  }
}

class LinearData {

  int i;
  num v;

  LinearData(this.i, this.v);

}