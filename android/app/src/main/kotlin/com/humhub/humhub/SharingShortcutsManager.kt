package com.humhub.app

import android.content.Context
import android.content.Intent
import androidx.core.app.Person
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import java.util.ArrayList
import java.util.HashSet

/**
 * Provides the Sharing Shortcuts items to the system.
 * <p>
 * Use the ShortcutManagerCompat to make it work on older Android versions
 * without any extra work needed.
 * <p>
 * Interactions with the ShortcutManager API can happen on any thread.
 */
class SharingShortcutsManager {

    /**
     * Category name defined in res/xml/shortcuts.xml that accepts data of type text/plain
     * and will trigger [SendMessageActivity]
     */
    val categoryTextShareTarget = "com.humhub.app.category.IMAGE_SHARE_TARGET"

    /**
     * Define maximum number of shortcuts.
     * Don't add more than [ShortcutManagerCompat.getMaxShortcutCountPerActivity].
     */
    private val maxShortcuts = 4

    /**
     * Publish the list of dynamic shortcuts that will be used in Direct Share.
     * <p>
     * For each shortcut, we specify the categories that it will be associated to
     * the intent that will trigger when opened as a static launcher shortcut,
     * and the Shortcut ID between other things.
     * <p>
     * The Shortcut ID that we specify in the [ShortcutInfoCompat.Builder] constructor will
     * be received in the intent as [Intent.EXTRA_SHORTCUT_ID].
     * <p>
     * In this code sample, this method is completely static. We are always setting the same sharing
     * shortcuts. In a real-world example, we would replace existing shortcuts depending on
     * how the user interacts with the app as often as we want to.
     */
    fun pushDirectShareTargets(context: Context) {
        val shortcuts = ArrayList<ShortcutInfoCompat>()

        // Category that our sharing shortcuts will be assigned to
        val contactCategories = setOf(categoryTextShareTarget)

        // Adding maximum number of shortcuts to the list
        for (id in 0 until maxShortcuts) {
            val contact = Contact.byId(id)

            // Item that will be sent if the shortcut is opened as a static launcher shortcut
            val staticLauncherShortcutIntent = Intent(Intent.ACTION_DEFAULT)

            // Creates a new Sharing Shortcut and adds it to the list
            // The id passed in the constructor will become EXTRA_SHORTCUT_ID in the received Intent
            shortcuts.add(
                ShortcutInfoCompat.Builder(context, Integer.toString(id))
                    .setShortLabel(contact.name)
                    // Icon that will be displayed in the share target
                    .setIcon(IconCompat.createWithResource(context, contact.icon))
                    .setIntent(staticLauncherShortcutIntent)
                    // Make this sharing shortcut cached by the system
                    // Even if it is unpublished, it can still appear on the sharesheet
                    .setLongLived(true)
                    .setCategories(contactCategories)
                    // Person objects are used to give better suggestions
                    .setPerson(
                        Person.Builder()
                            .setName(contact.name)
                            .build()
                    )
                    .build()
            )
        }

        //ShortcutManagerCompat.addDynamicShortcuts(context, shortcuts)
    }

    /**
     * Remove all dynamic shortcuts
     */
    fun removeAllDirectShareTargets(context: Context) {
        ShortcutManagerCompat.removeAllDynamicShortcuts(context)
    }
}