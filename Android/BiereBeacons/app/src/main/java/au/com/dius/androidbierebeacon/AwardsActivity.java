package au.com.dius.androidbierebeacon;

import android.app.Activity;
import android.app.Dialog;
import android.app.ProgressDialog;
import android.bluetooth.BluetoothAdapter;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.GridView;
import android.widget.ProgressBar;
import android.widget.Toast;

import com.estimote.sdk.Beacon;
import com.estimote.sdk.Region;
import com.estimote.sdk.Utils;

import java.util.ArrayList;
import java.util.List;

import au.com.dius.androidbierebeacon.BeaconMonitorService.BeaconBinder;

public class AwardsActivity extends Activity implements ServiceConnection {

    final static int SPOTTED_REQ_COUNT = 6;
    final static String TAG = AwardsActivity.class.getName();

	private BeaconBinder mBeaconBinder;
    private BadgeArrayAdapter badgeArrayAdapter;
    private List<Badge> mBadges;
    private ProgressDialog gatheringDialog;
    private Toast spottedToast;
    //private Game game;
	
	@Override
	protected void onPause() {
		super.onPause();
		
		// unBind service
		if(mBeaconBinder != null) {
			mBeaconBinder.getService().stopRanging(MainActivity.region_all);
		}
		this.unbindService(this);
	}
	
	@Override
	protected void onResume() {
		super.onResume();
		
		// Bind to service to get ranging notifications
		Intent service = new Intent(this, BeaconMonitorService.class);
		this.bindService(service, this, BIND_AUTO_CREATE);
	}

	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);

        if(getActionBar() != null) {
            getActionBar().setDisplayHomeAsUpEnabled(false);
        }

		setContentView(R.layout.awards);
		LocalBroadcastManager.getInstance(this).registerReceiver(mRangingReceiver, new IntentFilter(BeaconMonitorService.RANGED_INTENT));

        this.mBadges = new ArrayList<Badge>();
        this.mBadges.add(new Badge(MainActivity.region_green, R.drawable.hops));
        this.mBadges.add(new Badge(MainActivity.region_blue, R.drawable.water));
        this.mBadges.add(new Badge(MainActivity.region_phone_1, R.drawable.yeast));
        this.mBadges.add(new Badge(MainActivity.region_phone_2, R.drawable.barley));

        // setup the badge array adapter for the view
        this.badgeArrayAdapter = new BadgeArrayAdapter(this, R.layout.badge, new ArrayList<Badge>());

        // load unlocked badges
        for(Badge badge : this.mBadges) {
            badge.load(this);
            if(badge.isUnlocked()) {
                this.badgeArrayAdapter.add(badge);
            }
        }

        GridView gridView = (GridView) findViewById(R.id.badgeView);
        gridView.setAdapter(this.badgeArrayAdapter);


        // create dialogs and notifications
        gatheringDialog = new ProgressDialog(this);
        gatheringDialog.setMax(AwardsActivity.SPOTTED_REQ_COUNT);
        gatheringDialog.setProgress(0);
        gatheringDialog.setMessage("Gathering Ingredient!");
        gatheringDialog.setCancelable(false);

        spottedToast = Toast.makeText(AwardsActivity.this, "Ingredient Spotted", Toast.LENGTH_SHORT);
	}
	
	private BroadcastReceiver mRangingReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			ArrayList<Beacon> beacons = intent.getParcelableArrayListExtra(BeaconMonitorService.BEACONS_INTENT);

            // not near beacon?
			if(beacons.isEmpty()) {
				return;
			}
			
			// get first beacon - assumes it is the closest (according to estimote sdk)
            Beacon beacon = beacons.get(0);

            // check if is not game beacon
            if(!Utils.isBeaconInRegion(beacon, MainActivity.region_purple)) {
                beaconUpdate(beacon);
            }
            // first beacon is game beacon, check if near the game beacon
            else if(isNearGameBeacon(beacon)) {
                gameUpdate();
            }
            else {
                // not near the game beacon, get next beacon
                if(beacons.size() > 2) {
                    beacon = beacons.get(1);
                    beaconUpdate(beacon);
                }
            }
		}
	};

	@Override
	public void onServiceConnected(ComponentName arg0, IBinder binder) {
		if(mBeaconBinder == null) {
			mBeaconBinder = (BeaconBinder)binder;
		}
		BeaconMonitorService service = mBeaconBinder.getService();
		service.startRanging(MainActivity.region_all);
	}

	protected Badge getBeaconBadge(Beacon beacon) {
        for(int i = 0; i < this.mBadges.size(); i++) {
            Badge badge = this.mBadges.get(i);
            Region region = badge.region();

            // use estimote utils to determine if the region and beacons are the "same"
            if(Utils.isBeaconInRegion(beacon,region)) {
                return badge;
            }
        }
        return null;
	}

	@Override
	public void onServiceDisconnected(ComponentName arg0) {
		mBeaconBinder = null;
	}

    private boolean isNearGameBeacon(Beacon beacon) {
        if(Utils.isBeaconInRegion(beacon, MainActivity.region_purple) &&
           Utils.computeProximity(beacon) == Utils.Proximity.IMMEDIATE) {
            return true;
        }
        return false;
    }

    private void gameUpdate() {
        boolean gameFinished = true;
        // check if all badges are unlocked
        for (int i = 0; i < AwardsActivity.this.mBadges.size(); i++) {
            Badge b = AwardsActivity.this.mBadges.get(i);

            if (!b.isUnlocked()) {
                gameFinished = false;
                break;
            }
        }
        if (gameFinished) {
            Log.d(TAG, "Game success: %s");
            Intent successIntent = new Intent(AwardsActivity.this, GameSuccess.class);
            startActivity(successIntent);
            return;
        } else {
            Log.d(TAG, "Game denied: %s");
            Intent deniedIntent = new Intent(AwardsActivity.this, GameDenied.class);
            startActivity(deniedIntent);
            return;
        }
    }

    void beaconUpdate(Beacon beacon) {
        Badge badge = AwardsActivity.this.getBeaconBadge(beacon);
        if (badge != null && !badge.isUnlocked()) {

            if (Utils.computeProximity(beacon) == Utils.Proximity.NEAR ||
                    Utils.computeProximity(beacon) == Utils.Proximity.FAR ||
                    Utils.computeProximity(beacon) == Utils.Proximity.UNKNOWN) {
                gatheringDialog.cancel();
                spottedToast.show();
                Log.d("AwardsActivity", "show spotted");
            } else {
                spottedToast.cancel();
                badge.spotted();

                gatheringDialog.setProgress(badge.spottedCount());
                gatheringDialog.show();

                Log.d("AwardsActivity", "show gathering");


                if (badge.spottedCount() > AwardsActivity.SPOTTED_REQ_COUNT) {
                    badge.unlock();
                    badge.save(AwardsActivity.this);
                    AwardsActivity.this.badgeArrayAdapter.add(badge);
                    //AwardsActivity.this.badgeArrayAdapter.notifyDataSetChanged();
                    gatheringDialog.cancel();
                }
            }
        }
    }
}
