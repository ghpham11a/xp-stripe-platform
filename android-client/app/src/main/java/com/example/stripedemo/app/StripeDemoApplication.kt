package com.example.stripedemo.app

import android.app.Application
import com.example.stripedemo.BuildConfig
import com.stripe.android.PaymentConfiguration
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class StripeDemoApplication : Application() {

    override fun onCreate() {
        super.onCreate()

        // Initialize Stripe SDK with publishable key
        PaymentConfiguration.init(
            applicationContext,
            BuildConfig.STRIPE_PUBLISHABLE_KEY
        )
    }
}
