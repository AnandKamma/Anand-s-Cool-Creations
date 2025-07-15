import 'package:flutter/material.dart';
import 'package:lock/constonants.dart';

class Rough extends StatefulWidget {
  static const String id = 'Rough';
  const Rough({super.key});

  @override
  State<Rough> createState() => _RoughState();
}

class _RoughState extends State<Rough> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFede4d7),
      body: Center(child: Icon(kBumbleBeeLogo,color:Color(0xFF27302b),size: 400,)),
    );
  }
}
