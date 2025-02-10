
class Tasks{
  final String id;
  final String name;
  final String description;
  bool isDone;
  final DateTime? timestamp;
  final String sender;
  Tasks({
   required this.id,
    required this.name,
    this.description='',
    this.isDone = false,
    this.timestamp,
    required this.sender
  });

  void toggelDone(){
    isDone= !isDone;
  }

}