package com.example.stripedemo.core.datastore

import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AppPreferences @Inject constructor(
    private val dataStore: DataStore<Preferences>
) {
    private companion object {
        val SELECTED_ACCOUNT_ID_KEY = stringPreferencesKey("selected_account_id")
    }

    val selectedAccountId: Flow<String> = dataStore.data.map { prefs ->
        prefs[SELECTED_ACCOUNT_ID_KEY] ?: ""
    }

    suspend fun setSelectedAccountId(accountId: String) {
        dataStore.edit { prefs ->
            prefs[SELECTED_ACCOUNT_ID_KEY] = accountId
        }
    }

    suspend fun clearSelectedAccountId() {
        dataStore.edit { prefs ->
            prefs.remove(SELECTED_ACCOUNT_ID_KEY)
        }
    }
}
