import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lock/components/Registration_service.dart'; // ✅ Import your service class
import 'package:lock/screens/Calibration/CalibrationPage.dart';
import 'package:lock/components/Animations.dart'; // your custom fade animation

class AdminPage extends StatefulWidget {
  static const String id = 'AdminPage';

  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final HouseService houseService =
      HouseService(); // ✅ Create instance of service
  TextEditingController houseIDController = TextEditingController();
  TextEditingController esp32IDController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    houseIDController.dispose();
    esp32IDController.dispose();
    super.dispose();
  }

  /// ✅ Register House and Save Data
  void showInformationAboutRole(BuildContext context, String Role) {
    final rootContext = context;
    FocusNode houseIDFocus = FocusNode();
    bool showInputs = false; // Controls what is displayed

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: Color(0xFF38463e), // Background color of the modal
                border: Border(
                  top: BorderSide(color: Color(0xFFcbc7bc), width: 5),
                  left: BorderSide(color: Color(0xFFcbc7bc), width: 5),
                  right: BorderSide(color: Color(0xFFcbc7bc), width: 5),
                ),
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20)), // Rounded top corners
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFcbc7bc), // Inner border effect
                    offset: Offset(0, 0),
                    blurRadius: 5,
                    spreadRadius: -4, // Negative spread for inner glow effect
                  ),
                ],
              ),
              child: DraggableScrollableSheet(
                initialChildSize: showInputs ? 0.8 : 0.5,
                minChildSize: 0.5,
                maxChildSize: 0.8,
                expand: false,
                builder: (context, scrollController) {
                  return SingleChildScrollView(
                    controller: scrollController,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!showInputs) // Show text first
                            Column(
                              children: [
                                Container(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Center(
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            if (Role == 'Admin') ...[
                                              TextSpan(
                                                text:
                                                    "As an Admin, you have to make an unique house identifier and type in the name of device\n\n",
                                                style: TextStyle(
                                                  fontWeight: FontWeight
                                                      .bold, // 🔹 Make important parts bold
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    "Then, you have the ability to add members and remove members within your app.\n\n",
                                                style: TextStyle(
                                                  fontWeight: FontWeight
                                                      .bold, // 🔹 Make important parts bold
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    "These members will have access to operate the lock and will have a unified app experience\n\n",
                                                style: TextStyle(
                                                  fontWeight: FontWeight
                                                      .bold, // 🔹 Make important parts bold
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    "To add members, direct yourself to the settings page\n\n",
                                                style: TextStyle(
                                                  fontWeight: FontWeight
                                                      .bold, // 🔹 Make important parts bold
                                                ),
                                              ),
                                            ],
                                            if (Role != 'Admin') ...[
                                              TextSpan(
                                                text:
                                                    "Awesome! You are registered in our system.\n\n",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 22, // 🔥 Bold title
                                                ),
                                              ),
                                              TextSpan(
                                                text: "Notify your admin. \n",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),
                                              ),
                                              TextSpan(
                                                text: "Ensure that the exact ",
                                              ),
                                              TextSpan(
                                                text:
                                                    "email ID (Google Sign-In) or name (Apple Sign-In)",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20, // 🔥 Bold
                                                ),
                                              ),
                                              TextSpan(
                                                text:
                                                    " is used by the admin to identify you.\n",
                                              ),
                                              TextSpan(
                                                text:
                                                    "Wait for your admin to add you and restart the app.",
                                                style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20),
                                              ),
                                            ],
                                          ],
                                        ),
                                        textAlign: TextAlign
                                            .center, // 🔹 Centered for better readability
                                        style: TextStyle(
                                          color: Color(0xFFcbc7bc),
                                          fontSize:
                                              18, // 🔹 Reduced a bit for better layout
                                          fontFamily: 'Lato',
                                          height:
                                              1.5, // 🔹 Line spacing for better readability
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                TextButton(
                                  style: TextButton.styleFrom(
                                    backgroundColor: Color(0xFF38463e),
                                    foregroundColor: Color(0xFFcbc7bc),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          20), // 🔹 Rounded corners
                                      side: BorderSide(
                                          color: Color(0xFFcbc7bc),
                                          width:
                                              4), // 🔹 Border color & thickness
                                    ),
                                  ),
                                  onPressed: () {
                                    if (Role == 'Admin') {
                                      setModalState(() {
                                        showInputs = true;
                                      });
                                      Future.delayed(
                                          Duration(milliseconds: 300), () {
                                        houseIDFocus.requestFocus();
                                      });
                                    } else {
                                      Navigator.pop(
                                          context); // Just close for members
                                    }
                                  },
                                  child: Text(
                                      Role == "Admin" ? 'Next' : 'Got it!',
                                      style: TextStyle(
                                          fontSize: 22,
                                          color: Color(0xFFcbc7bc))),
                                ),
                              ],
                            )
                          else
                            Column(
                              children: [
                                TextField(
                                  controller: houseIDController,
                                  focusNode: houseIDFocus,
                                  decoration: InputDecoration(
                                    labelText: "House ID",
                                    labelStyle: TextStyle(
                                        color: Color(
                                            0xFFcbc7bc)), // 🔹 Custom label color
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(
                                            0xFFcbc7bc), // 🔹 Border color when focused
                                        width:
                                            2.5, // 🔹 Slightly thicker border when active
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          12), // 🔹 Rounded corners
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(
                                            0xFFcbc7bc), // 🔹 Default border color
                                        width: 2, // 🔹 Normal border thickness
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          12), // 🔹 Rounded corners
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(
                                            0xFFcbc7bc), // 🔹 Border color (fallback)
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    fillColor: Color(
                                        0xFF38463e), // 🔹 Background fill color
                                    filled:
                                        true, // 🔹 Ensures background color is applied
                                  ),
                                  style: TextStyle(
                                      color: Colors
                                          .white), // 🔹 Text color inside the field
                                  cursorColor: Color(
                                      0xFFcbc7bc), // 🔹 Cursor color matching theme
                                ),
                                SizedBox(height: 16),
                                TextField(
                                  controller: esp32IDController,
                                  decoration: InputDecoration(
                                    labelText: "Name of your lock",
                                    labelStyle: TextStyle(
                                        color: Color(
                                            0xFFcbc7bc)), // 🔹 Custom label color
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(
                                            0xFFcbc7bc), // 🔹 Border color when focused
                                        width:
                                            2.5, // 🔹 Slightly thicker border when active
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          12), // 🔹 Rounded corners
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(
                                            0xFFcbc7bc), // 🔹 Default border color
                                        width: 2, // 🔹 Normal border thickness
                                      ),
                                      borderRadius: BorderRadius.circular(
                                          12), // 🔹 Rounded corners
                                    ),
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(
                                            0xFFcbc7bc), // 🔹 Border color (fallback)
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    fillColor: Color(
                                        0xFF38463e), // 🔹 Background fill color
                                    filled:
                                        true, // 🔹 Ensures background color is applied
                                  ),
                                  style: TextStyle(color: Colors.white),
                                  cursorColor: Color(0xFFcbc7bc),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: isLoading
                                      ? null
                                      : () async {
                                          FocusScope.of(context)
                                              .unfocus(); // 🔹 Hide keyboard before processing
                                          setModalState(() => isLoading = true);
                                          final user =
                                              FirebaseAuth.instance.currentUser;
                                          if (user == null) return;

                                          try {
                                            await houseService
                                                .registerAdminHouse(
                                                    user.uid,
                                                    houseIDController.text
                                                        .trim(),
                                                    esp32IDController.text
                                                        .trim());
                                            if (mounted) Navigator.pop(context);
                                            // ✅ Wait a moment so modal animation completes cleanly
                                            Future.delayed(Duration(milliseconds: 250), () {
                                              if (mounted) {
                                                Navigator.of(rootContext).push(FadeToCalibrationRoute(page: CalibrationPage()));
                                              }
                                            });
                                          } catch (e) {
                                            print("❌ Error: $e");
                                          }

                                          setModalState(
                                              () => isLoading = false);
                                          FocusScope.of(context)
                                              .unfocus(); // 🔹 Hide keyboard before processing
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(
                                        0xFF38463e), // 🔹 Button background matching theme
                                    foregroundColor: Color(
                                        0xFFcbc7bc), // 🔹 Text color matching UI
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                          12), // 🔹 Smooth rounded corners
                                      side: BorderSide(
                                          color: Color(0xFFcbc7bc),
                                          width: 3), // 🔹 Custom border
                                    ),
                                    padding: EdgeInsets.symmetric(
                                        vertical: 15,
                                        horizontal: 25), // 🔹 Better spacing
                                    elevation:
                                        5, // 🔹 Adds a slight shadow effect for depth
                                  ),
                                  child: isLoading
                                      ? SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            color: Color(
                                                0xFFcbc7bc), // 🔹 Loader color matches text
                                          ),
                                        )
                                      : Text(
                                          'Submit',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight
                                                .bold, // 🔹 Slightly bold for visibility
                                            letterSpacing:
                                                1.2, // 🔹 Adds a nice spacing effect
                                          ),
                                        ),
                                ),
                              ],
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF38463e),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                  child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFF38463e),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFFcbc7bc), // Outer border color
                    width: 5, // Outer border width
                  ),
                  // Inner border - you need to add padding to make space for the inner border
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFcbc7bc),
                      // Inner border color
                      offset: Offset(0, 0),
                      blurRadius:
                          5, // You can adjust the blur for inner shadow effect
                      spreadRadius: -4, // Adjust for inner border effect
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      splashFactory:
                          NoSplash.splashFactory, // 🔹 Removes splash effect
                    ),
                    onPressed: () {
                      showInformationAboutRole(
                        context,
                        'Admin',
                      );
                    },
                    child: Text(
                      'Admin?',
                      style: TextStyle(
                          fontSize: 50,
                          color: Color(0xFFcbc7bc),
                          fontFamily: 'Lato'),
                    ),
                  ),
                ),
              )),
              SizedBox(
                height: 10,
              ),
              Expanded(
                  child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Color(0xFF38463e),
                  border: Border.all(
                    color: Color(0xFFcbc7bc), // Outer border color
                    width: 5, // Outer border width
                  ),
                  // Inner border - you need to add padding to make space for the inner border
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFcbc7bc), // Inner border color
                      offset: Offset(0, 0),
                      blurRadius:
                          5, // You can adjust the blur for inner shadow effect
                      spreadRadius: -4, // Adjust for inner border effect
                    ),
                  ],
                ),
                child: TextButton(
                  onPressed: () async {
                    showInformationAboutRole(context, 'Member');
                  },
                  child: Text('Member?',
                      style: TextStyle(
                          fontSize: 50,
                          color: Color(0xFFcbc7bc),
                          fontFamily: 'Lato')),
                ),
              ))
            ],
          ),
        ),
      ),
    );
  }
}
