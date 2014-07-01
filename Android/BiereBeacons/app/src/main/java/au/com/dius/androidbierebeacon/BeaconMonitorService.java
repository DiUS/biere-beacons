package au.com.dius.androidbierebeacon;

import java.util.ArrayList;
import java.util.Calendar;
import java.util.List;
import java.util.Locale;

import com.estimote.sdk.Beacon;
import com.estimote.sdk.BeaconManager;
import com.estimote.sdk.Region;

import android.app.Notification;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.app.Service;
import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Binder;
import android.os.IBinder;
import android.os.RemoteException;
import android.preference.PreferenceManager;
import android.support.v4.content.LocalBroadcastManager;
import android.util.Log;
import au.com.dius.androidbierebeacon.BeaconMonitorService;
import au.com.dius.androidbierebeacon.R;


public class BeaconMonitorService extends Service {

    // service binder
	private final IBinder mBinder = new BeaconBinder();
	
	public class BeaconBinder extends Binder {
		BeaconMonitorService getService() {
			return BeaconMonitorService.this;
		}
	}

    // intents
    final static String MONITOR_INTENT = "beacon_monitor_intent";
	final static String RANGED_INTENT = "beacon_ranged_intent";
	final static String BEACONS_INTENT = "beacons_intent";

    // class
	final static String TAG = BeaconMonitorService.class.getName();
	final static int ID = 12345;

    // other
    final static String PREF_FORMAT = "%d - %s";

    // enums
	enum NOTIFY_TYPE {
		ENTERED,
		EXITED
	}
	enum NOTIFY_WHEN {
		TODAY, // Same date
		RECENT, // within 1 hour
	}
	
	private BeaconManager beaconManager;
	private NotificationManager notificationManager;
	
	@Override
	public int onStartCommand(Intent intent, int flags, int startId) {
		super.onStartCommand(intent, flags, startId);
		notificationManager = (NotificationManager)getSystemService(NOTIFICATION_SERVICE);
		beaconManager = new BeaconManager(this);
		
		onHandleIntent(intent);

		return START_REDELIVER_INTENT;
	}
	
	@Override
	public void onDestroy() {
		beaconManager.disconnect();
		super.onDestroy();
	}
	
	@Override
	public IBinder onBind(Intent arg) {
		return mBinder;
	}
	
	protected void onHandleIntent(Intent intent) {
		final Region region = intent.getParcelableExtra(MainActivity.REGION);
		
		beaconManager.setMonitoringListener(new BeaconManager.MonitoringListener() {
			
			@Override
			public void onExitedRegion(Region reg) {
				BeaconMonitorService.this.onExitedRegion(reg);
			}
			
			@Override
			public void onEnteredRegion(Region reg, List<Beacon> beacons) {
				BeaconMonitorService.this.onEnteredRegion(reg, beacons);
			}
		});
		
		beaconManager.setRangingListener(new BeaconManager.RangingListener() {
			
			@Override
			public void onBeaconsDiscovered(Region reg, List<Beacon> beacons) {
				Intent rangingBroadcast = new Intent(RANGED_INTENT);
				rangingBroadcast.putParcelableArrayListExtra(BEACONS_INTENT, new ArrayList<Beacon>(beacons));
				LocalBroadcastManager.getInstance(BeaconMonitorService.this).sendBroadcast(rangingBroadcast);
			}
		});
		
		beaconManager.connect(new BeaconManager.ServiceReadyCallback() {
			
			@Override
			public void onServiceReady() {
				try {
					beaconManager.startMonitoring(region);
				} catch (RemoteException e) {
					e.printStackTrace();
				}
			}
		});
	}

	protected void saveNotification(NOTIFY_TYPE type, Region reg) {
		// Get editor and key
		SharedPreferences.Editor prefEditor = PreferenceManager.getDefaultSharedPreferences(this).edit();
		String prefKey = String.format(Locale.getDefault(), PREF_FORMAT, type.ordinal(), reg.toString());
		
		// Get time to associate with event and region
		Calendar rightNow = Calendar.getInstance();
		
		// Save changes
		prefEditor.putLong(prefKey, rightNow.getTimeInMillis());
		prefEditor.commit();
	}

