import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:lock/components/Todoey_models/task_data1.dart';
import 'package:lock/rough.dart';
import 'package:lock/screens/AdminPage.dart';
import 'package:lock/screens/Announcements.dart';
import 'package:lock/screens/Calibration/CalibrationPage.dart';
import 'package:lock/screens/ContactUs.dart';
import 'package:lock/screens/Home%20Screen.dart';
import 'package:lock/screens/MaintainanceScreen.dart';
import 'package:lock/screens/OpeiningScreen.dart';
import 'package:lock/screens/Registration%20Screen.dart';
import 'package:provider/provider.dart';
import 'screens/Login Screen.dart';
import 'screens/todoey/Todo Home Screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures bindings are initialized before Firebase
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) {
          final taskData = TaskData();
          taskData.fetchTasksFromFirestore(); // Ensure data is fetched on startup
          return taskData;
        }), // TaskData for state management
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: OpeningAnimations.id,
      routes: {
        LoginScreen.id: (context) => LoginScreen(),
        Registrationscreen.id: (context) => Registrationscreen(),
        TaskSscreen.id: (context) => TaskSscreen(),
        HomeScreen.id :(context)=> HomeScreen(),
        AnnouncementScreen.id:(context)=>AnnouncementScreen(),
        ContactUsPage.id:(context)=>ContactUsPage(),
        AdminPage.id:(context)=>AdminPage(),
        MaintainanceScreen.id:(context)=>MaintainanceScreen(),
        Rough.id:(context)=>Rough(),
        OpeningAnimations.id:(context)=>OpeningAnimations(),
        CalibrationPage.id:(context)=>CalibrationPage(),
      },
    );
  }
}
