import 'package:flash_chat/screens/login_screen.dart';
import 'registration_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/components/rounded_button.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'success_screen.dart';

class VerifyScreen extends StatefulWidget {
  static String id = 'verify_screen';

  @override
  _VerifyScreenState createState() => _VerifyScreenState();
}

class _VerifyScreenState extends State<VerifyScreen> {
  final _auth = FirebaseAuth.instance;
  String email;
  String password;
  bool showSpinner = false;
  String status =
      'We have sent you a verify email. \nPlease check it before hit the button.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    height: 200.0,
                    child: Image.asset('images/logo.png'),
                  ),
                ),
              ),
              SizedBox(
                height: 48.0,
              ),
              StatusInfo(status: status),
              SizedBox(
                height: 24.0,
              ),
              RoundedButton(
                textColor: Colors.limeAccent,
                color: Colors.lightBlue,
                title: 'Done',
                onPressed: () async {
                  setState(() {
                    showSpinner = true;
                  });
                  try {
                    User currentUser = _auth.currentUser;
                    if (currentUser.emailVerified) {
                      Navigator.pushNamed(context, SuccessScreen.id);
                      // } else if (currentUser.emailVerified == false) {
                      //   currentUser.delete();
                      //   status = 'There is something wrong.\nPlease try again.';
                      //   Navigator.pop(context, status);
                      // }
                      setState(() {
                        showSpinner = false;
                      });
                    }
                  } catch (e) {
                    print(e);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StatusInfo extends StatelessWidget {
  StatusInfo({this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Text(
          status,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.green,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
