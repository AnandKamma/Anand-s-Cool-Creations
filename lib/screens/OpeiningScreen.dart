import 'package:flutter/material.dart';
import 'package:lock/constonants.dart';
import 'package:lock/screens/Login Screen.dart';

import '../components/Animations.dart';
class OpeningAnimations extends StatefulWidget {
  static const String id = 'openingAnimation_screen';
  const OpeningAnimations({super.key});

  @override
  State<OpeningAnimations> createState() => _OpeningAnimationsState();
}

class _OpeningAnimationsState extends State<OpeningAnimations>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _radiusAnimation;

  @override
  void initState() {
    super.initState();

    //animation controller
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..forward();

    //rotatation Animation
    _rotationAnimation = Tween(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    //radius animation, it basically turn it from a circle to square(back and forth)
    _radiusAnimation = Tween(begin: 450.0, end: 10.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addListener(() {
      setState(() {});
    });
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    Future.delayed(Duration(milliseconds: 2500),(){
      Navigator.of(context).pushReplacement(
        FadePageRoute(routeName: LoginScreen.id),
      );
    });
  }
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kOpeningAnimationBkgColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            //stacks widgets on too pf each other
            child: Stack(
              alignment: Alignment.center,
              children: [
                //biggest comes on top
                Transform.rotate(
                  angle: _rotationAnimation.value,
                  child: Container(
                    height: 240,
                    width: 240,
                    decoration: BoxDecoration(
                        color: Color(0xFF27302b),
                        borderRadius: BorderRadius.circular(_radiusAnimation.value),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: Offset(66, -6),
                              blurRadius: 10

                          ),
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              offset: Offset(6, 6),
                              blurRadius: 10
                          )
                        ]
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAnimation.value+0.2,
                  child: Container(
                    height: 220,
                    width: 220,
                    decoration: BoxDecoration(
                        color: Color(0xff2f3b34),
                        borderRadius: BorderRadius.circular(_radiusAnimation.value)
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAnimation.value+0.4,
                  child: Container(
                    height: 200,
                    width: 200,
                    decoration: BoxDecoration(
                        color: Color(0xff38463e),
                        borderRadius: BorderRadius.circular(_radiusAnimation.value)
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAnimation.value+0.6,
                  child: Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                        color: Color(0xff415148),
                        borderRadius: BorderRadius.circular(_radiusAnimation.value)
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: _rotationAnimation.value+0.8,
                  child: Container(
                    height: 160,
                    width: 160,
                    decoration: BoxDecoration(
                        color: Color(0xff495c51),
                        borderRadius: BorderRadius.circular(_radiusAnimation.value)
                    ),
                  ),
                ),
                Container(
                  height: 160,
                  width: 160,
                  decoration: BoxDecoration(
                      color: kOpeningAnimationBkgColor,
                      borderRadius: BorderRadius.circular(300)
                  ),
                  child: Align(
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          SizedBox(
                            height: 30,
                          ),
                          Icon(kBumbleBeeLogo,size: 130,color: kOpeningAnimationBumbleBeeIconColor,),

                        ],
                      )),
                )
              ],
            ),
          ),
          SizedBox(height: 150,),
          Text('From',style: TextStyle(fontSize: 20, fontFamily:'Pacifico'),),
          Text('Ashok Anand',style: TextStyle(fontFamily: 'DancingScript',fontSize: 50),)
        ],
      ),
    );
  }
}
