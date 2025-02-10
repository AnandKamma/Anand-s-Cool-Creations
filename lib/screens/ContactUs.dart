import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:lock/constonants.dart';

class ContactUsPage extends StatefulWidget {
  static const String id = 'ContactUs_screen';
  @override
  _ContactUsPageState createState() => _ContactUsPageState();
}

class _ContactUsPageState extends State<ContactUsPage> {
  TextEditingController _feedbackController = TextEditingController();

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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismisses the keyboard
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight),
          child: Container(
            decoration: kContainerNeumorphim,
            child: AppBar(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(12))),
              title: Text(
                'Your Opinion Matters',
                style: TextStyle(
                    color: kContactUsPageTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 30,
                    fontFamily: kContactUsPagePrimaryFontFamily),
              ),
              backgroundColor: kContactUsPageAppBarBkgColor,
            ),
          ),
        ),
        backgroundColor: kContactUsPageBkgColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(kBumbleBeeLogo,size: 200,color: kTextAndIconColor,),
                TextField(
                  controller: _feedbackController,
                  textAlign: TextAlign.center,
                  textAlignVertical: TextAlignVertical.center,
                  textInputAction: TextInputAction.done,
                  maxLines: 5 ,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText:'                                                                Got ideas? Got Feedback? Your thoughts fuel our innovation—let us hear them!',
                    hintStyle: TextStyle(
                      color: kContactUsPageHintTextColor,
                      fontFamily: kContactUsPagePrimaryFontFamily,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: kContactUsPageTextFieldBkgColor,
                    enabledBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: kContactUsPageTextFieldBorderColor, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: kContactUsPageTextFieldBorderColor, width: 2),
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Send Feedback Button
                Center(
                  child: ElevatedButton(
                    onPressed: _sendEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kContactUsPageElevatedButtonBkgColor,
                      padding: EdgeInsets.symmetric(
                          horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Send Feedback",
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: kContactUsPagePrimaryFontFamily,
                          fontWeight: FontWeight.bold,
                          color: kContactUsPageElevatedButtonTextColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
