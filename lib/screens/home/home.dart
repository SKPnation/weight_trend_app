import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
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
  FirebaseFirestore.instance.collection('weight');

  static const String signOut = 'Sign out';

  List<String> menuOptions = <String>[signOut];

  bool weightListLoaded = false;

  var data;
  var uuid = Uuid();

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
                  return PopupMenuItem(value: option, child: Text(option));
                }).toList();
              })
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        splashColor: Colors.green,
        onPressed: () async {
          _showModalBottomSheet(context, 'new', '', '', 0 );
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
          stream: weightRef.orderBy('timestamp', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              lastWeight = snapshot.data.docs[0].data()['weight'];
              return ListView.builder(
                reverse: false,
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  return _buildWeightWidget(index,
                      snapshot: snapshot.data.docs[index]);
                },
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
  void optionAction(String option) async {
    if (option == signOut) {
      await _auth.signOut();
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => SignInPage()),
              (route) => false);
      print('$signOut');
    }
  }

  int lastWeight = 0;

  ///Weight item widget
  Widget _buildWeightWidget(index,
      {loader = false, QueryDocumentSnapshot snapshot}) {
    String date, time;
    String weight;
    String type;
    String id;

    final timeFormat = DateFormat.Hm();
    final dateFormat = DateFormat('dd-MM-yyyy');

    if (snapshot != null) {
      data = snapshot.data();
      id = data['id'].toString();
      date = dateFormat
          .format(DateTime.fromMillisecondsSinceEpoch(data['timestamp'].toInt())
          .toLocal())
          .toString();
      weight = data['weight'].toString();
      type = data['trendType'];
      time = timeFormat
          .format(DateTime.fromMillisecondsSinceEpoch(data['timestamp'].toInt())
          .toLocal())
          .toString();
    }

    if (loader) {
      return Container(
        height: 80,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    ValueNotifier<double> dxPosition = ValueNotifier(0);

    //initial x-axis position when dragging starts
    double initialdxPosition = 0;
    //opened bool value to see whether the drag is opened or not
    bool opened = false;

    return Column(
      children: [
        SizedBox(
          height: 20,
        ),
        GestureDetector(
          onHorizontalDragStart: (details) {
            // SETTING THE INITIAL X-AXIS POSITION WHEN DRAG STARTS
            initialdxPosition = details.localPosition.dx;
          },
          onHorizontalDragUpdate: (details) {
            //CHECKING IF THE CHANGING VALUE OF X-AXIS IS GREATER THAN -150 (as it is been dragged to left side)
            //and initial dx positions is greater than current dx position (to know that it's dragged to left)
            if (dxPosition.value < 150 &&
                details.localPosition.dx < initialdxPosition) {
              print('still dragging');
              opened = false;
              //setting the difference between current and initial x-axis position during drag
              dxPosition.value = initialdxPosition - details.localPosition.dx;
            } else if (details.localPosition.dx < initialdxPosition) {
              //if the difference exceeds 150 then define it to 150 as maximum displacement
              //- because dragged to left
              print('drag threshold reached');
              opened = true;
              dxPosition.value = 150;
            } else if (opened) {
              //if opened i.e dragged out then close it on horizontal right drag even a little
              opened = false;
              dxPosition.value = 0;
            }
          },
          onHorizontalDragCancel: () {
            //on cancel set the displacement to original position
            opened = false;
            dxPosition.value = 0;
          },
          onTap: (){
            //opening the dissmissible Container directly to 150 px from right on double tap
            opened = true;
            dxPosition.value = 150;
          },
          onDoubleTap: () {
            //opening the dissmissible Container directly to 150 px from right on double tap
            opened = true;
            dxPosition.value = 150;
          },
          onLongPress: () {
            //opening the dissmissible Container directly to 150 px from right on long press
            opened = true;
            dxPosition.value = 150;
          },
          onHorizontalDragEnd: (details) {
            //checking if the difference is less than 150
            //to make sure that minimum 150 displacement is required
            //to keep the container dragged
            if (dxPosition.value < 150) {
              opened = false;
              //if not then set to initial position
              dxPosition.value = 0;
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              //------------------------
              // BACKGROUND BUTTON BEHIND THE DRAGGABLE WEIGHT ITEM
              //------------------------
              Align(
                alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      InkWell(
                        onTap: () {
                          _showModalBottomSheet(context, 'edit', weight, id, index);
                        },
                        child: Container(
                            margin: const EdgeInsets.only(right: 16),
                            height: 60,
                            width: 60,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.orange[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 24,
                            )
                        ),
                      ),
                      InkWell(
                        onTap: (){
                          _deleteNotification(index, id, context);
                        },
                        child: Container(
                            margin: const EdgeInsets.only(right: 10),
                            height: 60,
                            width: 60,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 24,
                            )
                        ),
                      )
                    ],
                  )
              ),
              ValueListenableBuilder(
                valueListenable: dxPosition,
                builder: (context, value, child) => AnimatedPositioned(
                  duration: Duration(milliseconds: 200),
                  curve: Curves.ease,
                  right: value,
                  child: Container(
                    width: displayWidth(context)*0.9,
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
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
        )
      ],
    );
  }

  //Display weight entry field
  void _showModalBottomSheet(BuildContext context, String option, String weight, String id, int index) {
    if(option == 'edit'){
      weightEntryTEC.text = weight;
    }else{
      weightEntryTEC.text = '';
    }
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10), topRight: Radius.circular(10))),
        backgroundColor: Colors.white,
        builder: (BuildContext context) {
          return Container(
            padding: EdgeInsets.all(displayWidth(context) * 0.08),
            height: 360,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your current weight',
                    style: TextStyle(
                        fontSize: displayWidth(context) * 0.048,
                        fontWeight: FontWeight.bold,
                        color: Colors.green)),
                SizedBox(height: displayHeight(context) * 0.04),
                TextFormField(
                    controller: weightEntryTEC,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Weight',
                      fillColor: Colors.transparent,
                      filled: true,
                      hintText: "in Kg",
                      hintStyle: TextStyle(
                          fontSize: displayWidth(context) / 25,
                          color: Colors.grey),
                      // If  you are using latest version of flutter then lable text and hint text shown like this
                      // if you r using flutter less then 1.20.* then maybe this is not working properly
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      //prefixIcon: CustomSurffixIcon(svgIcon: "assets/icons/Mail.svg"),
                    )),
                SizedBox(height: displayHeight(context) * 0.04),
                Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: displayHeight(context) * 0.06,
                      child: ElevatedButton(
                          onPressed: () async {
                            if (weightEntryTEC.text.isEmpty) {
                              Navigator.of(context).pop();
                              displaySnackbar('Field is empty', context);
                            }
                            else {
                              if (lastWeight <=
                                  int.parse(weightEntryTEC.text.toString())) {
                                option == 'edit'
                                    ? updateItemInDatabase('up', id)
                                    : saveToDatabase('up');
                              } else {
                                option == 'edit'
                                    ? updateItemInDatabase('down', id)
                                    : saveToDatabase('down');
                              }
                              weightEntryTEC.clear();
                            }
                          },
                          style: ElevatedButton.styleFrom(primary: Colors.green),
                          child: Text('Save',
                              style: TextStyle(
                                  fontSize: displayWidth(context) * 0.040))),
                    ))
              ],
            ),
          );
        });
  }

  void saveToDatabase(String trend) async {
    var subStr = uuid.v4();
    String id = subStr.substring(0, subStr.length - 10);

    await weightRef.add({
      'uid': _auth.currentUser.uid,
      'weight': int.parse(weightEntryTEC.text),
      'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
      'trendType': trend,
      'id': id,
    }).then((value) {
      Navigator.of(context).pop();
      displaySnackbar('Saved successfully!', context);
    });
  }

  void updateItemInDatabase(String trend, String id) async{
    await weightRef.doc(id).update({
      'weight': int.parse(weightEntryTEC.text),
      'timestamp': DateTime.now().toUtc().millisecondsSinceEpoch,
      'trendType': trend,
      'id': id
    }).then((value) {
      Navigator.of(context).pop();
      displaySnackbar('Edited successfully!', context);
    });
  }

  void _deleteNotification(int index, String id, BuildContext context) {
    weightRef.doc(id).delete().then((value) =>
        displaySnackbar('deleted successfully!', context));
  }
}