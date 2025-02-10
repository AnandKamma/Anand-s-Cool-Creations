import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'components/bumblee.dart';
//Common Constants
const kLogandRegTextFieldDecoration = InputDecoration(
  hintText: "Enter a value",
  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(32)),
  ),
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.black26, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(32)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(color: Colors.black38, width: 2),
    borderRadius: BorderRadius.all(Radius.circular(32)),
  ),
);

//Registration Constants
const kRegScafColor = Colors.white;
const kRegheading = Text('Create Account',style: TextStyle(fontSize: 45),textAlign: TextAlign.center,);
const kReghintTextEmail='Enter your email';
const kReghintTextPassword='Enter your password';

//Login Constants
const kLogScafColor = Color(0xFFcbc7bc);
const kLogheading = Text('Welcome Back',style: TextStyle(fontSize: 45),textAlign: TextAlign.center,);

//HomeScreen Constants
 final kContainerNeumorphim=BoxDecoration(
    color:Color(0xFFc2baab), //Colors.grey.shade300
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      //bottom right shadow is darker
      BoxShadow(
          color: Color(0xFFada28d),//Colors.grey.shade500,
          offset: Offset(5, 5),
          blurRadius: 15,
          spreadRadius: 1
      )
      //top left shadown is lighter
      ,BoxShadow(
          color: Color(0xFFd7d2c9),//Colors.white,
          offset: Offset(-5, -5),
          blurRadius: 15,
          spreadRadius: 1

      )
    ]
);
 final kHomeScreenBkgColor = Color(0xFFcbc7bc);//whitesmoke Color(0xFFefefef)
 final IconData kBumbleBeeLogo = (MyFlutterApp.bumblebee);
 final kTextAndIconColor = Color(0xFF38463e);//Color(0xff275654)
 final kCustomActionSliderLeftArrowColor=Color(0xff667f71);//Colors.green.shade900.withOpacity(0.2)
 final kCustomActionSliderMiddleArrowColor=Color(0xff4f6257);//Colors.green.shade900.withOpacity(0.6)
 final kCustomActionSliderRightArrowColor=Color(0xff38463e);//Colors.green.shade900.withOpacity(1)
 final kCustomActionSliderLeftIconColor=Color(0xFFc2baab);//Colors.white
 final kFeatureContainerBkgColor=Color(0xFFc2baab);//Colors.grey.shade300
 final kBottomNavBarBkgColor=Color(0xFFc2baab);//Colors.grey.shade500
 final kBottomNavBarWaterDropColor= Color(0xFF38463e);//Color(0xff275654);
 final kCircularProgressIndicator= CircularProgressIndicator(
   color: Color(0xFF38463e),);
 final kHomeScreenPrimaryFontFamily='Lato';//'Baskervville'
final kFeatureContainerFontFamily='ShadowsIntoLight';


//TodoHomeScreen Constants
final kTodoHomeScreenBkgColor= Color(0xFFcbc7bc);//Color(0xFFefefef)
final kTodoTextAndIconColor = Color(0xFF38463e);//Color(0xff275654)
final kTodoTaskCountTextColor= Color(0xFF38463e);//Colors.grey.shade700

//AddTaskScreen Constants
final kAddTaskScreenBkgColor= Color(0xFFc2baab);//Colors.grey.shade300
final kAddTaskTextAndIconColor = Color(0xFF38463e);//Color(0xff275654)
final kAddTaskHintTextColor=Colors.grey[600];
final kAddTaskTextFieldBkgColor=Color(0xFFe2ded7);//Colors.grey[200]
final kAddTaskTextFieldBorderColor= Color(0xFF38463e);//Color(0xff275654)
//TaskTile Constants
final kTaskTileUserTextandTimeColor=Color(0xfF6a6352);//Colors.grey.shade600
final kTaskTileTaskTextColor=Colors.grey.shade200;
final kTaskTileBkgColor=Color(0xFF38463e);//Color(0xff275654)
final kTaskTileDescriptionTextColor=Colors.grey.shade400;

