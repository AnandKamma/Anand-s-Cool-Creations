import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;


  Stream<User?> authStatesChange() => _firebaseAuth.authStateChanges();

  // ✅ Get User Email
  String getUserEmail() => _firebaseAuth.currentUser?.email ?? 'User';

  // ✅ Fetch House ID Efficiently
  Future<String?> getHouseID(String uid) async {
    final firestore = FirebaseFirestore.instance;
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    print("📡 Fetching houseID for user: $uid from 'houses' collection...");

    // 🔥 Step 1: Check if the user exists in any house in 'houses' collection
    QuerySnapshot querySnapshot = await firestore
        .collection('houses')
        .where('members', arrayContains: uid) // ✅ Finds where the user is a member
        .limit(1) // Only get the first match
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String houseID = querySnapshot.docs.first.id; // ✅ Get the house document ID
      print("✅ Found houseID in 'houses' collection: $houseID");

      // ✅ Store houseID in SharedPreferences for faster access
      await prefs.setString('houseID', houseID);
      return houseID;
    }

    // 🔥 Step 2: If Firestore has no house, remove old SharedPreferences data
    print("❌ No house found for user. Clearing SharedPreferences...");
    await prefs.remove('houseID');
    return null;
  }



  String generateNonce([int length = 32]) {
    final random = Random.secure();
    final bytes = List<int>.generate(length, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }

  String sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  Future<void> _updateUserFirestore(UserCredential userCredential, String fullName, String signInMethod) async {
    final user = userCredential.user;
    if (user == null) return;

    final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
    final userSnapshot = await userDoc.get();

    // ✅ Preserve existing user data while updating Firestore
    Map<String, dynamic> userData = {
      'email': user.email ?? "No Email",
      'uid': user.uid,
      'fullName': fullName,
      'signInMethod': signInMethod,
    };

    if (userSnapshot.exists) {
      await userDoc.update(userData);
    } else {
      await userDoc.set(userData);
    }

    print("✅ User data updated in Firestore!");
  }

  Future<String?> _fetchUserFullName(String? uid) async {
    if (uid == null) return null;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

    if (userDoc.exists && userDoc.data()?['fullName'] != null) {
      print("✅ Found existing full name in Firestore: ${userDoc['fullName']}");
      return userDoc['fullName'];
    }

    print("⚠️ No existing full name found in Firestore.");
    return null; // If no name is found, return null
  }

  Future<UserCredential?> loginWithApple(BuildContext context) async {
    try {
      // ✅ Step 1: Trigger Apple Sign-In
      print("🔄 Starting Apple Sign-In process...");
      final rawNonce = generateNonce();
      final hashedNonce = sha256ofString(rawNonce);

      if (FirebaseAuth.instance.currentUser != null) {
        print("⚠️ A user is already signed in: ${FirebaseAuth.instance.currentUser!.uid}");
        print("🔄 Signing out current user before proceeding...");
        await FirebaseAuth.instance.signOut(); // 🔥 Ensure a fresh sign-in
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName],
        webAuthenticationOptions: WebAuthenticationOptions(
          redirectUri: Uri.parse('https://lock-7a5c7.firebaseapp.com/__/auth/handler'),
          clientId: 'com.anandkamma.lock',
          // Forces fresh login
        ),
        nonce: hashedNonce,
        state: generateNonce(),
      );
      print("✅ Apple Sign-In Successful: ${appleCredential}");
      print("🔍 Identity Token: ${appleCredential.identityToken}");
      print("🔍 Authorization Code: ${appleCredential.authorizationCode}");
      print("🔍 Raw Nonce: $rawNonce");
      print("🔍 Hashed Nonce: $hashedNonce");



      if (appleCredential.identityToken == null) {
        print("❌ Error: Apple Sign-In did not return an identityToken.");
        return null;
      }

      // ✅ Step 2: Create OAuth credential using the Apple token
      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );


      // ✅ Step 3: Sign in with Firebase
      print("🔄 Signing in with Firebase...");
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
      print("✅ Firebase Sign-In Successful! User: ${userCredential.user?.uid}");

      String? fullName = await _fetchUserFullName(userCredential.user?.uid);

      // ✅ Step 4: Handle missing full name (if Apple doesn’t provide it)
      if (fullName == null || fullName.isEmpty) {
        // ✅ If no name exists in Firestore, check if Apple provided one
        fullName = appleCredential.givenName != null
            ? "${appleCredential.givenName} ${appleCredential.familyName}".trim()
            : null;

        // ✅ If Apple didn’t provide a name, ask the user
        if (fullName == null || fullName.isEmpty) {
          print("⚠️ No name found in Firestore. Asking user...");
          fullName = await _askForUserName(context);
        }

        // ✅ Save the name in Firestore
        await _updateUserFirestore(userCredential, fullName, "Apple");
      }
      return userCredential; // 🔥 Ensure UserCredential is returned

    } catch (e) {

      print("❌ Error during Apple Sign-In: $e");

      if (e.toString().contains('user-mismatch')) {
        print("⚠️ Detected user mismatch error. Signing out and retrying...");
        await FirebaseAuth.instance.signOut();

        try {
          print("🔄 Retrying Apple Sign-In...");
          final rawNonce = generateNonce();
          final hashedNonce = sha256ofString(rawNonce);

          final appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            webAuthenticationOptions: WebAuthenticationOptions(
              redirectUri: Uri.parse('https://YOUR_FIREBASE_PROJECT_ID.firebaseapp.com/__/auth/handler'),
              clientId: 'com.anandkamma.lock',
            ),
            nonce: hashedNonce,
            state: generateNonce(),
          );

          if (appleCredential.identityToken == null) {
            print("❌ Error: Apple Sign-In did not return an identityToken.");
            return null;
          }

          final oAuthCredential = OAuthProvider('apple.com').credential(
            idToken: appleCredential.identityToken,
            rawNonce: rawNonce,
          );

          print("🔄 Signing in with Firebase after retry...");
          UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
          print("✅ Firebase Sign-In Successful after retry! User: ${userCredential.user?.uid}");

          // ✅ Handle name input if Apple does not provide it
          String? fullName = appleCredential.givenName != null
              ? "${appleCredential.givenName} ${appleCredential.familyName}".trim()
              : null;

          if (fullName == null || fullName.isEmpty) {
            print("⚠️ Apple did not provide a full name. Asking user...");
            fullName = await _askForUserName(context);
          }

          // ✅ Update Firestore with user data
          await _updateUserFirestore(userCredential, fullName, "Apple");

          return userCredential; // 🔥 Ensure UserCredential is returned after retry

        } catch (retryError) {
          print("❌ Error during retry: $retryError");
          return null;
        }
      }

      return null;

    }
  }

  Future<UserCredential?> _signInWithCredential(OAuthCredential credential, {String signInMethod = ''}) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      User user = userCredential.user!;

      // ✅ Fetch existing user data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      String? fullName = user.displayName ?? (userDoc.exists ? userDoc['fullName'] ?? 'Unknown User' : 'Unknown User');

      // ✅ Preserve houseID if it exists
      String? existingHouseID;
      Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?; // Explicitly cast
      if (userDoc.exists && userData != null && userData.containsKey('houseID')) {
        existingHouseID = userDoc['houseID'];
      } else {
        existingHouseID = null; // Prevents error if houseID is missing
      }
      // ✅ Update Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email ?? "No Email",
        'uid': user.uid,
        'fullName': fullName,
        'signInMethod': signInMethod,
        if (existingHouseID != null) 'houseID': existingHouseID, // Preserve houseID
      }, SetOptions(merge: true));

      // ✅ Fetch & store House ID if missing
      await getHouseID(user.uid);

      return userCredential;
    } catch (e) {
      print("❌ Error during Sign-In: $e");
      return null;
    }
  }


  // ✅ Google Login (Uses `_signInWithCredential`)
  Future<UserCredential?> loginWithGoogle(BuildContext context) async {
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        print("User cancelled Google Sign-In.");
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential cred = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);

      // ✅ Step 3: Authenticate with Firebase
      UserCredential? userCredential = await _signInWithCredential(cred, signInMethod: 'Google');
      if (userCredential == null) {
        print("❌ Google Sign-In Failed!");
        return null;
      }
      print("✅ Google Sign-In Successful: ${userCredential.user?.uid}");


      await Future.delayed(Duration(milliseconds: 500)); // Ensure Firestore sync

      return userCredential;
    } catch (e) {
      print("❌ Error during Google Sign-In: $e");
      return null;
    }
  }

  // ✅ Apple Login (Uses `_signInWithCredential`)

  // ✅ Logout
  Future<void> signout() async {
    await _firebaseAuth.signOut();
  }

  // ✅ Ask for User Name if missing
  Future<String> _askForUserName(BuildContext context) async {
    TextEditingController nameController = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFFcbc7bc), // 🔹 Matches background color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // 🔹 Rounded corners
          side: BorderSide(
            color: Color(0xFF38463e), // 🔹 Outer border color
            width: 7, // 🔹 Outer border thickness
          ),
        ),
        title: Text(
          "Enter Your Name",
          style: TextStyle(
            color: Color(0xFF38463e), // 🔹 Matches text color
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: TextStyle(color: Color(0xFF38463e)), // 🔹 Text color inside field
          decoration: InputDecoration(
            hintText: "Full Name",
            hintStyle: TextStyle(color: Color(0xFF38463e).withOpacity(0.6)), // 🔹 Subtle hint text
            filled: true,
            fillColor: Color(0xFFcbc7bc), // 🔹 Matches background
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF38463e), width: 2), // 🔹 Border color
              borderRadius: BorderRadius.circular(12), // 🔹 Rounded text field border
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF38463e), width: 2.5), // 🔹 Focus effect
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              String enteredName = nameController.text.trim();
              if (enteredName.isNotEmpty) {
                Navigator.pop(context, enteredName);
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFFcbc7bc), // 🔹 Text color
              backgroundColor: Color(0xFF38463e), // 🔹 Button background
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12), // 🔹 Rounded button
              ),
            ),
            child: Text(
              "Submit",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ?? "User"; // Default fallback
  }

}
