import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HouseService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  /// ✅ Update User's House ID in Firestore
  Future<void> updateUserHouseID(String userId, String houseID) async {
    try {
      await firestore.collection('users').doc(userId).update({
        'houseID': houseID,
      });
      print("✅ HouseID updated successfully for user: $userId");
    } catch (error) {
      print("❌ Error updating HouseID: $error");
    }
  }

  /// ✅ Admin: Register New House
  Future<void> registerAdminHouse(
      String userId, String houseID, String esp32ID) async {
    try {
      await firestore.runTransaction((transaction) async {
        DocumentReference houseRef = firestore.collection('houses').doc(houseID);
        DocumentSnapshot houseSnapshot = await transaction.get(houseRef);

        if (houseSnapshot.exists) {
          throw Exception("❌ House ID already exists. Choose a different one.");
        }

        transaction.set(houseRef, {
          'esp32_id': esp32ID,
          'admin_uid': userId,
          'members': [userId], // Admin is first member
          'lock_status': {
            'isUnlocked': false,
            'isLocked': true,
            'timestamp': FieldValue.serverTimestamp(),
          },
        });
      });

      // ✅ Update user's Firestore document with houseID
      await updateUserHouseID(userId, houseID);

      // ✅ Store House ID Locally
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('houseID', houseID);

      print("✅ House Registered Successfully: $houseID");
    } catch (e) {
      print("❌ Error registering house: $e");
      throw e;
    }
  }

  /// ✅ Member: Join Existing House
}
