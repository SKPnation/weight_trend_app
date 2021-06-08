import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:weight_trend_app/screens/authentication/components/auth.dart';
import 'package:weight_trend_app/screens/home/home.dart';
import 'package:weight_trend_app/utils/size_helpers.dart';

class SignInPage extends StatefulWidget {
  @override
  _SignInPageState createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {

  final AuthService _auth = AuthService();
  dynamic result;

  @override
  void initState() {
    super.initState();

    checkAuthState();
  }

  checkAuthState() async{
    if(result != null) {
      Navigator.push(context, MaterialPageRoute(
          builder: (context) => HomePage()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Align(
            alignment: Alignment.center,
            child: Column(
              children: [
                SizedBox(height: displayHeight(context)*0.08,),
                Image.asset(
                  'assets/images/weight_trend_img.png',
                  scale: 0.8,
                ),
                SizedBox(height: displayHeight(context)*0.06),
                Text('Weight Trend', style:
                TextStyle(
                  color: Colors.green[800],
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),),
                SizedBox(height: displayHeight(context)*0.2),
                InkWell(
                  onTap: () async{
                    result = await _auth.signInAnon();
                    if(result == null){
                      print('error signing in');
                    } else {
                      print('signed in');
                      Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  HomePage()
                          ), (route) => false
                      );
                      print(result);
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: displayWidth(context)*0.3,
                    height: displayHeight(context)*0.05,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                            colors: <Color>[Colors.green[900], Colors.green]
                        )
                    ),
                    child: Text('Sign In',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18
                      ),),
                  ),
                )
              ],
            ),
          ),
        ));
  }
}

