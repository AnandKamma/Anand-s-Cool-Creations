import 'dart:async';
import 'package:action_slider/action_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:lock/components/LockStateFirestore.dart';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BluetoothServ {
  BluetoothDevice? targetDevice;
  bool isScanning = false; // To indicate scanning status
  late StreamSubscription<List<ScanResult>> scanSubscription;
  StreamSubscription<BluetoothConnectionState>? connectionStateSubscription;
  String? errorMessage; // A variable to hold error messages
  String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
  BluetoothCharacteristic? writableCharacteristic;
  ValueNotifier<bool> isScanningNotifier = ValueNotifier(false);
  ValueNotifier<bool> isConnectedNotifier = ValueNotifier(false);
  ValueNotifier<BluetoothConnectionState> connectionStateNotifier =
      ValueNotifier(BluetoothConnectionState.disconnected);
  ValueNotifier<String?> errorNotifier = ValueNotifier(null);
  ValueNotifier<String?> reconnectionStatusNotifier =
      ValueNotifier(null); // Tracks the reconnection status
  ValueNotifier<BluetoothCharacteristic?> writableCharacteristicNotifier =
      ValueNotifier(null); // Tracks the writable characteristic
  ValueNotifier<String?> commandStatusNotifier =
      ValueNotifier(null); // Tracks the status of the last command sent
  ValueNotifier<bool> isReconnectingSpinnerNotifier = ValueNotifier(false);
  ValueNotifier<bool> isRSSIMonitoringActive =
      ValueNotifier(false); // Default: OFF
  Timer? _rssiTimer; // Store the timer reference

  int? scanRetryCount;

  Future<String?> getUserESP32ID() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("❌ User not logged in.");
      return null;
    }

    try {
      //Query Firestore for the house that the user is a member of
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('houses')
          .where('members', arrayContains: user.uid)
          .limit(1) // Get only the first matched house
          .get();
      if (querySnapshot.docs.isEmpty) return null;
      DocumentSnapshot houseDoc = querySnapshot.docs.first;
      String esp32ID =
          houseDoc['esp32_id']; // Return the ESP32 ID for this house
      print("✅ ESP32 ID Found: $esp32ID");
      return esp32ID; // Return the ESP32 ID for this house
    } catch (e) {
      print("❌ Error fetching ESP32 ID: $e");
      return null;
    }
  }
  //

  void bluetooth() async {
    int scanRetryCount = 0;
    const int scanMaxRetries = 10;

    while (scanRetryCount < scanMaxRetries) {
      String? targetLockID = await getUserESP32ID();
      if (targetLockID == null) {
        print("Error: No ESP32 assigned for this user.");
        return;
      }
      print("✅ Using ESP32 ID: $targetLockID for BLE scanning.");

      try {
        // Ensure no previous scan or subscription is active
        if (isScanning) {
          await FlutterBluePlus.stopScan();
          scanSubscription.cancel();
          isScanning = false;
          isScanningNotifier.value = isScanning;
        }

        // Start a new scan
        isScanning = true;
        isScanningNotifier.value = isScanning;
        print("Starting BLE scan (Attempt ${scanRetryCount + 1})...");
        await FlutterBluePlus.startScan(timeout: Duration(seconds: 4))
            .catchError((error) {
          print("Error starting scan: $error");
        });

        // Listen for scan results
        scanSubscription = FlutterBluePlus.scanResults.listen((results) async {
          for (ScanResult result in results) {
            String deviceName = result.device.name;

            if (deviceName == targetLockID) {
              print('✅ Target device found: $deviceName');
              targetDevice = result.device;

              // Stop scanning and cancel subscription
              await FlutterBluePlus.stopScan();
              await scanSubscription.cancel();
              isScanning = false;
              isScanningNotifier.value = isScanning;

              // Attempt to connect
              try {
                if (result.device.state != BluetoothDeviceState.connected) {
                  print("Connecting to ${result.device.name}...");
                  connectToDevice(targetDevice!);
                } else {
                  print("Device is already connected.");
                }

                // Exit the loop after a successful connection
                scanRetryCount = scanMaxRetries;
              } catch (e) {
                print("Connection failed: $e");
              }

              return; // Exit the listener
            }
          }
        });

        // Increment retry count if the scan completes without finding the target device
        await Future.delayed(Duration(seconds: 4));
        if (isScanning) {
          print("Target device not found. Retrying...");
          scanRetryCount++;
        }
      } catch (e) {
        print("Error in Bluetooth operation: $e");
        scanRetryCount++;
      } finally {
        // Ensure cleanup is properly handled
        if (isScanning) {
          await FlutterBluePlus.stopScan();
          await scanSubscription.cancel();
          isScanning = false;
          isScanningNotifier.value = isScanning;
        }
      }

      // Add a small delay before retrying
      if (scanRetryCount < scanMaxRetries) {
        await Future.delayed(Duration(seconds: 2));
      }
    }
  }

  void resetRetries() {
    print("Resetting retry counter...");
    scanRetryCount = 0; // Reset retry counter
    bluetooth(); //
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      monitorConnectionState(device);
      device.connect(
          autoConnect: true, mtu: null, timeout: Duration(seconds: 10));

      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          if (!isConnectedNotifier.value) {
            // Prevent unnecessary updates
            isConnectedNotifier.value = true;
            print('✅ Connection Established with ${device.name}');
            monitorConnectionState(device);
          }
        } else {
          if (isConnectedNotifier.value) {
            // Prevent unnecessary updates
            isConnectedNotifier.value = false;
            print('🚫 Disconnected from ${device.name}');
          }
        }
      });
    } catch (e) {
      isConnectedNotifier.value = false;
      print('Failed to connect: $e');
    }
  }

  void monitorConnectionState(BluetoothDevice device) {
    connectionStateSubscription?.cancel(); //cancel previous subscriptions
    connectionStateSubscription = device.connectionState.listen((state) {
      connectionStateNotifier.value = state;
      if (state == BluetoothConnectionState.connected) {
        isConnectedNotifier.value = true;
        print('${device.name} is connected.');
        discoverServices(targetDevice!);
      } else if (state == BluetoothConnectionState.disconnected) {
        isConnectedNotifier.value = false;
        print('${device.name} is disconnected.');
        handleDisconnection(device);
      } else if (state == BluetoothConnectionState.connecting) {
        print('${device.name} is attempting to connect.');
      } else if (state == BluetoothConnectionState.disconnecting) {
        print('${device.name} is disconnecting.');
      }
    });
  }

  void setError(String message) {
    errorNotifier.value = message;
    print("Error set: $message");
  }

  void handleDisconnection(BluetoothDevice device) async {
    int retryCount = 0;
    const int maxRetries = 5;
    isReconnectingSpinnerNotifier.value = true;
    reconnectionStatusNotifier.value =
        'Connection lost. Attempting to reconnect...';
//Reconnect Logic
    while (retryCount < maxRetries) {
      try {
        await device.connect(
            autoConnect: true, mtu: null, timeout: Duration(seconds: 10));
        await device.connectionState
            .where((state) => state == BluetoothConnectionState.connected)
            .first;
        reconnectionStatusNotifier.value = 'Reconnected to ${device.name}!';
        print('Reconnected to ${device.name}');
        break;
      } catch (e) {
        retryCount = retryCount + 1;
        reconnectionStatusNotifier.value =
            'Reconnect attempt $retryCount of $maxRetries failed.';
        print('Reconnect attempt failed: $e');
        if (retryCount >= maxRetries) {
          reconnectionStatusNotifier.value =
              'Max retries reached. Could not reconnect.';
          print('Max retries reached. Could not reconnect.');
          errorNotifier.value =
              'Failed to reconnect after $maxRetries attempts.';
          break;
        }
        await Future.delayed(Duration(seconds: 5)); // Retry after a delay
      }
    }
    isReconnectingSpinnerNotifier.value = true;
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    List<BluetoothService> services = await device.discoverServices();
    for (BluetoothService service in services) {
      print("Discovered service: ${service.uuid.toString()}");
      if (service.uuid.toString() == serviceUUID) {
        print("Matched service UUID: $serviceUUID");
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          print("Discovered characteristic: ${characteristic.uuid.toString()}");
          if (characteristic.uuid.toString() == characteristicUUID) {
            print("Found writable characteristic!");
            writableCharacteristicNotifier.value = characteristic;
            writableCharacteristic = characteristic;
          } else {
            print('Error in Discovering Services');
          }
        }
      }
    }
  }

  Future<bool> isUserAuthorized() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('houses')
        .where('members', arrayContains: user.uid)
        .limit(1)
        .get();

    return querySnapshot.docs.isNotEmpty; // Returns true if user is authorized
  }

  Future<void> sendCommand(String command) async {
    if (writableCharacteristic != null) {
      try {
        await writableCharacteristic!
            .write(utf8.encode(command), withoutResponse: false);
        commandStatusNotifier.value =
            "Command sent: $command"; // Update notifier with success message
        print("Command sent: $command");
      } catch (e) {
        commandStatusNotifier.value =
            "Failed to send command: $command"; // Update notifier with error message
        print("Failed to send command: $command - Error: $e");
      }
    } else {
      commandStatusNotifier.value = "Writable characteristic not found!";
      print("Writable characteristic not found!");
    }
  }

  void dispose() {
    // Cancel connection state subscription
    connectionStateSubscription?.cancel();
    connectionStateSubscription = null;

    // Cancel scan subscription
    scanSubscription.cancel();

    // Disconnect the target device
    targetDevice?.disconnect();

    // Reset notifiers
    isScanningNotifier.value = false;
    connectionStateNotifier.value = BluetoothConnectionState.disconnected;
    writableCharacteristicNotifier.value = null;
    commandStatusNotifier.value = null;
    errorNotifier.value = null;

    print("BluetoothService resources disposed.");
  }

  void testReadRssi(
      BluetoothDevice device,
      ActionSliderController sliderController,
      Function(ActionSliderController) handleSuccess) async {
    try {
      int rssi = await device.readRssi();
      print("🔍 RSSI Test: $rssi dBm");
      if (!isConnectedNotifier.value) {
        print("⚠️ Device not connected. Cannot check lock state.");
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? houseID = prefs.getString('houseID');
      if (houseID == null) {
        print("❌ No houseID found. Cannot fetch lock state.");
        return;
      }
      LockStateDatabase lockStateDatabase = LockStateDatabase();
      Map<String, dynamic>? lockState =
          await lockStateDatabase.fetchLockState(houseID);
      if (lockState == null) {
        print("Could not fetch lock state.");
        return;
      }
      print("🔍 Fetched lock state: $lockState");
      if (!lockState.containsKey('isLocked')) {
        print("❌ Lock state data is missing 'isLocked' key.");
        return;
      }

      bool isCurrentlyLocked =
          lockState['isLocked'] ?? true; // Default to locked if null

      if (rssi > -90) {
        print("$rssi > -90, checking lock state...");
        if (isCurrentlyLocked) {
          print("Auto-triggering slider to unlock...");
          handleSuccess(sliderController);
        } else {
          print("Already unlocked. No action needed.");
        }
      } else if (rssi < -90) {
        print("$rssi < -90, checking lock state...");
        if (!isCurrentlyLocked) {
          print("Auto-triggering slider to lock...");
          handleSuccess(sliderController);
        } else {
          print("Already locked. No action needed.");
        }
      }
    } catch (e) {
      print("RSSI Read Failed: $e");
    }
  }

  void toggleRSSIMonitoring(ActionSliderController sliderController,
      Function(ActionSliderController) handleSuccess) async {
    bool newState = !isRSSIMonitoringActive.value;
    isRSSIMonitoringActive.value = newState;

    // ✅ Fetch houseID from SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? houseID = prefs.getString('houseID');

    if (houseID == null) {
      print("❌ No houseID found. Cannot update RSSI state.");
      return;
    }

    // ✅ Update Firestore state
    LockStateDatabase lockStateDatabase = LockStateDatabase();
    lockStateDatabase.updateRSSIMonitoringState(houseID, newState);

    // ✅ Use newState directly instead of re-toggling
    if (newState) {
      print("✅ Starting RSSI Monitoring...");
      startMonitoringRSSI(sliderController, handleSuccess);
    } else {
      print("🛑 Stopping RSSI Monitoring...");
      _rssiTimer?.cancel(); // ✅ Stop timer immediately
      _rssiTimer = null;
    }
  }

  void startMonitoringRSSI(ActionSliderController sliderController,
      Function(ActionSliderController) handleSuccess) {
    if (_rssiTimer != null) return; // ✅ Prevent multiple timers
    _rssiTimer?.cancel();
    _rssiTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      if (!isRSSIMonitoringActive.value) {
        print("🚫 RSSI Monitoring Disabled.");
        timer.cancel();
        _rssiTimer = null;
        return;
      }
      if (targetDevice == null || !isConnectedNotifier.value) {
        print("Device not connected. Stopping RSSI monitoring.");
        timer.cancel();
        _rssiTimer = null;
        return;
      }
      try {
        int rssi = await targetDevice!.readRssi();
        print("Live RSSI: $rssi dBm");
        testReadRssi(targetDevice!, sliderController, handleSuccess);
      } catch (e) {
        print(" Error reading RSSI: $e");
        timer.cancel();
        _rssiTimer = null;
      }
    });
  }

  void handleTap(bool isConnected, ActionSliderController sliderController,
      void Function(ActionSliderController) handleSuccess) {
    if (isConnected) {
      toggleRSSIMonitoring(sliderController, handleSuccess);
    } else {
      print('🔄 Connection lost! Trying to reconnect...');
      if (targetDevice == null) {
        resetRetries();
      } else {
        print("⚠️ No target device. Scan and connect first.");
      }
    }
  }

  Future<List<String>> getAllESP32IDs() async {
    try {
      QuerySnapshot querySnapshot =
      await FirebaseFirestore.instance.collection('houses').get();

      List<String> esp32IDs = querySnapshot.docs
          .map((doc) => doc['esp32_id'].toString()) // Extract ESP32 ID from each house
          .toList();

      print("✅ Retrieved all ESP32 IDs: $esp32IDs");
      return esp32IDs;
    } catch (e) {
      print("❌ Error fetching all ESP32 IDs: $e");
      return [];
    }
  }

}
