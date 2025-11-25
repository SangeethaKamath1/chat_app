
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatConfig {
  final Color primaryColor;
  final SharedPreferences prefs;
final String token;
final String conversationId;
final String userId;
final String username;
final Dio dioService;

  // final Color accentColor;
  // final Color backgroundColor;
  // final Color textColor;

  const ChatConfig({
    required this.primaryColor,
    required this.prefs,
    required this.token,
    required this.conversationId,
    required this.userId,
    required this.username,
    required this.dioService

    
    // required this.accentColor,
    // required this.backgroundColor,
    // required this.textColor,
  });
}