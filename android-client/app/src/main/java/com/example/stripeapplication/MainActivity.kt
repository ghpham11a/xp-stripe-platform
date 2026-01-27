package com.example.stripeapplication

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.example.stripeapplication.ui.screens.MainScreen
import com.example.stripeapplication.ui.theme.StripeApplicationTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            StripeApplicationTheme {
                MainScreen()
            }
        }
    }
}
