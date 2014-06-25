package au.com.dius.androidbierebeacon;

import java.util.ArrayList;

import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.ServiceConnection;
import android.os.Bundle;
import android.os.IBinder;
import android.support.v4.content.LocalBroadcastManager;
import android.widget.Toast;
import au.com.dius.androidbierebeacon.BeaconMonitorService.BeaconBinder;

import com.estimote.sdk.Beacon;

public class AwardsActivity extends Activity implements ServiceConnection {
	
	private BeaconBinder mBeaconBinder;
	
	@Override
	protected void onPause() {
		super.onPause();
		
		// unBind service
		if(mBeaconBinder != null) {
			mBeaconBinder.getService().stopRanging(MainActivity.region);
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
		
		getActionBar().setDisplayHomeAsUpEnabled(false);
		setContentView(R.layout.awards);
		LocalBroadcastManager.getInstance(this).registerReceiver(mRangingReceiver, new IntentFilter(BeaconMonitorService.RANGED_INTENT));
	}
	
	private BroadcastReceiver mRangingReceiver = new BroadcastReceiver() {
		@Override
		public void onReceive(Context context, Intent intent) {
			ArrayList<Beacon> beacons = intent.getParcelableArrayListExtra(BeaconMonitorService.BEACONS_INTENT);
			
			Toast.makeText(context, beacons.get(0).toString(), Toast.LENGTH_LONG).show();
		}
	};

	@Override
	public void onServiceConnected(ComponentName arg0, IBinder binder) {
		if(mBeaconBinder == null) {
			mBeaconBinder = (BeaconBinder)binder;
		}
		BeaconMonitorService service = mBeaconBinder.getService();
		service.startRanging(MainActivity.region);
	}

	@Override
	public void onServiceDisconnected(ComponentName arg0) {
		// TODO Auto-generated method stub
		mBeaconBinder = null;
	}
}
