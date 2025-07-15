import 'package:flutter/material.dart';
import 'package:lock/constonants.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const CustomFloatingActionButton({required this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60, // Custom height
      width: 60,  // Custom width
      decoration: BoxDecoration(
        color: kTextAndIconColor,
        borderRadius: BorderRadius.circular(12), // ✅ Rounded rectangle
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onPressed,
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
}
