import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'home_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:messeco/constants.dart';

class LoginScreen extends StatefulWidget {
  static String id = 'login_screen';

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  User currentUser;
  SharedPreferences prefs;
  bool isUserSignedIn = false;
  bool userSignedIn;

  bool isLoggedIn = false;
  bool showSpinner = false;

  String email;
  String password;

  String status = ' ';

  @override
  void initState() {
    super.initState();
    isSignedIn();

    // initApp();
  }

  void isSignedIn() async {
    this.setState(() {
      showSpinner = true;
    });

    prefs = await SharedPreferences.getInstance();

    isLoggedIn = await _googleSignIn.isSignedIn();
    if (isLoggedIn) {}

    this.setState(() {
      showSpinner = false;
    });
  }

  // void initApp() async {
  //   FirebaseApp defaultApp = await Firebase.initializeApp();
  //   _auth = FirebaseAuth.instanceFor(app: defaultApp);
  //   //immediately check whether the user is signed in
  //   // checkIfUserIsSignedIn();
  // }

  // Future<User> _handleLogIn() async {
  //   User user;
  //
  //   //flag to check whether we're log in already
  //   bool isSignedIn = await _googleSignIn.isSignedIn();
  //
  //   setState(() {
  //     isUserSignedIn = userSignedIn;
  //   });
  //
  //   if (isSignedIn) {
  //     //if so, return the current user
  //     user = _auth.currentUser;
  //   } else {
  //     final GoogleSignInAccount googleUser = await _googleSignIn.signIn();
  //     final GoogleSignInAuthentication googleAuth =
  //         await googleUser.authentication;
  //
  //     //get the credentials to access/ id token
  //     //to sign in via Firebase Authentication
  //     final AuthCredential credential = GoogleAuthProvider.credential(
  //       accessToken: googleAuth.accessToken,
  //       idToken: googleAuth.idToken,
  //     );
  //
  //     user = (await _auth.signInWithCredential(credential)).user;
  //     userSignedIn = await _googleSignIn.isSignedIn();
  //     setState(() {
  //       isUserSignedIn = userSignedIn;
  //     });
  //   }
  //
  //   return user;
  // }

  Future handleSignIn() async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() {
      showSpinner = true;
    });

    //google sign in
    GoogleSignInAccount googleAcc = await _googleSignIn.signIn();

    //google authentication (xác thực)
    GoogleSignInAuthentication googleAuth = await googleAcc.authentication;

    //google credential (chứng chỉ)
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    //firebase user by sign in with credential
    User fbaseUser = (await _auth.signInWithCredential(credential)).user;

    //check is already sign up
    if (fbaseUser != null) {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: fbaseUser.uid)
          .get();
      final List<DocumentSnapshot> documents = result.docs;

      //update data to server if new user
      if (documents.length == 0) {
        FirebaseFirestore.instance.collection('users').doc(fbaseUser.uid).set({
          'nickname': fbaseUser.displayName,
          'photoUrl': fbaseUser.photoURL,
          'id': fbaseUser.uid,
          'createdAt': DateTime.now().microsecondsSinceEpoch.toString(),
          'chattingWith': null
        });

        //write data to local
        currentUser = fbaseUser;
        await prefs.setString('id', currentUser.uid);
        await prefs.setString('nickname', currentUser.displayName);
        await prefs.setString('photoUrl', currentUser.photoURL);
      } else {
        //write data to local
        await prefs.setString('id', documents[0].data()['id']);
        await prefs.setString('nickname', documents[0].data()['nickname']);
        await prefs.setString('photoUrl', documents[0].data()['photoUrl']);
        await prefs.setString('aboutMe', documents[0].data()['aboutMe']);
      }

      Fluttertoast.showToast(msg: "Sign in success");
      this.setState(() {
        showSpinner = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(),
        ),
      );
    } else {
      Fluttertoast.showToast(msg: "Sign in fail");
      this.setState(() {
        showSpinner = false;
      });
    }
  }

  // void onGoogleSignIn(BuildContext context) async {
  //   User user = await _handleLogIn();
  //   var userSignedIn = Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder: (context) => UserScreen(
  //         user: user,
  //         googleSignIn: _googleSignIn,
  //       ),
  //     ),
  //   );
  //
  //   setState(() {
  //     isUserSignedIn = userSignedIn == null ? true : false;
  //   });
  // }

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
              FlatButton(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                onPressed: () {
                  handleSignIn();
                },
                color: kPrimaryColor,
                // onGoogleSignIn(context);
                child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_circle,
                        color: kColor2,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Login with Google',
                        style: TextStyle(
                          color: kColor2,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                child: Text(
                  status,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.pink,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
