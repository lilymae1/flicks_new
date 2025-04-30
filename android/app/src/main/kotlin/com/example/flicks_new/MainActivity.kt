package com.example.flicks_new  // Ensure this matches the actual package name in your app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import com.google.firebase.FirebaseApp  // Import Firebase

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Firebase
        FirebaseApp.initializeApp(this)  // This initializes Firebase
        
        // Other initialization code (if necessary)
    }
}

