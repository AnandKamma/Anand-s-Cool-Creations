import 'package:flutter/material.dart';
import 'package:lock/constonants.dart';
import 'package:provider/provider.dart';
import 'package:lock/components/Todoey_models/task_data1.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

// ignore: must_be_immutable
class AddTaskScreen extends StatefulWidget {
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController taskTitleController = TextEditingController();
  final TextEditingController taskDescriptionController =
      TextEditingController();
  final _auth = FirebaseAuth.instance;
  User? loggedInUser;
  String selectedRecipientUID = "all"; // Stores the UID
  String selectedRecipientName = "All Members"; // Stores the Display Name

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedInUser = user;
        print(loggedInUser!.email);
      }
    } catch (e) {
      debugPrint('Logged-in user: ${loggedInUser!.email}');
    }
  }
  void showRecipientPicker(BuildContext context, TaskData taskData) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        padding: EdgeInsets.only(top: 10), // ✅ Adds spacing for better UI
        height: 150,
        decoration: BoxDecoration(
          color: kTextAndIconColor,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ), // ✅ Rounded top edges for a clean UI
        ),
        child: CupertinoPicker(
          backgroundColor: kTextAndIconColor,
          itemExtent: 40, // Height of each item
          onSelectedItemChanged: (index) {
            String newUID = (index == 0) ? "all" : taskData.houseMembers[index - 1]["uid"]!;
            String newName = (index == 0) ? "All Members" : taskData.houseMembers[index - 1]["name"]!;

            if (newUID != selectedRecipientUID) {
              setState(() {
                selectedRecipientUID = newUID;
                selectedRecipientName = newName;
              });
            }
          },
          children: [
            Center(child: Text("All Members", style: TextStyle(fontSize: 20, fontFamily:'CaveatBrush', color: kAddTaskScreenBkgColor))),
            ...taskData.houseMembers.map((member) => Center(
              child: Text(
                member["name"]!,
                style: TextStyle(fontSize: 18, fontFamily: 'CaveatBrush',color: kAddTaskScreenBkgColor),
              ),
            )),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    taskTitleController.dispose();
    taskDescriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskData>(context, listen: false).fetchHouseMembers();
    });
  }

  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus(); // Dismiss the keyboard on tap outside
      },
      child: SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.only(
            top: 30,
            left: 20,
            right: 20,
            bottom:
                MediaQuery.of(context).viewInsets.bottom, // Adjust for keyboard
          ),
          decoration: BoxDecoration(
            color: kAddTaskScreenBkgColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Add Task',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kAddTaskTextAndIconColor,
                  fontSize: 40,
                  fontFamily: 'CaveatBrush',
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              // Task Title Input
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: taskTitleController,
                  textInputAction: TextInputAction.done,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    hintText: 'Type your task (mandatory)',
                    hintStyle: TextStyle(
                        color: kAddTaskHintTextColor,
                        fontFamily: 'ShadowsIntoLight',
                        fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: kAddTaskTextFieldBkgColor,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: kAddTaskTextFieldBorderColor, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: kAddTaskTextFieldBorderColor, width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
              ),
              // Task Description Input
              Padding(
                padding: EdgeInsets.all(10),
                child: TextField(
                  controller: taskDescriptionController,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.done,
                  maxLines: 1,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: 'Describe it (optional)',
                    hintStyle: TextStyle(
                        color: kAddTaskHintTextColor,
                        fontFamily: 'ShadowsIntoLight',
                        fontWeight: FontWeight.bold),
                    filled: true,
                    fillColor: kAddTaskTextFieldBkgColor,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: kAddTaskTextFieldBorderColor, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: kAddTaskTextFieldBorderColor, width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  'Assign to...',
                  style: TextStyle(
                      color: kAddTaskTextAndIconColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: "CaveatBrush"),
                ),
              ),
              Consumer<TaskData>(
                builder: (context, taskData, child) {
                  if (taskData.houseMembers.isEmpty) {
                    return Center(child: CircularProgressIndicator());
                  }

                  return GestureDetector(
                    onTap: () {
                      showRecipientPicker(context, taskData); // ✅ Opens Cupertino Picker
                    },
                    child:Container(
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                      decoration: BoxDecoration(
                        color: kAddTaskTextFieldBkgColor, // ✅ Matches Input Field background color
                        borderRadius: BorderRadius.all(Radius.circular(20)), // ✅ Rounded corners
                        border: Border.all(
                          color: kAddTaskTextFieldBorderColor, // ✅ Matches Input Field border color
                          width: 1, // ✅ Matches border width
                        ),
                      ),
                      child: Text(
                        selectedRecipientName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: kTextAndIconColor, // ✅ Matches hint text color
                          fontFamily: 'ShadowsIntoLight', // ✅ Matches font style
                          fontWeight: FontWeight.bold, // ✅ Matches font weight
                          fontSize: 18,
                        ),
                      ),
                    )
                    ,
                  );
                },
              ),
              SizedBox(height: 20),
              // Add Button
              Container(
                decoration: BoxDecoration(
                    border: Border.all(
                      color: kAddTaskTextFieldBorderColor, // Outline color
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20)),
                child: TextButton(
                  onPressed: () {
                    FocusScope.of(context)
                        .unfocus(); // Dismiss the keyboard and commit input
                    String newTaskTitle = taskTitleController.text.trim();
                    String newTaskDescription =
                        taskDescriptionController.text.trim();
                    if (newTaskTitle.isNotEmpty) {
                      Provider.of<TaskData>(context, listen: false)
                          .addTaskWithDescription(
                        newTaskTitle,
                        newTaskDescription, // Default to an empty description
                        selectedRecipientName,
                      );
                      Navigator.pop(context);
                    } else {
                      debugPrint('the task was not created');
                      // Show a message or handle empty title case
                      ScaffoldMessenger.of(context,).showSnackBar(
                        SnackBar(
                          content: Text('Task title cannot be empty!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Click to Add!',
                    style: TextStyle(
                        color: kAddTaskTextAndIconColor,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        fontFamily: "CaveatBrush"),
                  ),
                ),
              ),
              SizedBox(
                height: 40,
              )
            ],
          ),
        ),
      ),
    );
  }
}
