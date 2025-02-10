import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Fetch members list (real-time updates)
  Stream<DocumentSnapshot> getMembersStream(String houseID) {
    return _firestore.collection('houses').doc(houseID).snapshots();
  }

  // ✅ Add a member by email
  Future<String> addMember(
      String houseID, String email, String fullname) async {
    try {
      QuerySnapshot userQuery;
      if (email.isNotEmpty) {
        // ✅ Search by email for Google users
        userQuery = await _firestore
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
      } else {
        // ✅ Search by full name for Apple users
        userQuery = await _firestore
            .collection('users')
            .where('fullName', isEqualTo: fullname)
            .limit(1)
            .get();
      }

      if (userQuery.docs.isEmpty) {
        return "❌ No user found with this email.";
      }

      String userId = userQuery.docs.first.id;

      // Add user to house's members list
      DocumentSnapshot houseDoc =
          await _firestore.collection('houses').doc(houseID).get();
      if (!houseDoc.exists) {
        return "❌ House not found.";
      }
      // ✅ Check if user is already a member
      Map<String, dynamic> houseData = houseDoc.data() as Map<String, dynamic>;
      List<dynamic> members = houseData['members'] ?? [];

      if (members.contains(userId)) {
        return "⚠️ User is already a member of this house.";
      }

      // ✅ Add user to house's members list
      await _firestore.collection('houses').doc(houseID).update({
        'members': FieldValue.arrayUnion([userId])
      });

      return "✅ Member added successfully!";
    } catch (e) {
      return "❌ Error adding member: $e";
    }
  }

  // ✅ Remove a member from the house
  Future<String> removeMember(String houseID, String userId) async {
    try {
      // ✅ Get the house document
      DocumentSnapshot houseDoc =
          await _firestore.collection('houses').doc(houseID).get();
      if (!houseDoc.exists) {
        return "❌ House not found.";
      }

      // ✅ Get the members list
      Map<String, dynamic> houseData = houseDoc.data() as Map<String, dynamic>;
      List<dynamic> members = houseData['members'] ?? [];

      // ✅ Check if the user is in the members list
      if (!members.contains(userId)) {
        return "⚠️ User is not a member of this house.";
      }

      // ✅ Remove user from the house's members list
      await _firestore.collection('houses').doc(houseID).update({
        'members': FieldValue.arrayRemove([userId])
      });

      return "✅ Member removed successfully!";
    } catch (e) {
      return "❌ Error removing member: $e";
    }
  }

  // ✅ Check if current user is an admin
  Future<bool> isUserAdmin(String houseID) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      DocumentSnapshot houseDoc =
          await _firestore.collection('houses').doc(houseID).get();
      if (!houseDoc.exists) return false;
      Map<String, dynamic> houseData = houseDoc.data() as Map<String, dynamic>;
      if (houseData == null || !houseData.containsKey('admin_uid'))
        return false;

      return houseData['admin_uid'] == user.uid;
    } catch (e) {
      print("❌ Error checking admin status: $e"); // ✅ Debugging log
      return false; // ✅ Default to false in case of an error
    }
  }
}
