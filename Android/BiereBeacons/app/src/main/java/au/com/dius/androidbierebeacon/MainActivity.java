package au.com.dius.androidbierebeacon;


import android.app.Activity;
import android.bluetooth.BluetoothAdapter;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;

import com.estimote.sdk.Region;

import au.com.dius.androidbierebeacon.R;

/* Main Activity
 * Start BeaconMonitorService
 * Check bluetooth on
 * Start main game activity
 */

public class MainActivity extends Activity {

    final static int REQUEST_ENABLE_BT = 1;

	final static String REGION = "region";
	final static String TAG = MainActivity.class.getName();
	final static String PREF_FORMAT = "%d - %s";
	
	// TODO: Should put these in an external file
	final static Region region_all = new Region("dius_region", "b9407f30-f5f8-466e-aff9-25556b57fe6d", null, null);
    // purple at the fridge
	final static Region region_purple = new Region("dius_region_purple", "b9407f30-f5f8-466e-aff9-25556b57fe6d", 15295, 49236);
    // hops, region based
	final static Region region_green = new Region("dius_region_green", "b9407f30-f5f8-466e-aff9-25556b57fe6d", 50730, 33558);
    // water, region based
	final static Region region_blue = new Region("dius_region_blue", "b9407f30-f5f8-466e-aff9-25556b57fe6d", 23491, 36886);
    // yeast, region based
    final static Region region_phone_1 = new Region("dius_region_phone_1", "b9407f30-f5f8-466e-aff9-25556b57fe6d", 111, 222);
    // barley, region based
    final static Region region_phone_2 = new Region("dius_region_phone_2", "b9407f30-f5f8-466e-aff9-25556b57fe6d", 1, 2);


	@Override
	protected void onCreate(Bundle savedInstanceState) {
		super.onCreate(savedInstanceState);
		getActionBar().setDisplayHomeAsUpEnabled(false);

        isBluetoothOn();

		Intent i = new Intent(this, BeaconMonitorService.class);
		i.putExtra(REGION, region_all);
		startService(i);
		//setContentView(R.layout.main);
		
		Intent awardsIntent = new Intent(this, AwardsActivity.class);
        awardsIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
		startActivity(awardsIntent);
        finish();
	}

	@Override
	protected void onDestroy() {
		super.onDestroy();
	}

	@Override
	protected void onPause() {
		super.onPause();
		Log.d(TAG, "paused");
	}

	@Override
	protected void onResume() {
		super.onResume();
		Log.d(TAG, "resumed");
	}

    private void isBluetoothOn() {
        // check bluetooth
        BluetoothAdapter mBluetoothAdapter = BluetoothAdapter.getDefaultAdapter();
        if (mBluetoothAdapter == null) {
            // Device does not support Bluetooth
        }

        // Request user to turn on bluetooth
        if(!mBluetoothAdapter.isEnabled()) {
            Intent enableBtIntent = new Intent(BluetoothAdapter.ACTION_REQUEST_ENABLE);
            startActivityForResult(enableBtIntent, REQUEST_ENABLE_BT);
        }
    }
}
