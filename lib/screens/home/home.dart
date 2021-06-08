import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:weight_trend_app/models/weight.dart';
import 'package:weight_trend_app/screens/authentication/signIn.dart';
import 'package:weight_trend_app/utils/size_helpers.dart';
import 'package:weight_trend_app/utils/snackbar.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  TextEditingController weightEntryTEC = new TextEditingController();

  FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference weightRef =
  FirebaseFirestore
      .instance
      .collection('weight');

  static const String signOut = 'Sign out';

  List<String> menuOptions = <String>[signOut];

  bool weightListLoaded = false;

  var data;

  ///list containing the weights from the database
  List<WeightModel> weight = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(
        backgroundColor: Colors.green,
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        title: Text('Weight Trend'),
        actions: [
          PopupMenuButton<String>(
              onSelected: optionAction,
              itemBuilder: (BuildContext context) {
                return menuOptions.map((String option) {
                  return PopupMenuItem(
                      value: option, child: Text(option));
                }).toList();
              })
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        splashColor: Colors.green,
        onPressed: () async{
          _showModalBottomSheet(context);
        },
        child: Center(
          child: Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder(
          stream: weightRef
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot){
            if(snapshot.hasData){
              return ListView.builder(
                reverse: false,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) =>
                      _buildWeightWidget(index,
                          snapshot: snapshot.data.docs[index]),
              );
            } else {
              return Center(
                child: CircularProgressIndicator(
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  ///menu option method
  void optionAction(String option) async{
    if (option == signOut) {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  SignInPage()
          ), (route) => false
      );
      print('$signOut');
    }
  }

  var weightArray = [];

  ///Weight item widget
  Widget _buildWeightWidget(index,
  {loader = false, QueryDocumentSnapshot snapshot}) {
    String date, time;
    String weight;
    String type;

    final timeFormat = DateFormat.Hm();
    final dateFormat = DateFormat('dd-MM-yyyy');

    if (snapshot != null) {
      weightArray.add(snapshot.data()['weight']);
      data = snapshot.data();
      date = dateFormat.format(DateTime.fromMillisecondsSinceEpoch(data['timestamp'].toInt())
          .toLocal()).toString();
      weight = data['weight'].toString();
      type = data['trendType'];
      time = timeFormat.format(DateTime.fromMillisecondsSinceEpoch(data['timestamp'].toInt()).toLocal()).toString();
    }

    if (loader) {
      return Container(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return GestureDetector(
      onTap: (){
        displaySnackbar('Double tap or long press for other options', context);
      },
      onDoubleTap: (){
        //..
      },
      onLongPress: (){
        //..
      },
      child: Container(
        margin: EdgeInsets.all(8),
        height: displayHeight(context)*0.1,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white
        ),
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                [
                  Text('$weight''kg',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 24,
                      fontWeight: FontWeight.bold
                    ),),
                  Icon(type == 'up'
                      ? Icons.trending_up
                      : Icons.trending_down,
                      color: Colors.blue,
                  size: 36,)
                ]
            ),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children:
                [
                  Text(time),
                  Text(date)
                ]
            )
          ],
        ),
      ),
    );
  }

  //Display weight entry field
  void _showModalBottomSheet(BuildContext context)
  {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10),topRight: Radius.circular(10) )),
        backgroundColor: Colors.white,
        builder: (BuildContext context){
          return Container (
            padding: EdgeInsets.all(displayWidth(context)*0.08),
            height: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your current weight',
                    style: TextStyle(
                        fontSize: displayWidth(context)*0.048,
                        fontWeight: FontWeight.bold,
                        color: Colors.green
                    )),
                SizedBox(height: displayHeight(context)*0.04),
                TextFormField(
                    controller: weightEntryTEC,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly
                    ],
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      fillColor: Colors.transparent,
                      filled: true,
                      hintText: "in Kg",
                      hintStyle:
                      TextStyle(fontSize: displayWidth(context) / 25, color: Colors.grey),
                      // If  you are using latest version of flutter then lable text and hint text shown like this
                      // if you r using flutter less then 1.20.* then maybe this is not working properly
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      //prefixIcon: CustomSurffixIcon(svgIcon: "assets/icons/Mail.svg"),
                    )),
                SizedBox(height: displayHeight(context)*0.04),
                Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: displayHeight(context)*0.06,
                      child: ElevatedButton(
                          onPressed: () async{
                            if(weightEntryTEC.text.isEmpty){
                              await Navigator.of(context).pop();
                              displaySnackbar('Field is empty', context);
                            } else {
                              if(data['weight'] !=null)
                              {
                                if(weightArray[weightArray.length-1] < int.parse(weightEntryTEC.text.toString()) ||
                                    weightArray[weightArray.length-1] == int.parse(weightEntryTEC.text.toString()))
                                {
                                  saveToDatabase('up');
                                } else {
                                  saveToDatabase('down');
                                }
                              } else {
                                saveToDatabase('up');
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              primary: Colors.green),
                          child: Text('Save', style:
                          TextStyle(fontSize: displayWidth(context)*0.040))),
                    )
                )
              ],),
          );
        }
    );
  }

  void saveToDatabase(String trend) async{
    await weightRef.add({
      'uid': _auth.currentUser.uid,
      'weight': weightEntryTEC.text,
      'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
      'trendType': trend
    }).then((value){
      Navigator.of(context).pop();
      displaySnackbar('Saved successfully!', context);
    });
  }
}
