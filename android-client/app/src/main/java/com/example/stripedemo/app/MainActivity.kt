package com.example.stripedemo.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.navigation.NavHostController
import androidx.navigation.compose.rememberNavController
import com.example.stripedemo.core.navigation.AppNavigation
import com.example.stripedemo.shared.theme.StripeDemoTheme
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    private var navController: NavHostController? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            StripeDemoTheme {
                val navController = rememberNavController().also {
                    this.navController = it
                }
                AppNavigation(navController = navController)
            }
        }
    }
}