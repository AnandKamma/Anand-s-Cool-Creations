// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:lock/components/Animations.dart';
import 'package:lock/components/LoginOptionButton.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lock/screens/AdminPage.dart';
import 'package:lock/screens/Home%20Screen.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';
import 'package:lock/components/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  static const String id = 'login_screen';
  final AuthService authService = AuthService();

  LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

Future<void> checkUserRegistration(BuildContext context, String userId) async {
  print("🔍 Checking user registration...");

  try {
    final firestore = FirebaseFirestore.instance;
    String? houseID = await AuthService().getHouseID(userId);
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print("🔍 Retrieved houseID: $houseID");

    print("🔍 Retrieved houseID from Firestore: $houseID");

    if (houseID == null || houseID.isEmpty) {
      print("❌ No house assigned in Firestore.");

      // 🔥 Clear old SharedPreferences data if Firestore doesn't have a houseID
      await prefs.remove('houseID');

      // Check if there's old data in SharedPreferences (could be outdated)
      String? storedHouseID = prefs.getString('houseID');
      if (storedHouseID != null && storedHouseID.isNotEmpty) {
        print("⚠️ WARNING: Using outdated HouseID from SharedPreferences: $storedHouseID");

        // ✅ Redirect to HomeScreen (assuming this is intentional)
        Navigator.of(context).pushReplacement(
          FadePageRoute(routeName: HomeScreen.id),
        );
        return;
      }

      print("🚨 No valid house found. Redirecting to AdminPage...");
      Navigator.pushReplacementNamed(context, AdminPage.id);
      return;
    }

    print("📡 Fetching user document from Firestore...");
    DocumentSnapshot userDoc = await firestore
        .collection('users')
        .doc(userId)
        .get(const GetOptions(source: Source.server)); // Force fresh fetch

    if (!userDoc.exists || userDoc.data() == null) {
      print("❌ User does NOT exist in Firestore. Clearing old data...");
      await prefs.remove('houseID');
      Navigator.pushReplacementNamed(context, AdminPage.id);
      return;
    }


    print("📡 Fetching house document with ID: $houseID...");
    DocumentSnapshot houseDoc = await firestore
        .collection('houses')
        .doc(houseID)
        .get(const GetOptions(source: Source.server)); // Force fresh fetch

    if (!houseDoc.exists) {
      print("❌ House with ID $houseID does NOT exist. Clearing old data...");

      // 🔥 Remove the invalid `houseID` from Firestore users collection
      await firestore.collection('users').doc(userId).update({'houseID': FieldValue.delete()});

      // 🔥 Remove the old `houseID` from SharedPreferences
      await prefs.remove('houseID');

      Navigator.pushReplacementNamed(context, AdminPage.id);
      return;
    }

    print("✅ House document found: ${houseDoc.data()}");

    // 🔥 Ensure houseData is not NULL
    Map<String, dynamic>? houseData = houseDoc.data() as Map<String, dynamic>?;
    if (houseData == null) {
      print("❌ House data is NULL. Clearing SharedPreferences and redirecting...");
      await prefs.remove('houseID');
      Navigator.pushReplacementNamed(context, AdminPage.id);
      return;
    }

    // 🔥 Check if the user is a member of the house
    List<dynamic>? members = houseData['members'];
    if (members == null || !members.contains(userId)) {
      print("❌ User is NOT in the house members list. Redirecting...");
      await prefs.remove('houseID');
      Navigator.pushReplacementNamed(context, AdminPage.id);
      return;
    }

    // ✅ Step 4: Store House ID in SharedPreferences (after verification)
    await prefs.setString('houseID', houseID);
    print("✅ HouseID stored in SharedPreferences: ${prefs.getString('houseID')}");

    // ✅ Redirect to HomeScreen
    print("✅ User verified in Firestore. Redirecting to HomeScreen...");
    Navigator.of(context).pushReplacement(
      FadePageRoute(routeName: HomeScreen.id),
    );

  } catch (e) {
    print("❌ Error during user check: $e");
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('houseID');
    Navigator.pushReplacementNamed(context, AdminPage.id);
  }
}






class _LoginScreenState extends State<LoginScreen> {
  bool showSpinner = false;
  String? email;
  String? password;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFcbc7bc),
      body: ModalProgressHUD(
        color: Color(0xFF38463e),
        inAsyncCall: showSpinner,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ColoriseText(text: 'Welcome Back'),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Color(0xFF38463e),
                      ),
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('Sign in with')),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Color(0xFF38463e),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: LoginOptions(
                      iconbgColor: Color(0xFFb37400),
                      onPress: () async {
                        setState(() {
                          showSpinner = true;
                        });

                        try {
                          final authService = AuthService();
                          UserCredential? userCredential =
                              await authService.loginWithGoogle(context);

                          if (userCredential != null) {
                            print("✅ Google Sign-In successful!");

                            // ✅ Auto-handle user redirection after login
                            await checkUserRegistration(
                                context, userCredential.user!.uid);
                          } else {
                            print("❌ Google Sign-In Failed or Cancelled");
                          }
                        } catch (e) {
                          print("❌ Error during sign in with Google: $e");
                        } finally {
                          setState(() {
                            showSpinner = false;
                          });
                        }
                      },
                      cardChild: IconContent(
                        icon: FontAwesomeIcons.google,
                        size: 65,
                        color: Color(0xFFb37400),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: LoginOptions(
                      iconbgColor: Colors.grey.shade700,
                      onPress: () async {
                        setState(() {
                          showSpinner = true;
                        });

                        try {
                          final authService = AuthService();
                          UserCredential? userCredential =
                              await authService.loginWithApple(context);

                          if (userCredential != null) {
                            print("✅ Apple Sign-In successful!");

                            // ✅ Auto-handle user redirection after login
                            await checkUserRegistration(
                                context, userCredential.user!.uid);
                          } else {
                            print("❌ Apple Sign-In Failed or Cancelled");
                          }
                        } catch (e) {
                          print("❌ Error during sign in with Apple: $e");
                        } finally {
                          setState(() {
                            showSpinner = false;
                          });
                        }
                      },
                      cardChild: IconContent(
                        icon: FontAwesomeIcons.apple,
                        size: 68,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
