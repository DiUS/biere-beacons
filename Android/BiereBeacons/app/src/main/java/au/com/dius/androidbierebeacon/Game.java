package au.com.dius.androidbierebeacon;

import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.IBinder;
import android.widget.Toast;

import com.estimote.sdk.Beacon;
import com.estimote.sdk.Utils;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by lincoln on 27/06/2014.
 */

public class Game {

    private BroadcastReceiver mBroadcastReceiver;
    private List<Badge> badgeList;
    private Toast mGameToast;

    public Game(Context context, Intent intent) {

        mBroadcastReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                Game.this.onReceived(context, intent);
            }
        };
    }

    public void onReceived(Context context, Intent intent) {
        ArrayList<Beacon> beacons = intent.getParcelableArrayListExtra(BeaconMonitorService.BEACONS_INTENT);

        if(beacons.isEmpty()) {
            return;
        }
/*
        // get first beacon - assumes it is the closest (according to estimote sdk)
        Badge badge = AwardsActivity.this.getBeaconBadge(beacons.get(0));
        if(badge != null && !badge.isUnlocked()) {

            if(Utils.computeProximity(beacons.get(0)) == Utils.Proximity.NEAR ||
                    Utils.computeProximity(beacons.get(0)) == Utils.Proximity.FAR ||
                    Utils.computeProximity(beacons.get(0)) == Utils.Proximity.UNKNOWN ) {
                mGameToast.cancel();
                mGameToast = Toast.makeText(AwardsActivity.this, "Ingredient Spotted", TOAST_LENGTH);
                mGameToast.show();
            }
            else {
                mGameToast.cancel();
                mGameToast = Toast.makeText(AwardsActivity.this, "Gathering Ingredient", TOAST_LENGTH);
                mGameToast.show();

                badge.spotted();

                if (badge.spottedCount() > 5) {
                    badge.unlock();
                    badge.save(AwardsActivity.this);
                    AwardsActivity.this.badgeArrayAdapter.notifyDataSetChanged();

                    // check if all badges are unlocked
                    for(int i = 0; i < AwardsActivity.this.badgeArrayAdapter.getCount(); i++) {
                        Badge b = AwardsActivity.this.badgeArrayAdapter.getItem(i);

                        if(!b.isUnlocked()) {
                            break;
                        }
                        Intent successIntent = new Intent(AwardsActivity.this, GameSuccess.class);
                        startActivity(successIntent);
                    }
                }
            }
        }
        */
    }
}
