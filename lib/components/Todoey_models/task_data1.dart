import 'package:flutter/foundation.dart';
import 'dart:collection';
import 'package:lock/components/Todoey_models/task_data2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class TaskData extends ChangeNotifier {
  final List<Tasks> _tasks = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? houseID;

  void setHouseID(String newHouseID) {
    print("🔍 Setting house ID: $newHouseID"); // Debug print
    houseID = newHouseID;
    fetchTasksFromFirestore(); // Fetch tasks for the updated house
  }

  UnmodifiableListView<Tasks> get tasks {
    return UnmodifiableListView(_tasks);
  }

  int get taskcount {
    return _tasks.length;
  }

  Future<void> initializeHouseID() async {
    User? user = _auth.currentUser;
    if (user == null) {
      print("❌ User not logged in.");
      return;
    }

    print("🔍 Fetching House ID for user: ${user.uid}");

    QuerySnapshot querySnapshot = await _firestore
        .collection('houses')
        .where('members',
            arrayContains: user.uid) // Find house where user is a member
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) {
      print("❌ No house found for user.");
      return;
    }

    String fetchedHouseID = querySnapshot.docs.first.id;
    print("✅ Found houseID: $fetchedHouseID");

    setHouseID(fetchedHouseID); // ✅ Store house ID and fetch tasks
  }




  void fetchTasksFromFirestore() async {
    print("🔍 Fetching tasks for houseID: $houseID");

    if (houseID == null || houseID!.isEmpty) {
      print("❌ Error: No house ID provided.");
      return;
    }

    final User? user = _auth.currentUser;
    if (user == null) {
      print("❌ Error: No authenticated user.");
      return;
    }

    // ✅ Fetch user's full name
    DocumentSnapshot userDoc = await _firestore.collection("users").doc(user.uid).get();
    String userName = userDoc.exists ? userDoc["fullName"] ?? user.uid : user.uid;

    print("🆔 Fetching tasks for user: ${user.uid} | Name: $userName");

    Set<String> seenTaskIds = {}; // ✅ Track already added task IDs

    // ✅ Get house members list (to handle "All Members")
    DocumentSnapshot houseDoc = await _firestore.collection("houses").doc(houseID).get();
    List<String> houseMembers = [];

    if (houseDoc.exists) {
      Map<String, dynamic>? houseData = houseDoc.data() as Map<String, dynamic>?;
      if (houseData != null && houseData.containsKey("members")) {
        houseMembers = List<String>.from(houseData["members"]);
      }
    }

    print("🏠 House Members: $houseMembers");

    // ✅ Fetch tasks where:
    // - The recipient contains the user’s UID (directly assigned tasks)
    // - OR the recipient contains the user’s name (for named-based assignments)
    // - OR the recipient contains "All Members" (shared with everyone in the house)
    List<QuerySnapshot> snapshots = await Future.wait([
      _firestore
          .collection('houses')
          .doc(houseID)
          .collection('tasks')
          .where("recipient", arrayContainsAny: [user.uid, userName, "All Members"]) // ✅ Include personal, name-based, and "All Members"
          .orderBy('timestamp', descending: true)
          .get(),
    ]);

    // ✅ Clear tasks before adding new ones
    _tasks.clear();

    // ✅ Process fetched tasks
    for (var snapshot in snapshots) {
      for (var doc in snapshot.docs) {
        if (seenTaskIds.contains(doc.id)) continue; // ✅ Skip duplicates
        seenTaskIds.add(doc.id); // ✅ Mark task as added

        final data = doc.data();
        if (data == null || data is! Map<String, dynamic>) {
          print("❌ Skipping task ${doc.id}: Data is null or invalid.");
          continue;
        }

        // ✅ Check if the task is assigned to "All Members"
        List<dynamic> recipientList = List<dynamic>.from(data["recipient"] ?? []);

        // ✅ If recipient is "All Members", verify the user is actually a member
        if (recipientList.contains("All Members") && !houseMembers.contains(user.uid)) {
          print("🚨 Skipping task ${doc.id}: User is not in house members.");
          continue; // ✅ If user is NOT in house members, skip this task
        }

        print("📝 Task Retrieved: ${data['task']} | Recipient: ${data['recipient']} | Timestamp: ${data['timestamp']}");

        try {
          final task = Tasks(
            id: doc.id,
            name: data['task'] ?? 'Untitled Task',
            description: data['description'] ?? '',
            isDone: data['isDone'] ?? false,
            timestamp: (data['timestamp'] is Timestamp)
                ? (data['timestamp'] as Timestamp).toDate()
                : null,
            sender: data['sender'] ?? 'Unknown',
          );
          _tasks.add(task);
        } catch (e) {
          print('❌ Error processing task: ${doc.id} -> $e');
        }
      }
    }

    notifyListeners(); // ✅ Call notifyListeners() only once
  }


  void addTaskNoDescription(String newTaskTitle, String recipient) async {
    final User? user = _auth.currentUser; // Get the logged-in user
    final email = user?.email ?? 'Unknown';

    List<String> recipientList = [];

    if (recipient == "all") {
      // ✅ Fetch all house members
      DocumentSnapshot houseDoc = await _firestore.collection("houses").doc(houseID).get();
      if (houseDoc.exists) {
        Map<String, dynamic>? houseData = houseDoc.data() as Map<String, dynamic>?;
        if (houseData != null && houseData.containsKey("members")) {
          recipientList = List<String>.from(houseData["members"]);
        }
      }
    } else {
      recipientList = [recipient]; // ✅ If not "all", store only selected recipient
    }

    final docRef = await _firestore
        .collection('houses')
        .doc(houseID)
        .collection('tasks')
        .add({
      'task': newTaskTitle,
      'description': '',
      'isDone': false,
      'sender': email,
      'recipient': recipientList,
      'timestamp': FieldValue.serverTimestamp()
    });
    _tasks.add(Tasks(
        id: docRef.id,
        name: newTaskTitle,
        description: '',
        sender: email,
        timestamp: DateTime.now()));
    notifyListeners();
    print("Using houseID: $houseID");
  }

  void addTaskWithDescription(String title, String description,String recipient) async {
    final User? user = _auth.currentUser; // Get the logged-in user
    final email = user?.email ?? 'Unknown';

    List<String> recipientList = [];

    if (recipient == "all") {
      // ✅ Fetch all house members
      DocumentSnapshot houseDoc = await _firestore.collection("houses").doc(houseID).get();
      if (houseDoc.exists) {
        Map<String, dynamic>? houseData = houseDoc.data() as Map<String, dynamic>?;
        if (houseData != null && houseData.containsKey("members")) {
          recipientList = List<String>.from(houseData["members"]);
        }
      }
    } else {
      recipientList = [recipient]; // ✅ If not "all", store only selected recipient
    }

    final docRef = await _firestore
        .collection('houses')
        .doc(houseID)
        .collection('tasks')
        .add({
      'task': title,
      'description': description,
      'isDone': false,
      'sender': email,
      'recipient': recipientList,
      'timestamp': FieldValue.serverTimestamp()
    });
    _tasks.add(Tasks(
        id: docRef.id,
        name: title,
        description: description,
        sender: email,
        timestamp: DateTime.now()));
    notifyListeners();
  }

  void updateTask(Tasks task) async {
    task.toggelDone();
    notifyListeners();
    await _firestore
        .collection('houses')
        .doc(houseID)
        .collection('tasks')
        .doc(task.id)
        .update({
      'isDone': task.isDone,
    });
  }

  void deleteTask(Tasks task) async {
    _tasks.remove(task);
    notifyListeners();
    await _firestore
        .collection('houses')
        .doc(houseID)
        .collection('tasks')
        .doc(task.id)
        .delete();
  }

  Future<String> getUserName(String email) async {
    try {
      // Query Firestore for a user with this email
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where("email", isEqualTo: email)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first["fullName"] ??
            email; // ✅ Return name if found
      }
      return email; // ✅ If no name is found, return the email as fallback
    } catch (e) {
      return email; // ✅ If Firestore fails, return email
    }
  }
  List<Map<String, String>> _houseMembers = []; // Stores UID & Name

  List<Map<String, String>> get houseMembers => _houseMembers;


  Future<void> fetchHouseMembers() async {
    try{
      _houseMembers.clear(); // Clear previous data

      User? user = _auth.currentUser;
      if (user == null) return;

      QuerySnapshot houseSnapshot = await _firestore
          .collection("houses")
          .where("members", arrayContains: user.uid)
          .limit(1)
          .get();

      if (houseSnapshot.docs.isNotEmpty) {
        String houseID = houseSnapshot.docs.first.id;

        DocumentSnapshot houseDoc =
        await _firestore.collection("houses").doc(houseID).get();

        if (houseDoc.exists) {
          // ✅ Explicitly cast houseDoc.data() as Map<String, dynamic>
          Map<String, dynamic>? houseData =
          houseDoc.data() as Map<String, dynamic>?;

          if (houseData != null && houseData.containsKey("members")) {
            List<dynamic> members = houseData["members"];

            // ✅ Fetch names from "users" collection for each UID
            _houseMembers = await Future.wait(members.map((uid) async {
              DocumentSnapshot userDoc =
              await _firestore.collection("users").doc(uid.toString()).get();

              String name = userDoc.exists ? userDoc["fullName"] ?? uid.toString() : uid.toString();
              return {"uid": uid.toString(), "name": name}; // ✅ Store UID and Name
            }));
          }
        }
      }

      notifyListeners(); // ✅ Updates UI without setState()
    }catch(e){
      debugPrint('Error fetching house members: $e');
      notifyListeners(); // Ensure UI updates even if an error occurs
    }

  }



}
