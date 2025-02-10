import 'package:cloud_firestore/cloud_firestore.dart';

class LockStateDatabase {

  Future<Map<String, dynamic>?> fetchLockState(String houseID) async {
    try {
      DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
          .collection('houses')
          .doc(houseID)
          .get();

      if (!docSnapshot.exists) {
        print("❌ No document found for houseID: $houseID");
        return null;
      }

      var data = docSnapshot.data() as Map<String, dynamic>?;

      if (data == null || !data.containsKey('lock_status')) {
        print("⚠️ Lock state missing 'lock_status' key. Returning null.");
        return null;
      }

      var lockStatus = data['lock_status'];

      if (lockStatus is! Map<String, dynamic>) {
        print("❌ Error: 'lock_status' is not a Map<String, dynamic>. Returning null.");
        return null;
      }

      print("✅ Lock state fetched successfully: $lockStatus");
      return lockStatus;
    } catch (e) {
      print("❌ Error fetching lock state: $e");
      return null; // Explicitly return null on error
    }
  }

  Future<void> updateLockState(String houseID, bool isUnlocked) async {
    try {
      await FirebaseFirestore.instance.collection('houses').doc(houseID).set({
        'lock_status': {
          'isUnlocked': isUnlocked,
          'isLocked': !isUnlocked,
          'timestamp': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      print("✅ Lock state updated successfully: isUnlocked=$isUnlocked");
    } catch (e) {
      print("❌ Error updating lock state: $e");
    }
  }


  Future<void> addLockEventLog(String houseID, bool isUnlocked) async {
    try {
      await FirebaseFirestore.instance
          .collection('houses')
          .doc(houseID) // ✅ Store logs inside the correct house
          .collection('Logs') // ✅ Store each lock event inside the Logs subcollection
          .add({ // ✅ Each event gets a unique auto-generated ID
        'isUnlocked': isUnlocked,
        'timestamp': FieldValue.serverTimestamp(),
      });

      print("✅ Lock event recorded for $houseID: isUnlocked = $isUnlocked");
    } catch (e) {
      print('❌ Error adding lock event log: $e');
    }
  }


  // Real-time listener for lock state changes

  Stream<Map<String, dynamic>?> lockStateStream(String houseID) {
    return FirebaseFirestore.instance
        .collection('houses')
        .doc(houseID) // ✅ Listen to the correct house
        .snapshots()
        .map((docSnapshot) {
      if (!docSnapshot.exists) {
        print("❌ No document found for houseID: $houseID");
        return null;
      }

      var data = docSnapshot.data();
      if (data == null || !data.containsKey('lock_status')) {
        print("⚠️ Lock state missing 'lock_status' key. Returning null.");
        return null;
      }

      var lockStatus = data['lock_status'];

      if (lockStatus is! Map<String, dynamic>) {
        print("❌ Error: 'lock_status' is not a Map<String, dynamic>. Returning null.");
        return null;
      }

      print("✅ Live Lock State Updated: $lockStatus");
      return lockStatus;
    });
  }


  Future<bool> initializeLockState(String houseID) async {
    try {
      final lockState = await fetchLockState(houseID); // Fetch lock state dynamically

      if (lockState != null) {
        if (lockState.containsKey('isUnlocked') && lockState['isUnlocked'] is bool) {
          print("✅ Lock state initialized: isUnlocked = ${lockState['isUnlocked']}");
          return lockState['isUnlocked'] as bool;
        } else {
          print("⚠️ Lock state missing 'isUnlocked' key or has an invalid type. Defaulting to false.");
        }
      } else {
        print("❌ No lock state found for houseID: $houseID. Defaulting to locked.");
      }

      // Default to locked state (false) if data is missing or invalid
      return false;
    } catch (e) {
      print("❌ Error initializing lock state: $e");
      return false; // Default to locked state on error
    }
  }



// Fetch first unlocked and last locked times for the current day
  Future<Map<String, Timestamp?>> fetchFirstUnlockedAndLastLockedTimes(
      String houseID) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = DateTime(today.year, today.month, today.day, 23, 59, 59, 999);

      final query = FirebaseFirestore.instance
          .collection('houses')
          .doc(houseID)
          .collection('Logs'); // ✅ Store logs directly in "Logs" collection

      // Fetch first unlocked event of the day
      final firstUnlockedQuery = await query
          .where('isUnlocked', isEqualTo: true)
          .where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: false) // ✅ Order after filtering
          .limit(1)
          .get();

      // Fetch last locked event of the day
      final lastLockedQuery = await query
          .where('isUnlocked', isEqualTo: false)
          .where('timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .orderBy('timestamp', descending: true) // ✅ Order after filtering
          .limit(1)
          .get();

      // Extract timestamps safely
      final firstUnlockedTime = firstUnlockedQuery.docs.isNotEmpty &&
          firstUnlockedQuery.docs.first.data().containsKey('timestamp')
          ? firstUnlockedQuery.docs.first['timestamp'] as Timestamp
          : null;

      final lastLockedTime = lastLockedQuery.docs.isNotEmpty &&
          lastLockedQuery.docs.first.data().containsKey('timestamp')
          ? lastLockedQuery.docs.first['timestamp'] as Timestamp
          : null;

      print("✅ First unlocked time: $firstUnlockedTime, Last locked time: $lastLockedTime");

      return {
        'firstUnlocked': firstUnlockedTime,
        'lastLocked': lastLockedTime,
      };
    } catch (e) {
      print('❌ Error fetching first unlocked and last locked times: $e');
      return {
        'firstUnlocked': null,
        'lastLocked': null,
      }; // Always return a non-null map
    }
  }

  /// 🔥 Function to update RSSI Monitoring state in Firestore
  Future<void> updateRSSIMonitoringState(String houseID, bool isActive) async {
    try {
      await FirebaseFirestore.instance.collection("houses").doc(houseID).set({
        'lock_status': {
          'feature': isActive,
          'timestamp': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));

      print("✅ Firestore Updated: RSSI Monitoring is now ${isActive ? 'ON' : 'OFF'}");
    } catch (e) {
      print("❌ Error updating RSSI state: $e");
    }
  }

  /// 🔥 Function to get the stored RSSI Monitoring state from Firestore
  Future<bool> getStoredRSSIMonitoringState(String houseID) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
      await FirebaseFirestore.instance.collection("houses").doc(houseID).get();

      if (snapshot.exists) {
        return snapshot.data()?["lock_status"]?["feature"] ?? false;
      }
    } catch (e) {
      print("❌ Error fetching RSSI state: $e");
    }
    return false; // Default to false if there's an error or no data
  }


}
