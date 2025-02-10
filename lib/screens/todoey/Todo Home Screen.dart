import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lock/components/Todoey_models/task_data1.dart';
import 'package:lock/components/Todoey_models/task_list.dart';
import 'package:lock/constonants.dart';
import 'package:provider/provider.dart';
import 'package:lock/screens/todoey/add_tasks_screen.dart';
import 'package:lock/components/Todoey_models/custom fab.dart';
import 'package:lock/components/Animations.dart';


class TaskSscreen extends StatefulWidget {
  static const String id='tasks_screen';
  const TaskSscreen({super.key});

  @override
  State<TaskSscreen> createState() => _TaskSscreenState();
}

class _TaskSscreenState extends State<TaskSscreen> {
  @override
  void initState() {
    Provider.of<TaskData>(context, listen: false).fetchTasksFromFirestore();
    Provider.of<TaskData>(context, listen: false).initializeHouseID();
    super.initState();
  }


  Widget buildbottomSheet(BuildContext context) {
    return AddTaskScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: CustomFloatingActionButton(onPressed: (){
        showModalBottomSheet(context: context, builder: buildbottomSheet, isScrollControlled: true);}),
      backgroundColor: kTodoHomeScreenBkgColor,
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        
          Container(
            padding: EdgeInsets.only(top:0, left: 30, right: 30, bottom: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap:(){
                    Navigator.pop(context);
                  }
                    ,child: Icon(FontAwesomeIcons.arrowLeft,color: kTodoTextAndIconColor,)),
                Container(
              height: 134,
                  child: RotateWords(
                    label1: 'Plan',
                    label2: 'Execute',
                    label3: 'Repeat',
                  ),
                )
                ,
                SizedBox(
                  height: 10,
                ),
                Text(
                  '${Provider.of<TaskData>(context).taskcount} Tasks',
                  style: TextStyle(color: kTodoTaskCountTextColor, fontSize: 20,fontFamily: 'CaveatBrush'),
                ),
              ],
            ),
          ),
          Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: kTodoHomeScreenBkgColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: TasksList(hideDetails:false),
              ))
        ]),
      ),
    );
  }
}
