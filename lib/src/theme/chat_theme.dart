
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatConfig {
  final Color primaryColor;
  final SharedPreferences prefs;
final dynamic constant;
  // final Color accentColor;
  // final Color backgroundColor;
  // final Color textColor;

  const ChatConfig({
    required this.primaryColor,
    required this.prefs,
    required this.constant
    // required this.accentColor,
    // required this.backgroundColor,
    // required this.textColor,
  });
}