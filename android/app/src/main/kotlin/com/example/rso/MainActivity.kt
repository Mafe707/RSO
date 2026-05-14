package com.example.rso

import android.os.Bundle
import android.view.animation.AnimationUtils
import android.widget.ImageView
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val animation = AnimationUtils.loadAnimation(
            this,
            R.anim.launch_scale
        )
    }
}