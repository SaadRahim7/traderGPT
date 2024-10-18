import 'package:another_flushbar/flushbar.dart';
import 'package:another_flushbar/flushbar_route.dart';
import 'package:flutter/material.dart';

class FlushBar {
  static flushbarmessagered({
    required String message,
    required context,
    double? width,
  }) {
    showFlushbar(
        context: context,
        flushbar: Flushbar(
          maxWidth: width,
          forwardAnimationCurve: Curves.decelerate,
          flushbarStyle: FlushbarStyle.FLOATING,
          flushbarPosition: FlushbarPosition.BOTTOM,
          margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          padding: EdgeInsets.all(15),
          message: message,
          positionOffset: 8,
          borderRadius: BorderRadius.circular(8),
          // backgroundColor: Colors.red,
          titleColor: Colors.white,
          duration: Duration(seconds: 2),
          icon: Icon(Icons.error, color: Colors.white),
        )..show(context));
  }

  static flushbarmessagegreen({
    required String message,
    required BuildContext context,
    double? width,
  }) {
    showFlushbar(
      context: context,
      flushbar: Flushbar(
        forwardAnimationCurve: Curves.decelerate,
        flushbarStyle: FlushbarStyle.FLOATING,
        flushbarPosition: FlushbarPosition.BOTTOM,
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        padding: EdgeInsets.all(15),
        message: message,
        positionOffset: 8,
        borderRadius: BorderRadius.circular(8),
        // backgroundColor: MyColor.darkblue,
        titleColor: Colors.white,
        duration: Duration(seconds: 2),
        icon: Icon(Icons.check_circle, color: Colors.white),
        maxWidth: width, // Set the custom width
      )..show(context),
    );
  }
}