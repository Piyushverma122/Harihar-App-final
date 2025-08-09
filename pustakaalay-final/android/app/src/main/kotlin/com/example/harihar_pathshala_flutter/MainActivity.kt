package com.example.harihar_pathshala_flutter

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Disable app launch animation
        overridePendingTransition(0, 0)
    }
}
