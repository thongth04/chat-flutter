import 'package:messeco/constants.dart';
import 'package:messeco/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:messeco/components/rounded_button.dart';

class WelcomeScreen extends StatefulWidget {
  static String id = 'welcome_screen';

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  AnimationController controller;
  Animation animation;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );

    animation = ColorTween(
      begin: kPrimaryColor,
      end: Colors.white,
    ).animate(controller);

    controller.forward();
    controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: animation.value,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Hero(
                  tag: 'logo',
                  child: Container(
                    child: Image.asset('images/logo.png'),
                    height: 80,
                  ),
                ),
                SizedBox(
                  width: 7,
                ),
                ColorizeAnimatedTextKit(
                  text: ['Messeco'],
                  colors: [
                    kSecondaryColor,
                    kColor2,
                    kColor1,
                    kPrimaryColor,
                  ],
                  textStyle: TextStyle(
                    fontSize: 60.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 30.0,
            ),
            RoundedButton(
              color: kPrimaryColor,
              textColor: kSecondaryColor,
              title: '➟',
              onPressed: () {
                //Go to log in screen.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(),
                  ),
                );
              },
              textSize: 40,
            ),
          ],
        ),
      ),
    );
  }
}
