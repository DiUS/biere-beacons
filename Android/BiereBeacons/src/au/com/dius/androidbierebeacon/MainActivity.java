package au.com.dius.androidbierebeacon;


import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.estimote.sdk.Region;

import au.com.dius.androidbierebeacon.R;

/* Notification Activity to start the Beacon Notification Service
 */

public class MainActivity extends Activity {
	
	final static String REGION = "region";
	final static String TAG = "DiUSBeaconNotification";
	final static String PREF_FORMAT = "%d - %s";
	
	// TODO: Should put these in an external file
	final static Region region = new Region("dius_region", "b9407f30-f5f8-466e-aff9-25556b57fe6d", null, null);
	final Region region_purple = new Region("dius_region_purple", "b9407f30-f5f8-466e-aff9-25556b57fe6d", 15295, 49236);
	final Region region_green = new Region("dius_region_green", "b9407f30-f5f8-466e-aff9-25556b57fe6d", 50730, 33558);
	final Region region_blue = new Region("dius_region_blue", "b9407f30-f5f8-466e-aff9-25556b57fe6d", 23491, 36886);


	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		getActionBar().setDisplayHomeAsUpEnabled(false);

		Intent i = new Intent(this, BeaconMonitorService.class);
		i.putExtra(REGION, region);
		startService(i);
		setContentView(R.layout.main);
		
		Intent awardsIntent = new Intent(this, AwardsActivity.class);
		startActivity(awardsIntent);
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();
	}

	@Override
	protected void onPause() {
		super.onPause();
		Log.d("main activity", "paused");
	}

	@Override
	protected void onResume() {
		super.onResume();
		Log.d("main activity", "resumed");
	}
}
