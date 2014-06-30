package au.com.dius.androidbierebeacon;

import android.app.Activity;
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
import android.widget.GridView;
import android.widget.Toast;

import com.estimote.sdk.Beacon;
import com.estimote.sdk.Region;
import com.estimote.sdk.Utils;

import java.util.ArrayList;
import java.util.List;

import au.com.dius.androidbierebeacon.BeaconMonitorService.BeaconBinder;

public class AwardsActivity extends Activity implements ServiceConnection {
	
	private BeaconBinder mBeaconBinder;
    private BadgeArrayAdapter badgeArrayAdapter;
    private Toast awardToast;
    //private Game game;
    final static int TOAST_LENGTH = 2;


	
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

        List<Badge> badges = new ArrayList<Badge>();
        badges.add(new Badge(MainActivity.region_green, R.drawable.hops));
        badges.add(new Badge(MainActivity.region_blue, R.drawable.water));
        badges.add(new Badge(MainActivity.region_phone_1, R.drawable.yeast));
        badges.add(new Badge(MainActivity.region_phone_2, R.drawable.barley));

        for(Badge badge : badges) {
            badge.load(this);
        }

        this.badgeArrayAdapter = new BadgeArrayAdapter(this, R.layout.badge, badges);
        GridView gridView = (GridView) findViewById(R.id.badgeView);
        gridView.setAdapter(this.badgeArrayAdapter);

        awardToast = new Toast(AwardsActivity.this);
	}
	
	private BroadcastReceiver mRangingReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			ArrayList<Beacon> beacons = intent.getParcelableArrayListExtra(BeaconMonitorService.BEACONS_INTENT);
			
			if(beacons.isEmpty()) {
				return;
			}
			
			// get first beacon - assumes it is the closest (according to estimote sdk)
            if(Utils.isBeaconInRegion(beacons.get(0), MainActivity.region_purple)) {
                boolean gameFinished = false;
                // check if all badges are unlocked
                for(int i = 0; i < AwardsActivity.this.badgeArrayAdapter.getCount(); i++) {
                    Badge b = AwardsActivity.this.badgeArrayAdapter.getItem(i);

                    if(!b.isUnlocked()) {
                        break;
                    }

                }
                if(gameFinished) {
                    Intent successIntent = new Intent(AwardsActivity.this, GameSuccess.class);
                    startActivity(successIntent);
                }
                else {
                    Intent successIntent = new Intent(AwardsActivity.this, GameDenied.class);
                    startActivity(successIntent);
                }
            }

			Badge badge = AwardsActivity.this.getBeaconBadge(beacons.get(0));
            if(badge != null && !badge.isUnlocked()) {

                if(Utils.computeProximity(beacons.get(0)) == Utils.Proximity.NEAR ||
                   Utils.computeProximity(beacons.get(0)) == Utils.Proximity.FAR ||
                   Utils.computeProximity(beacons.get(0)) == Utils.Proximity.UNKNOWN ) {
                    awardToast.cancel();
                    awardToast = Toast.makeText(AwardsActivity.this, "Ingredient Spotted", TOAST_LENGTH);
                    awardToast.show();
                }
                else {
                    awardToast.cancel();
                    awardToast = Toast.makeText(AwardsActivity.this, "Gathering Ingredient", TOAST_LENGTH);
                    awardToast.show();

                    badge.spotted();

                    if (badge.spottedCount() > 5) {
                        badge.unlock();
                        badge.save(AwardsActivity.this);
                        AwardsActivity.this.badgeArrayAdapter.notifyDataSetChanged();


                    }
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
        for(int i = 0; i < this.badgeArrayAdapter.getCount(); i++) {
            Badge badge = this.badgeArrayAdapter.getItem(i);
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




}
