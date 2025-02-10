// ignore_for_file: must_be_immutable

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:lock/constonants.dart';
import 'package:lock/components/Todoey_models/task_data1.dart';

class TaskTile extends StatelessWidget {
  String loggedinUser = FirebaseAuth.instance.currentUser?.email ?? 'Guest';
  final bool isChecked;
  final String? taskTitle;
  final String? taskDescription;
  final String? addedBy;
  final DateTime? timestamp;
  final bool hideDetails;
  final ValueChanged<bool?>? checkboxCallback;
  final GestureLongPressCallback? longPressCallback;

  TaskTile(
      {this.isChecked = false,
      this.taskTitle,
      this.taskDescription,
      this.checkboxCallback,
      this.longPressCallback,
      this.addedBy,
      this.timestamp,
      this.hideDetails = false,
      super.key});

  Color getRandomColor() {
    List<Color> colors = [
      kTaskTileBkgColor,
    ];
    Random random = Random();
    return colors[random.nextInt(colors.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Column(
        children: [
          if (!hideDetails)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FutureBuilder<String>(
                  future: TaskData().getUserName(
                      addedBy ?? ""), // ✅ Fetch name from Firestore
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Text(
                        "Loading...",
                        style: TextStyle(
                          color: kTaskTileUserTextandTimeColor,
                          fontSize: 10,
                        ),
                      );
                    }
                    return Text(
                      snapshot.data ??
                          addedBy ??
                          "Unknown User", // ✅ Show name or fallback to email
                      style: TextStyle(
                        color: kTaskTileUserTextandTimeColor,
                        fontSize: 10,
                      ),
                    );
                  },
                ),
                Text(
                  timestamp != null
                      ? DateFormat('hh:mm a').format(timestamp!)
                      : '',
                  style: TextStyle(
                      color: kTaskTileUserTextandTimeColor, fontSize: 10),
                )
              ],
            ),
          SizedBox(
            height: 5,
          ),
          Container(
            decoration: BoxDecoration(
              color: getRandomColor(),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Material(
              borderRadius: BorderRadius.circular(20),
              color: getRandomColor(),
              elevation: 0,
              child: ListTile(
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    taskTitle ?? 'no task',
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 16,
                        color: kTaskTileTaskTextColor,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'CaveatBrush',
                        decoration:
                            isChecked ? TextDecoration.lineThrough : null),
                  ),
                ),
                subtitle:
                    (taskDescription != null && taskDescription!.isNotEmpty)
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              taskDescription ?? "",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontFamily: 'CaveatBrush',
                                  color: kTaskTileDescriptionTextColor),
                            ),
                          )
                        : null,
                trailing: GestureDetector(
                  onTap: () {
                    checkboxCallback!(!isChecked); // Toggle the state
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 300), // Animation duration
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChecked
                          ? Colors.black
                          : Colors.grey[300], // Color changes smoothly
                      border: Border.all(
                        color: isChecked ? Colors.black : Colors.grey,
                        width: 2,
                      ),
                    ),
                    child: isChecked
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                onLongPress: longPressCallback,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