//Announcements Screen
final kAnnouncementScreenBkgColor= Color(0xFFcbc7bc);//Color(0xFFefefef)
final kAnnouncementScreenAppBarBkgColor= Color(0xFFcbc7bc);//Colors.grey.shade300
final kAnnouncementScreenAppBarTextColor= Color(0xFF38463e);//Color(0xff275654)
final kAnnouncementScreenPrimaryFontFamily='Lato';
final kAnnouncementScreenMessageBubbleColor=Color(0xFF38463e);//Color(0xff275654)
final kAnnouncementScreenTextButtonTextColor=Color(0xFF38463e);//Color(0xff275654)
final kAnnouncementScreenTextFieldContainerColor=Color(0xFF38463e);//Color(0xff275654)
final kAnnouncementScreenDateColor=Colors.white54;

//ContactUsPage Screen Constants
final kContactUsPageBkgColor= Color(0xFFcbc7bc);//Color(0xFFefefef)
final kContactUsPageAppBarBkgColor= Color(0xFFcbc7bc);//Colors.grey.shade300
final kContactUsPageTextColor=Color(0xFF38463e);//Color(0xff275654)
final kContactUsPagePrimaryFontFamily='Lato';
final kContactUsPageTextFieldBkgColor=Color(0xFFe2ded7);//Colors.grey[200]
final kContactUsPageHintTextColor=Colors.grey[600];
final kContactUsPageTextFieldBorderColor= Color(0xFF38463e);//Color(0xff275654)
final kContactUsPageElevatedButtonBkgColor=Color(0xFF38463e);//Color(0xff275654)
final kContactUsPageElevatedButtonTextColor=Colors.white;

//OpeningAnimation Constants
final kOpeningAnimationBkgColor=Color(0xFFcbc7bc);
final kOpeningAnimationBumbleBeeIconColor = Color(0xFF27302b);//Color(0xff275654)

//Settings Page Constants
final kSettingsAppBarTextStyle = TextStyle(
    color: kAnnouncementScreenAppBarTextColor,
    fontWeight: FontWeight.bold,
    fontSize: 30,
    fontFamily: 'Lato');
final kSettingsUserInfoContainerDecoration = BoxDecoration(
  color: Color(0xFFc2baab), // Background color
  borderRadius: BorderRadius.circular(12), // Rounded corners
  boxShadow: [
    BoxShadow(
      color: Colors.black12, // Soft shadow
      blurRadius: 6,
      spreadRadius: 2,
    ),
  ],
);
final kSettingsTextStyle= TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    fontFamily: 'Lato',
    color: kAnnouncementScreenAppBarTextColor);
final kSettingsFeedbackContainerDecoration = InputDecoration(
  hintText:
  ' Got ideas? Got Feedback? Your thoughts fuel our innovation—let us hear them!',
  hintStyle: TextStyle(
    color: kContactUsPageHintTextColor,
    fontFamily: 'Lato',
    fontWeight: FontWeight.bold,
  ),
  filled: true,
  fillColor: kContactUsPageTextFieldBkgColor,
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(
        color: kContactUsPageTextFieldBorderColor, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(
        color: kContactUsPageTextFieldBorderColor, width: 2),
    borderRadius: BorderRadius.all(Radius.circular(12)),
  ),
);
final kSettingsElevatedButtonTextStyle = TextStyle(
    fontSize: 16,
    fontFamily: 'Lato',
    fontWeight: FontWeight.bold,
    color: kContactUsPageElevatedButtonTextColor);
final kSettingsManageMembersElevatedButtonDecoration = InputDecoration(
  hintText: 'Enter the exact name or gmail of the member',
  hintStyle: TextStyle(
      color: kAddTaskHintTextColor,
      fontFamily: 'Lato',
      fontWeight: FontWeight.bold),
  filled: true,
  fillColor: kAddTaskTextFieldBkgColor,
  enabledBorder: OutlineInputBorder(
    borderSide: BorderSide(
        color: kAddTaskTextFieldBorderColor, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
  focusedBorder: OutlineInputBorder(
    borderSide: BorderSide(
        color: kAddTaskTextFieldBorderColor, width: 2),
    borderRadius: BorderRadius.all(Radius.circular(20)),
  ),
);
final kSettingsCurrentMembersContainerTextStyle = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: kAnnouncementScreenAppBarTextColor,
  fontFamily: 'Lato',
);