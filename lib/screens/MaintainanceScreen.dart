import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:lock/constonants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lock/components/BluetoothService.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lock/components/LockStateFirestore.dart';
import 'package:action_slider/action_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaintainanceScreen extends StatefulWidget {
  static const String id = 'maintainance_screen';
   MaintainanceScreen({super.key});

  @override
  State<MaintainanceScreen> createState() => _MaintainanceScreenState();
}

class _MaintainanceScreenState extends State<MaintainanceScreen> {
  List<String> esp32List = []; // List to store ESP32 IDs
  String selectedESP = ''; // To track the selected ESP32 ID
  BluetoothServ bluetoothServ = BluetoothServ();
  final ActionSliderController sliderController = ActionSliderController();
  bool isUnlocked = false;
  String? houseID; // Store houseID
  LockStateDatabase lockStateDatabase = LockStateDatabase();
  late AnimationController animationController;

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

  void startColorAnimation() {
    animationController.forward(from: 0);
  }

  void showConnectionStatus(bool isConnected) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            isConnected ? "Connected" : "Connection Failed",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Text(
            isConnected
                ? "Successfully connected to $selectedESP."
                : "Failed to connect to $selectedESP. Try again.",
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }


  @override
  void initState() {
    super.initState();
    fetchESPIDs(); // Fetch ESP32 IDs when screen loads
  }

  @override
  void dispose() {
    animationController.dispose();
    bluetoothServ.dispose();
    super.dispose();
  }

  // Function to fetch all ESP32 IDs from Firestore
  void fetchESPIDs() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('houses').get();

    List<String> espIDs = [];

    for (var doc in snapshot.docs) {
      if (doc.data() is Map<String, dynamic> &&
          (doc.data() as Map<String, dynamic>).containsKey('esp32_id')) {
        espIDs.add(doc['esp32_id'].toString()); // Extract ESP32 ID
      }
    }

    setState(() {
      esp32List = espIDs;
      if (esp32List.isNotEmpty) {
        selectedESP = esp32List[0]; // Default to first ESPID
      }
    });

    print("Fetched ESP32 IDs: $esp32List"); // Debugging log
  }

  void showESP32Picker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) {
        return CupertinoActionSheet(
          title:  Text("Select Lock Name"),
          actions: esp32List.map((espID) {
            return CupertinoActionSheetAction(
              onPressed: () {
                setState(() {
                  selectedESP = espID;
                });
                Navigator.pop(context); // Close the picker
              },
              child: Text(
                espID,
                style: TextStyle(color: kTextAndIconColor, fontFamily: 'Lato'),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height; //Screen Hieght

    return Scaffold(
      backgroundColor: kHomeScreenBkgColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: kContainerNeumorphim,
          child: AppBar(
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(12))),
            title: Icon(
              CupertinoIcons.wrench, // Cupertino wrench icon for maintenance
              color: Colors.black,
              size: 28,
            ),
            backgroundColor: kAnnouncementScreenAppBarBkgColor,
          ),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Select the Lock Name',style: TextStyle(fontSize: 20,fontFamily: 'Lato'),),
          // Cupertino Picker
          Padding(
            padding: EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            child: Container(
              decoration: kContainerNeumorphim,
              margin: EdgeInsets.symmetric(horizontal: 10),
              child: esp32List.isNotEmpty
                  ? // Cupertino-style dropdown button
                  CupertinoButton(
                      borderRadius: BorderRadius.circular(10),
                      onPressed: () => showESP32Picker(context),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            textAlign: TextAlign.center,
                            selectedESP,
                            style: TextStyle(
                                fontSize: 20,
                                color: kTextAndIconColor,
                                fontFamily: 'Lato'),
                          ),
                          Icon(
                            CupertinoIcons.chevron_down,
                            color: kTextAndIconColor,
                          ),
                        ],
                      ),
                    )
                  : Center(
                      child:
                          kCircularProgressIndicator), // Show loading indicator
            ),
          ),

          ElevatedButton(
            onPressed: () async {
              if (selectedESP.isNotEmpty) {
                print("Attempting to connect to ESP32: $selectedESP");

                List<String> espIDs = await bluetoothServ.getAllESP32IDs(); // ✅ Fetch all ESP32 IDs.

                if (!espIDs.contains(selectedESP)) {
                  print("⚠️ Selected ESP32 ($selectedESP) is not in the system ($espIDs)");
                  return;
                }
                // ✅ Check if targetDevice is null
                if (bluetoothServ.targetDevice == null) {
                  print("❌ Error: targetDevice is null. Cannot connect.");
                  return;
                }

                // ✅ Call `connectToDevice` without expecting a return value
                bluetoothServ.connectToDevice(bluetoothServ.targetDevice!);

                // ✅ Manually update UI based on Bluetooth connection notifier
                bluetoothServ.isConnectedNotifier.addListener(() {
                  if (bluetoothServ.isConnectedNotifier.value) {
                    print("✅ Successfully connected to $selectedESP");
                    showConnectionStatus(true);
                  } else {
                    print("❌ Failed to connect to $selectedESP");
                    showConnectionStatus(false);
                  }
                });
              } else {
                print("⚠️ No ESP32 selected.");
              }
            },
            child: Text("Connect to ESP32",style: kSettingsElevatedButtonTextStyle,),
            style: ElevatedButton.styleFrom(
              backgroundColor: kContactUsPageElevatedButtonBkgColor,
              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
                      height: screenHeight * 0.1,
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
                  toggleMargin:
                      EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  height: screenHeight * 0.13,
                  slideAnimationDuration: Duration(milliseconds: 500),
                  action: handleSuccess,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
