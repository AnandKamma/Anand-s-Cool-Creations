import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lock/components/member_service.dart';
import 'package:lock/constonants.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lock/screens/Calibration/CalibrationPage.dart';
import 'package:lock/components/Animations.dart';

class SettingsPage extends StatefulWidget {
  static const String id = 'Settings_Page';
  final String houseID;

  SettingsPage({required this.houseID});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? userId;
  bool isAdmin = false;
  final MemberService _memberService = MemberService();
  TextEditingController emailController = TextEditingController();
  TextEditingController _feedbackController = TextEditingController();

  bool isAddingMember = false;
  FocusNode _focusNode = FocusNode(); // ✅ FocusNode to control the keyboard

  @override
  void initState() {
    super.initState();
    _checkIfAdmin();
  }

  // ✅ Check if the current user is an admin
  Future<void> _checkIfAdmin() async {
    bool adminStatus = await _memberService.isUserAdmin(widget.houseID);
    setState(() => isAdmin = adminStatus);
  }

  // ✅ Add a member using the service
  Future<void> _addMember() async {
    _focusNode.unfocus();
    setState(() => isAddingMember = true);

    String input = emailController.text.trim(); // ✅ Get input from text field

    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Enter a valid email or full name.")),
      );
      setState(() => isAddingMember = false);
      return;
    }
    bool isEmail = input.contains("@");
    String email = isEmail ? input : ""; // If input is an email, set email
    String fullName = isEmail ? "" : input; // If input is a name, set fullName

    String result = await _memberService.addMember(
        widget.houseID, email, fullName); // ✅ Pass input
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));

    emailController.clear();
    setState(() => isAddingMember = false);
  }

  // ✅ Remove a member using the service
  Future<void> _removeMember(String userId) async {
    // ✅ Call `removeMember` with email/fullName instead of userId
    String result = await _memberService.removeMember(widget.houseID, userId);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));

    emailController.clear(); // ✅ Clear input field after removing
  }

  void _sendEmail() async {
    final String feedback = _feedbackController.text.trim();

    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter your feedback.")),
      );
      return;
    }

    final Uri emailUri = Uri.parse(
        "mailto:dev.kamma04@gmail.com?subject=User Feedback&body=$feedback");

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
      _feedbackController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Feedback sent successfully!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Could not open email app.")),
      );
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    emailController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;//Screen Hieght
    return GestureDetector(
      onTap: () {
        FocusScope.of(context)
            .unfocus(); // ✅ Hide keyboard when tapping outside
      },
      child: Scaffold(
        backgroundColor: kAnnouncementScreenBkgColor,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: kContainerNeumorphim,
            child: AppBar(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(12))),
              title: Text(
                'People Who Matter',
                style: kSettingsAppBarTextStyle,
              ),
              backgroundColor: kAnnouncementScreenAppBarBkgColor,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: kSettingsUserInfoContainerDecoration,
                  child: Row(
                    children: [
                      Icon(Icons.account_circle,
                          color: kTextAndIconColor, size: 32), // Profile Icon
                      SizedBox(width: 12), // Spacing
                      Expanded(
                        child: FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(FirebaseAuth.instance.currentUser!.uid)
                              .get(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Text("Loading...",
                                  style: kSettingsTextStyle);
                            }
                            if (!snapshot.hasData || !snapshot.data!.exists) {
                              return Text(
                                  FirebaseAuth.instance.currentUser?.email ??
                                      "No Email",
                                  style: kSettingsTextStyle);
                            }

                            // ✅ Fetch user data
                            Map<String, dynamic> userData =
                                snapshot.data!.data() as Map<String, dynamic>;
                            String displayName = userData['fullName'] ??
                                FirebaseAuth.instance.currentUser?.email ??
                                "No Email";

                            return Text(displayName,
                                style: kSettingsTextStyle);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                Divider(
                  color: Colors.black,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        FadeToCalibrationRoute(page: CalibrationPage()),
                      );
                    },
                    icon: Icon(Icons.compass_calibration, color: Colors.white),
                    label: Text("Recalibrate", style: kSettingsElevatedButtonTextStyle),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kContactUsPageElevatedButtonBkgColor,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                TextField(
                  controller: _feedbackController,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.done,
                  maxLines: 3,
                  autofocus: false,
                  decoration: kSettingsFeedbackContainerDecoration,
                ),

                SizedBox(height: 10),

                // Send Feedback Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _sendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kContactUsPageElevatedButtonBkgColor,
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Send Feedback",
                      style: kSettingsElevatedButtonTextStyle,
                    ),
                  ),
                ),
                SizedBox(
                  height: 15,
                ),

                // ✅ Only show "Manage Members" if the user is an admin
                if (isAdmin) ...[
                  Text("Manage Members",
                      style: kSettingsTextStyle),
                  SizedBox(
                    height: 15,
                  ),
                  TextField(
                    controller: emailController,
                    focusNode: _focusNode,
                    textAlignVertical: TextAlignVertical.center,
                    maxLines: 2,
                    decoration: kSettingsManageMembersElevatedButtonDecoration,
                    textInputAction: TextInputAction.done,
                    onEditingComplete: () {
                      _focusNode
                          .unfocus(); // ✅ Hide keyboard when Done is pressed
                    },
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isAddingMember ? null : _addMember,
                      icon: isAddingMember
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2, // ✅ Smaller loading indicator
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(Icons.person_add,
                              color: Colors.white), // ✅ Add Icon

                      label: Text(
                        isAddingMember ? "Adding..." : "Add Member",
                        style: kSettingsElevatedButtonTextStyle,
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            kContactUsPageElevatedButtonBkgColor, // ✅ Custom button color
                        foregroundColor: kTextAndIconColor, // ✅ Text/icon color
                        padding:
                            EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 20),
                Text("Current Members:",
                    style: kSettingsTextStyle),

                // ✅ Fetch and display members list
                Container(
                  height: screenHeight*0.5, // ✅ Limit height to prevent overflow
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StreamBuilder<DocumentSnapshot>(
                    stream: _memberService.getMembersStream(widget.houseID),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data == null) {
                        return Center(child: kCircularProgressIndicator);
                      }

                      Map<String, dynamic>? houseData =
                      snapshot.data!.data() as Map<String, dynamic>?;
                      if (houseData == null ||
                          !houseData.containsKey('members')) {
                        return Center(child: Text("No members found."));
                      }

                      List<dynamic> members = houseData['members'];

                      return ListView.builder(
                        padding: EdgeInsets.all(
                            10), // ✅ Add padding inside the list
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          String userId = members[index];
                          return FutureBuilder(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return _buildMemberTile(
                                   name: "Loading...",icon:  Icons.hourglass_empty,userId: userId,showRemoveButton: isAdmin);
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data == null) {
                                return _buildMemberTile(
                                  name:   "Unknown User", icon:  Icons.error_outline,userId:  userId,showRemoveButton: isAdmin);
                              }

                              Map<String, dynamic>? userData =
                              snapshot.data!.data();
                              String userName = userData?['fullName'] ??
                                  "Unnamed User"; // ✅ Fetch full name

                              return _buildMemberTile(
                                  name:  userName,icon:  Icons.person,userId:  members[index],showRemoveButton: isAdmin);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberTile({

  required String name,
  required IconData icon,
  String? userId,
  bool showRemoveButton = false}
  ) {
    return Container(

    height:(MediaQuery.of(context).size.height)*0.07 ,
      margin: EdgeInsets.symmetric(vertical: 10), // ✅ Space between members
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: kContainerNeumorphim,
      child: Row(
        children: [
          Icon(icon, color: kAnnouncementScreenAppBarTextColor, size: 25), // ✅ Avatar icon
          SizedBox(width: 12), // ✅ Spacing
          Expanded(
            child: Text(
              name,
              style: kSettingsCurrentMembersContainerTextStyle,
            ),
          ),
          if (showRemoveButton &&userId != null) // ✅ Show remove button only if userId exists
            IconButton(
              icon: Icon(Icons.remove_circle, color: Colors.red),
              onPressed: () => _removeMember(userId),
            ),
        ],
      ),
    );
  }
}
