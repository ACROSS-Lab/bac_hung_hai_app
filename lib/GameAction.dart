class GameAction {

  final String id;
  final String name;
  final num cost;
  final bool once_per_game;
  final bool mandatory;
  final String asset_name;
        String description;

  GameAction({required this.id,
    required this.name,
    required this.cost,
    required this.once_per_game,
    required this.mandatory,
    required this.asset_name,
    required this.description
    }){
      this.description = this.description.replaceAll('@n@', '\n');
  }


}