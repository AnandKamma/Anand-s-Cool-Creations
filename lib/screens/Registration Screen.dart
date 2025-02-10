
import 'package:flutter/material.dart';
import 'package:lock/components/Animations.dart';
import 'package:lock/components/LoginOptionButton.dart';
import 'package:lock/components/RoundedButton.dart';
import 'package:lock/components/auth_service.dart';
import 'package:lock/constonants.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:lock/screens/Home%20Screen.dart';
import 'package:lock/screens/Login%20Screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class Registrationscreen extends StatefulWidget {
  static const String id = 'registration_screen';
  final AuthService authService=AuthService();

   Registrationscreen({super.key});

  @override
  State<Registrationscreen> createState() => _RegistrationscreenState();
}

class _RegistrationscreenState extends State<Registrationscreen> {
  AuthService authService=AuthService();
  final authFirebase = FirebaseAuth.instance;
  bool showSpinner = false;
  String? email;
  String? passoword;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kRegScafColor,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 34),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ColoriseText(text: 'Create Account'),
              SizedBox(
                height: 30,
              ),
              TextField(
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  email = value;
                },
                decoration: kLogandRegTextFieldDecoration.copyWith(
                    hintText: kReghintTextEmail),
              ),
              SizedBox(
                height: 15,
              ),
              TextField(
                obscureText: true,
                keyboardType: TextInputType.emailAddress,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  passoword = value;
                },
                decoration: kLogandRegTextFieldDecoration.copyWith(
                    hintText: kReghintTextPassword),
              ),
              SizedBox(
                height: 15,
              ),
              RoundedButton(
                  color: Colors.black26,
                  buttonTitle: 'Register',
                  onpressed: () async {
                    setState(() {
                      showSpinner = true;
                    });
                    try {
                      final newUser =
                          await authFirebase.createUserWithEmailAndPassword(
                              email: email!, password: passoword!);
                      if (newUser != null) {
                        Navigator.pushNamed(context, HomeScreen.id);
                      }
                    } catch (e) {
                      print(e);
                      setState(() {
                        showSpinner = false;
                      });
                    }
                  }),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 15),
                child: Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Text('or continue with')),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: LoginOptions(
                      iconbgColor: Colors.grey,
                      onPress: () async {
                        setState(() {
                          showSpinner = true;
                        });
                        try {
                          UserCredential? userCredential =
                          await authService.loginWithGoogle(context);

                          if (userCredential != null) {
                            Navigator.pushNamed(context, HomeScreen.id);
                          } else {
                            print('Google Sign-In Falied or Cancelled');
                          }
                        } catch (e) {
                          print('Error during sign in with Google: $e');
                        } finally {
                          setState(() {
                            showSpinner = false;
                          });
                        }
                      },
                      cardChild: IconContent(
                          icon: FontAwesomeIcons.google,

                          color: Colors.grey),
                    ),
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: LoginOptions(
                      iconbgColor: Colors.grey,
                      onPress: () async {
                        setState(() {
                          showSpinner = true;
                        });
                        try {
                          UserCredential? userCredential =
                              await authService.loginWithApple(context);
                          if (userCredential!= null) {
                            Navigator.pushNamed(context, HomeScreen.id);
                            print('wohooo');
                          } else {
                            print('Apple Sign-In Falied or Cancelled');
                          }
                        } catch (e) {
                          print('Error during sign in with Apple: $e');
                        } finally {
                          setState(() {
                            showSpinner = false;
                          });
                        }
                      },
                      cardChild: IconContent(
                          icon: FontAwesomeIcons.apple,

                          color: Colors.grey),
                    ),
                  ),
                ],
              ),
              NavigatetoRegorLog(
                intro: 'Already Have an account? ',
                whereto: 'Log In',
                ontap: () {
                  Navigator.of(context)
                      .push(FadePageRoute(routeName: LoginScreen.id));
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
