import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CallKitBridge {
  static const MethodChannel _ch = MethodChannel('call_intent');

  static Future<void> endCall(String callId) async {
    debugPrint("end call from bridge:${callId}");
    try {
      await _ch.invokeMethod("endCall", {"call_id": callId});
    } catch (_) {}
  }

  static Future<void> dismissIncoming(String callId) async {
    if (!Platform.isIOS) return;
    debugPrint("📲 [iOS] dismissIncoming(callId=$callId)");
    try {
      await _ch.invokeMethod("dismissIncoming", {"call_id": callId});
      debugPrint("✅ [iOS] dismissIncoming sent to native");
    } catch (e) {
      debugPrint("❌ [iOS] dismissIncoming failed: $e");
    }
  }
  static Future<void> acceptCallFromApp(String callId) async {
    try {
      debugPrint("📤 [CallKitEvents] acceptCallFromApp(callId=$callId)");
      await _ch.invokeMethod("acceptCallFromApp", {"call_id": callId});
    } catch (e, st) {
      debugPrint("❌ acceptCallFromApp failed: $e");
      debugPrint("$st");
    }
  }

  // Optional: listen iOS -> Flutter events (you already invoke methods)
}