	protected boolean hasBeenNotified(NOTIFY_WHEN when, NOTIFY_TYPE type, Region reg) {
		// Get pref and key
		SharedPreferences pref = PreferenceManager.getDefaultSharedPreferences(this);
		String prefKey = String.format(Locale.getDefault(), PREF_FORMAT, type.ordinal(), reg.toString());

		// check key exists
		if(pref.contains(prefKey)) {
			// Get time associated with key
			Calendar lastTime = Calendar.getInstance();
			lastTime.setTimeInMillis(pref.getLong(prefKey, 0L));
			
			Calendar rightNow = Calendar.getInstance();
			
			// Check if notified within
			switch(when) {
			case TODAY: rightNow.set(Calendar.HOUR_OF_DAY, 0); 
						rightNow.set(Calendar.MINUTE, 0);
						rightNow.set(Calendar.SECOND, 0);
						return lastTime.after(rightNow);

			case RECENT: rightNow.add(Calendar.HOUR, -1);
						 return lastTime.after(rightNow);
			}
		}
		
		return false;
	}


	
	private void onEnteredRegion(Region reg, List<Beacon> beacons) {
		// check has not been notified today
		if(hasBeenNotified(NOTIFY_WHEN.TODAY, NOTIFY_TYPE.ENTERED, reg)) {
			return;
		}
		
		// Set up an intent for the notification
		Intent openAppIntent = new Intent(getApplicationContext(), MainActivity.class);
		
		Notification notification = new Notification.Builder(getApplicationContext())
		.setContentTitle(getResources().getText(R.string.notification_title))
		.setContentText(getResources().getText(R.string.notification_welcome))
		.setContentIntent(PendingIntent.getActivity(getApplication(), START_STICKY, openAppIntent, START_FLAG_REDELIVERY))
		.setSmallIcon(R.drawable.ic_launcher)
		.build();
		notificationManager.notify(BeaconMonitorService.TAG, BeaconMonitorService.ID, notification);
		
		// Save notification
		saveNotification(NOTIFY_TYPE.ENTERED, reg);		
	}
	
	private void onExitedRegion(Region reg) {
		// check if already notified today
		if(hasBeenNotified(NOTIFY_WHEN.TODAY, NOTIFY_TYPE.EXITED, reg)) {
			return;
		}
		
		// trigger notification only if after 4pm
		Calendar rightNow = Calendar.getInstance();
		Calendar cal_4pm = Calendar.getInstance();
		cal_4pm.set(Calendar.HOUR, 16);
		cal_4pm.set(Calendar.MINUTE, 0);
		cal_4pm.set(Calendar.SECOND, 0);
		
		if(rightNow.after(cal_4pm)) {
			Notification notification = new Notification.Builder(getApplicationContext())
			.setContentTitle(getResources().getText(R.string.notification_title))
			.setContentText(getResources().getText(R.string.notification_goodbye))
			.setSmallIcon(R.drawable.ic_launcher)
			.build();
			notificationManager.notify(BeaconMonitorService.TAG, BeaconMonitorService.ID, notification);
			
			// Save notification
			saveNotification(NOTIFY_TYPE.EXITED, reg);
		}
	}

    public void startMonitoring(Region region) {
        try {
            beaconManager.startMonitoring(region);
        } catch (RemoteException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

    public void stopMonitoring(Region region) {
        try {
            beaconManager.stopMonitoring(region);
        } catch (RemoteException e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
    }

	public void startRanging(Region region) {
		try {
			beaconManager.startRanging(region);
		} catch (RemoteException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
	}
	public void stopRanging(Region region) {
		try {
			beaconManager.stopRanging(region);
		} catch (RemoteException e) {
			e.printStackTrace();
		}
	}
	
}
