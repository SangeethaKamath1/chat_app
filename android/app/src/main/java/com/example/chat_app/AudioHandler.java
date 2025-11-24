package com.example.chat_app;

import android.content.Context;
import android.media.AudioManager;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.MethodCall;

public class AudioHandler implements MethodCallHandler {
    private final MethodChannel channel;
    private AudioManager audioManager;
    private Context context;

    private static final String CHANNEL = "audio_channel";

    public AudioHandler(Context context, FlutterEngine flutterEngine) {
        this.context = context;
        this.audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
        
        channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL);
        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {
            case "setSpeakerphoneOn":
                boolean on = (Boolean) call.arguments;
                setSpeakerphone(on, result);
                break;
            default:
                result.notImplemented();
                break;
        }
    }

    private void setSpeakerphone(boolean on, Result result) {
        try {
            if (audioManager == null) {
                result.error("AUDIO_ERROR", "AudioManager not available", null);
                return;
            }

            // Set speakerphone mode
            audioManager.setSpeakerphoneOn(on);

            // Set appropriate audio mode
            if (on) {
                // Speaker mode - use MODE_IN_COMMUNICATION for VoIP
                audioManager.setMode(AudioManager.MODE_IN_COMMUNICATION);
                // Disable Bluetooth SCO when using speaker
                audioManager.setBluetoothScoOn(false);
                audioManager.stopBluetoothSco();
            } else {
                // Earpiece mode
                audioManager.setMode(AudioManager.MODE_IN_CALL);
            }

            result.success(true);

        } catch (Exception e) {
            result.error("AUDIO_ERROR", "Failed to set speakerphone: " + e.getMessage(), null);
        }
    }

    // Optional: Method to check current speakerphone state
    public boolean isSpeakerphoneOn() {
        if (audioManager != null) {
            return audioManager.isSpeakerphoneOn();
        }
        return false;
    }

    // Optional: Clean up method
    public void dispose() {
        if (channel != null) {
            channel.setMethodCallHandler(null);
        }
    }
}