package com.example.chat_app;

import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;

public class MainActivity extends FlutterActivity {
     private AudioHandler audioHandler;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        
        // Initialize audio handler
        audioHandler = new AudioHandler(this, flutterEngine);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        // Clean up audio handler
        if (audioHandler != null) {
            audioHandler.dispose();
        }
    }
}