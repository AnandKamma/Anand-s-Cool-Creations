import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  final Color? color;
  final String? buttonTitle;
  final VoidCallback? onpressed;

  const RoundedButton({
    this.color,
    this.buttonTitle,
    this.onpressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(30), // Rounded corners
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30), // Rounded corners
        ),
        child: InkWell(
          onTap: onpressed,
          splashColor: Colors.white.withOpacity(0.3), // Splash color on press
          highlightColor: Colors.white.withOpacity(0.2), // Highlight color on press
          borderRadius: BorderRadius.circular(30), // Ensures rounded splash
          child: Container(
            alignment: Alignment.center, // Centers the text
            height: 42.0, // Button height
            width: 200.0, // Button width
            child: Text(
              buttonTitle ?? '',
              style: TextStyle(
                fontSize: 20,
                color: Colors.white
              )
            ),
          ),
        ),
      ),
    );
  }
}
