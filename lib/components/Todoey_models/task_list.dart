import 'package:flutter/material.dart';
import 'task_tile.dart';
import 'package:provider/provider.dart';
import 'package:lock/components/Todoey_models/task_data1.dart';

class TasksList extends StatelessWidget {
   final bool hideDetails;
  const TasksList({
    this.hideDetails=false
    ,super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TaskData>(
      builder: (context, taskData, child) {
        return ListView.builder(
          padding: EdgeInsets.only(top: 16),
          itemCount: taskData.taskcount,
          itemBuilder: (context, index) {
            final task=taskData.tasks[index];
            return TaskTile(
              taskTitle: task.name,
              taskDescription: task.description,
              isChecked: task.isDone,
              addedBy: task.sender,
              timestamp: task.timestamp,
              hideDetails: hideDetails,
              checkboxCallback: (bool? newValue) {
                taskData.updateTask(task);
              },
              longPressCallback: (){
                taskData.deleteTask(task);
              },);
          },
        );
      },
    );
  }
}
