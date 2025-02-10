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
        .where('members', arrayContains: user.uid) // Find house where user is a member
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

  void fetchTasksFromFirestore() {
    print("🔍 Fetching tasks for houseID: $houseID"); // Debug print
    if (houseID==null||houseID!.isEmpty) {
      print("❌ Error: No house ID provided.");
      return;
    }

    _firestore.
    collection('houses')
        .doc(houseID)
        .collection('tasks').
    orderBy('timestamp',descending: true).
    snapshots().
    listen((snapshot) {
      _tasks.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        try {
          final task = Tasks(
            id: doc.id,
            name: data['task'] ?? 'Untitled Task',
            description: data['description'] ?? '',
            isDone: data['isDone'] ?? false,
            timestamp: (data['timestamp'] as Timestamp?)
                ?.toDate(), // Convert Firestore timestamp to DateTime
            sender: data['sender'] ?? 'Unknown',
          );
          _tasks.add(task);
        } catch (e) {
          print('Error processing document with ID ${doc.id}: $e');
        }
      }
      notifyListeners();
    });
  }

  void addTaskNoDescription(String newTaskTitle) async {
    final User? user = _auth.currentUser; // Get the logged-in user
    final email = user?.email ?? 'Unknown';
    final docRef = await _firestore.collection('houses').
    doc(houseID).
    collection('tasks').add({
      'task': newTaskTitle,
      'description': '',
      'isDone': false,
      'sender': email,
      'timestamp': FieldValue.serverTimestamp()
    });
    _tasks.add(Tasks(
      id: docRef.id,
      name: newTaskTitle,
      description: '',
      sender: email,
      timestamp: DateTime.now()
    ));
    notifyListeners();
    print("Using houseID: $houseID");
  }

  void addTaskWithDescription(String title, String description) async {
    final User? user = _auth.currentUser; // Get the logged-in user
    final email = user?.email ?? 'Unknown';
    final docRef = await _firestore.collection('houses').
    doc(houseID).
    collection('tasks').add({
      'task': title,
      'description': description,
      'isDone': false,
      'sender': email,
      'timestamp': FieldValue.serverTimestamp()
    });
    _tasks.add(Tasks(
      id: docRef.id,
      name: title,
      description: description,
        sender: email,
        timestamp: DateTime.now()
    ));
    notifyListeners();
  }

  void updateTask(Tasks task) async {
    task.toggelDone();
    notifyListeners();
    await _firestore.collection('houses').
    doc(houseID).
    collection('tasks').doc(task.id).update({
      'isDone': task.isDone,
    });
  }

  void deleteTask(Tasks task) async {
    _tasks.remove(task);
    notifyListeners();
    await _firestore.collection('houses').
    doc(houseID).
    collection('tasks').doc(task.id).delete();
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
        return snapshot.docs.first["fullName"] ?? email; // ✅ Return name if found
      }
      return email; // ✅ If no name is found, return the email as fallback
    } catch (e) {
      return email; // ✅ If Firestore fails, return email
    }
  }
}
