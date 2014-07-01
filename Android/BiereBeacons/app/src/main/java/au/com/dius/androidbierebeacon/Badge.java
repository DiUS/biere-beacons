package au.com.dius.androidbierebeacon;

import android.content.Context;
import android.content.SharedPreferences;
import android.preference.PreferenceManager;

import com.estimote.sdk.Region;

import java.util.Locale;
import java.util.Timer;
import java.util.TimerTask;

public class Badge {

    private Region region;
    private int resource;
    private int spotted;

    private boolean unlocked;

    public Badge(Region region, int resource) {
        this.unlocked = false;
        this.spotted = 0;
        this.region = region;
        this.resource = resource;
    }

    public boolean isUnlocked() {
        return this.unlocked;
    }

    public boolean unlock() {
        this.unlocked = true;
        return this.unlocked;
    }

    public int resource() {
        return this.resource;
    }

    public Region region() { return this.region; }

    public int spottedCount() { return this.spotted; }

    public void spotted() {
        this.spotted++;
    }

    public void save(Context context) {
        SharedPreferences.Editor prefEditor = PreferenceManager.getDefaultSharedPreferences(context).edit();
        if (this.unlocked) {
            prefEditor.putBoolean(region.toString(), this.unlocked);
        }

        prefEditor.commit();
    }

    public void load(Context context) {
        SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(context);
        this.unlocked = pref.getBoolean(region.toString(), false);

    }
}
