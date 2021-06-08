import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

displaySnackbar(String message, BuildContext context) {
  try {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  } catch (e) {
    debugPrint(e);
  }
}