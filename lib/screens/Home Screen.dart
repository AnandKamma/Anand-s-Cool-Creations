import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lock/components/BluetoothService.dart';
import 'package:lock/components/Todoey_models/task_data1.dart';
import 'package:lock/components/Todoey_models/task_list.dart';
import 'package:lock/constonants.dart';
import 'package:lock/screens/Announcements.dart';
import 'package:lock/screens/settings_page.dart';
import 'package:lock/screens/todoey/Todo%20Home%20Screen.dart';
import 'package:action_slider/action_slider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:water_drop_nav_bar/water_drop_nav_bar.dart';
import 'package:lock/components/LockStateFirestore.dart';
import 'package:lock/screens/Login Screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  static const String id = 'home_screen';
  HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late BluetoothServ bluetoothServ = BluetoothServ();
  late AnimationController animationController;
  late Animation<Color?> colorAnimation;
  final ActionSliderController sliderController = ActionSliderController();
  bool isUnlocked = false;
  int _currentIndex = 0; //for my bottom navigation bar
  String? houseID; // Store houseID

  final ScrollController _scrollController = ScrollController();
  ValueNotifier<bool> isReconnectingSpinnerNotifier = ValueNotifier(false);
  LockStateDatabase lockStateDatabase = LockStateDatabase();
  TaskSscreen taskSscreen = TaskSscreen();
  TaskData taskData = TaskData();

  Future getPermissions() async {
    try {
      await Permission.bluetooth.request();
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize animation controller and color animation
    getPermissions();
    bluetoothServ.bluetooth();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Future.delayed(Duration.zero, () async {
        if (bluetoothServ.targetDevice != null) {
          bluetoothServ.monitorConnectionState(bluetoothServ.targetDevice!);
        } else {
          print("Target device not set. Scan and connect first.");
        }

        // ✅ Fetch the stored RSSI state from Firestore instead of auto-toggling
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? houseID = prefs.getString('houseID');

        if (houseID != null) {
          bool storedRSSIState =
              await lockStateDatabase.getStoredRSSIMonitoringState(houseID);
          bluetoothServ.isRSSIMonitoringActive.value =
              storedRSSIState; // ✅ Set the stored state
          print(
              "📡 Restored RSSI Monitoring state: ${storedRSSIState ? 'ON' : 'OFF'}");
        } else {
          print("⚠️ No houseID found. Defaulting RSSI Monitoring to OFF.");
          bluetoothServ.isRSSIMonitoringActive.value = false;
        }

        // ✅ Only listen for connection changes, don't auto-toggle RSSI
        bluetoothServ.isConnectedNotifier.addListener(() {
          if (bluetoothServ.isConnectedNotifier.value) {
            print(
                "✅ Device Connected. RSSI Monitoring remains: ${bluetoothServ.isRSSIMonitoringActive.value ? 'ON' : 'OFF'}");
          }
        });

        _initializeLockState();
        _loadHouseID();
        await Provider.of<TaskData>(context, listen: false).initializeHouseID();
        Provider.of<TaskData>(context, listen: false).fetchTasksFromFirestore();

        animationController =
            AnimationController(duration: Duration(seconds: 1), vsync: this);
        colorAnimation = ColorTween(
          begin: Colors.grey.shade100,
          end: Colors.lightGreen,
        ).animate(animationController);

        taskData.fetchTasksFromFirestore();
      });
    });
  }

  @override
  void dispose() {
    animationController.dispose();
    BluetoothServ bluetoothServ = BluetoothServ();
    bluetoothServ.dispose();
    super.dispose();
  }

  void startColorAnimation() {
    animationController.forward(from: 0);
  }

  void handleSuccess(ActionSliderController controller) async {
    startColorAnimation();
    try {
      final command = isUnlocked ? "LOCK" : "UNLOCK";
      if (bluetoothServ != null &&
          bluetoothServ.writableCharacteristic != null) {
        await bluetoothServ.sendCommand(command);
        print("$command sent to ESP32 successfully.");
      } else {
        print("Writable characteristic not found. Command not sent.");
      }
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? houseID = prefs.getString('houseID');

      if (houseID == null) {
        print("❌ Error: No houseID found. Cannot update Firestore.");
        return;
      }
      // Update state in Firestore
      await lockStateDatabase.updateLockState(houseID, !isUnlocked);
      await lockStateDatabase.addLockEventLog(houseID, !isUnlocked);

      if (mounted) {
        setState(() {
          isUnlocked = !isUnlocked;
          print(isUnlocked ? 'State: UNLOCK' : 'State: LOCK'); // lo
          showBottomWidget(); // ck/unlocked
        });
      }
      controller.success();
    } catch (e) {
      print(
          "Failed to send command to ESP32/Firestore: $e"); // Handle errors (e.g., Bluetooth or Firestore issues)
      controller.reset();
    }

    // Reset the success state after 1 second
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          controller.reset(); // Reset to normal state
        });
      }
    });
  }

  void showBottomWidget() {
    showModalBottomSheet(
        context: context,
        backgroundColor: isUnlocked ? Colors.green : Colors.red,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(50))),
        builder: (context) {
          return Container(
            height: 150,
            child: Center(
              child: Text(
                isUnlocked ? 'Unlocked' : 'Locked',
                style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          );
        });
    Future.delayed(Duration(milliseconds: 500), () {
      Navigator.pop(context);
    });
  }

  void _initializeLockState() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? houseID = prefs.getString('houseID');

      if (houseID == null) {
        print("❌ Error: No houseID found. Cannot update Firestore.");
        return;
      }
      bool? lockState = await lockStateDatabase.initializeLockState(houseID);
      if (lockState != null) {
        setState(() {
          isUnlocked = lockState;
        });
        print("Lock state initialized: ${isUnlocked ? 'Unlocked' : 'Locked'}");
      } else {
        print("❌ Error: Failed to fetch lock state.");
      }
    } catch (e) {
      print("Error initializing lock state: $e");
    }
  }

  void handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
          builder: (context) => LoginScreen()), // Redirect to Login
      (route) => false, // Clears all previous routes (including HomeScreen)
    );
  }

  Future<void> _loadHouseID() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      houseID = prefs.getString('houseID'); // Get stored houseID
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;//Screen Hieght
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) {
          handleLogout(); // Clears HomeScreen when user tries to go back
        }
      },
      child: Scaffold(
        bottomNavigationBar: Container(
          decoration: kContainerNeumorphim,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: WaterDropNavBar(
                backgroundColor: kBottomNavBarBkgColor,
                iconSize: 30,
                waterDropColor: kBottomNavBarWaterDropColor,
                barItems: [
                  BarItem(
                      filledIcon: FontAwesomeIcons.house,
                      outlinedIcon: Icons.home_outlined),
                  BarItem(
                      filledIcon: FontAwesomeIcons.solidMessage,
                      outlinedIcon: Icons.messenger_outline_rounded),
                  BarItem(
                      filledIcon: FontAwesomeIcons.solidHeart,
                      outlinedIcon: Icons.favorite_border_outlined)
                ],
                selectedIndex: _currentIndex,
                onItemSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                }),
          ),
        ),
        backgroundColor: kHomeScreenBkgColor,
        body: IndexedStack(
          index: _currentIndex,
          children: [
            Stack(children: [
              ListView(
                controller: _scrollController,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 20.0),
                    child: GestureDetector(
                      onDoubleTap: () {
                        Navigator.pushNamed(context, TaskSscreen.id);
                      },
                      child: Container(
                        height: screenHeight*0.4,
                        width: double.infinity,
                        decoration: kContainerNeumorphim,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Consumer<TaskData>(
                            builder: (context, taskData, child) {
                              if (taskData.taskcount == 0) {
                                return Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      kBumbleBeeLogo,
                                      size: screenHeight*0.22,
                                      color: kTextAndIconColor,
                                    ),
                                    Text(
                                      'Double Tap to plan!',
                                      style: TextStyle(
                                          color: kTextAndIconColor,
                                          fontFamily:
                                              kFeatureContainerFontFamily),
                                    )
                                  ],
                                );
                              } else {
                                return TasksList(hideDetails: true);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    child: Container(
                      decoration: kContainerNeumorphim,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: bluetoothServ.isConnectedNotifier,
                        builder: (context, isConnected, child) {
                          if (!isConnected) {
                            return SizedBox(
                              height: screenHeight*0.1,
                              child: Center(
                                child: Text(
                                  "Lost Connection",
                                  style: TextStyle(
                                      color: kTextAndIconColor,
                                      fontSize: 20,
                                      fontFamily: kHomeScreenPrimaryFontFamily,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }
                          return child!;
                        },
                        child: ActionSlider.custom(
                          controller: sliderController,
                          sliderBehavior: SliderBehavior.stretch,
                          key: ValueKey('lockSlider'),
                          outerBackgroundBuilder: (context, state, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    FontAwesomeIcons.chevronRight,
                                    color: kCustomActionSliderLeftArrowColor,
                                  ),
                                  Icon(
                                    FontAwesomeIcons.chevronRight,
                                    color: kCustomActionSliderMiddleArrowColor,
                                  ),
                                  Icon(
                                    FontAwesomeIcons.chevronRight,
                                    color: kCustomActionSliderRightArrowColor,
                                  ),
                                ],
                              ),
                            );
                          },
                          backgroundBuilder: (context, state, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10.0),
                                child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: Icon(
                                      isUnlocked
                                          ? FontAwesomeIcons.lock
                                          : FontAwesomeIcons.unlock,
                                      size: 35,
                                      color: kTextAndIconColor,
                                    )),
                              ),
                            );
                          },
                          foregroundBuilder: (context, state, child) {
                            return Container(
                              decoration: BoxDecoration(
                                color: kTextAndIconColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isUnlocked
                                    ? FontAwesomeIcons.unlock
                                    : FontAwesomeIcons.lock,
                                size: 35,
                                color: kCustomActionSliderLeftIconColor,
                              ),
                            );
                          },
                          toggleWidth: 60,
                          toggleMargin: EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          height: screenHeight*0.13,
                          slideAnimationDuration: Duration(milliseconds: 500),
                          action: handleSuccess,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: FutureBuilder<Map<String, Timestamp?>>(
                              future: houseID == null
                                  ? Future.value({
                                      'firstUnlocked': null,
                                      'lastLocked': null
                                    }) // Handle null case safely
                                  : LockStateDatabase()
                                      .fetchFirstUnlockedAndLastLockedTimes(
                                          houseID ?? ''),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // Show a loading indicator while the data is being fetched
                                  return Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Container(
                                      decoration: kContainerNeumorphim,
                                      height: screenHeight*0.16,
                                      child: Center(
                                        child: kCircularProgressIndicator,
                                      ),
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  // Show an error message if something goes wrong
                                  return Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Container(
                                      decoration: kContainerNeumorphim,
                                      height: screenHeight*0.16,
                                      child: Center(
                                        child: Text(
                                          'Error',
                                          style: TextStyle(
                                            color: kTextAndIconColor,
                                            fontSize: 18,
                                            fontFamily:
                                                kHomeScreenPrimaryFontFamily,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (snapshot.hasData &&
                                    snapshot.data != null) {
                                  // Extract the timestamps from the snapshot
                                  final data = snapshot.data!;
                                  final firstUnlockedTimestamp =
                                      data['firstUnlocked'];

                                  // Safely convert the timestamp to DateTime
                                  final firstOpenedTime =
                                      firstUnlockedTimestamp?.toDate();

                                  // Format the time as hour:minute, with null-safe fallback
                                  final firstOpenedTimeStr = firstOpenedTime !=
                                          null
                                      ? '${firstOpenedTime.hour}:${firstOpenedTime.minute.toString().padLeft(2, '0')}'
                                      : 'N/A'; // Display 'N/A' if no data

                                  return Padding(
                                    padding: EdgeInsets.only(right: 10),
                                    child: Container(
                                      decoration: kContainerNeumorphim,
                                      height: screenHeight*0.16,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            'First Unlocked',
                                            style: TextStyle(
                                              color: kTextAndIconColor,
                                              fontFamily:
                                                  kHomeScreenPrimaryFontFamily,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                          Text(
                                            firstOpenedTimeStr,
                                            style: TextStyle(
                                              color: kTextAndIconColor,
                                              fontSize: 45,
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  // Handle the case where no data exists
                                  return Container(
                                    decoration: kContainerNeumorphim,
                                    height: screenHeight*0.16,
                                    child: Center(
                                      child: Text(
                                        'No Data',
                                        style: TextStyle(
                                            fontFamily:
                                                kHomeScreenPrimaryFontFamily,
                                            color: kTextAndIconColor,
                                            fontSize: 18),
                                      ),
                                    ),
                                  );
                                }
                              }),
                        ),
                        Expanded(
                          child: FutureBuilder<Map<String, Timestamp?>>(
                              future: LockStateDatabase()
                                  .fetchFirstUnlockedAndLastLockedTimes(
                                      houseID ?? ''),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  // Show a loading indicator while the data is being fetched
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: Container(
                                      decoration: kContainerNeumorphim,
                                      height: screenHeight*0.16,
                                      child: Center(
                                        child: kCircularProgressIndicator,
                                      ),
                                    ),
                                  );
                                } else if (snapshot.hasError) {
                                  // Show an error message if something goes wrong
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: Container(
                                      decoration: kContainerNeumorphim,
                                      height: screenHeight*0.16,
                                      child: Center(
                                        child: Text(
                                          'Error',
                                          style: TextStyle(
                                              fontFamily:
                                                  kHomeScreenPrimaryFontFamily,
                                              color: kTextAndIconColor,
                                              fontSize: 18),
                                        ),
                                      ),
                                    ),
                                  );
                                } else if (snapshot.hasData &&
                                    snapshot.data != null) {
                                  // Extract the timestamps from the snapshot
                                  final data = snapshot.data!;
                                  final lastLockedTimestamp =
                                      data['lastLocked'];

                                  // Safely convert the timestamp to DateTime
                                  final lastLockedTime =
                                      lastLockedTimestamp?.toDate();

                                  // Format the time as hour:minute, with null-safe fallback
                                  final lastLockedTimeStr = lastLockedTime !=
                                          null
                                      ? '${lastLockedTime.hour}:${lastLockedTime.minute.toString().padLeft(2, '0')}'
                                      : 'N/A'; // Display 'N/A' if no data

                                  return Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: Container(
                                      decoration: kContainerNeumorphim,
                                      height: screenHeight*0.16,
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          Text(
                                            'Last Locked',
                                            style: TextStyle(
                                                color: kTextAndIconColor,
                                                fontFamily:
                                                    kHomeScreenPrimaryFontFamily,
                                                fontStyle: FontStyle.italic),
                                          ),
                                          Text(
                                            lastLockedTimeStr,
                                            style: TextStyle(
                                                color: kTextAndIconColor,
                                                fontSize: 45),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                } else {
                                  // Handle the case where no data exists
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: Container(
                                      decoration: kContainerNeumorphim,
                                      height: screenHeight*0.16,
                                      child: Center(
                                        child: Text(
                                          'No Data',
                                          style: TextStyle(
                                              fontFamily:
                                                  kHomeScreenPrimaryFontFamily,
                                              color: kTextAndIconColor,
                                              fontSize: 18),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              }),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 15.0, horizontal: 20),
                    child: ValueListenableBuilder(
                      valueListenable: bluetoothServ.isConnectedNotifier,
                      builder: (context, isConnected, child) {
                        return GestureDetector(
                          onTapDown: (_) {
                            print(
                                "🔄 Redo button tapped!"); // ✅ Debug statement
                            bluetoothServ.handleTap(
                                isConnected, sliderController, handleSuccess);
                          },
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color:
                                  kFeatureContainerBkgColor, // Active vs Disabled color
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: kContainerNeumorphim.boxShadow,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: ValueListenableBuilder(
                                valueListenable:
                                    bluetoothServ.isRSSIMonitoringActive,
                                builder: (context, isActive, child) {
                                  return isConnected
                                      ? Icon(
                                          isActive
                                              ? FontAwesomeIcons.signal
                                              : FontAwesomeIcons
                                                  .timesCircle, // Change icon dynamically
                                          color: isActive
                                              ? Colors.green
                                              : Colors
                                                  .red, // Change color dynamically
                                        )
                                      : Icon(
                                          FontAwesomeIcons
                                              .redo, // Retry icon when disconnected
                                          color: Colors.white,
                                          size: 30,
                                        ); // Show retry icon when disconnected
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              ValueListenableBuilder(
                  valueListenable: isReconnectingSpinnerNotifier,
                  builder: (context, isReconnecting, child) {
                    if (isReconnecting) {
                      return Container(
                        child: Center(child: kCircularProgressIndicator),
                      );
                    }
                    return SizedBox.shrink();
                  }),
              SizedBox(
                height: 30,
              )
            ]),
            AnnouncementScreen(),
            if (houseID != null)
              SettingsPage(houseID: houseID ?? "")
            else
              Center(child: CircularProgressIndicator())
          ],
        ),
      ),
    );
  }
}
