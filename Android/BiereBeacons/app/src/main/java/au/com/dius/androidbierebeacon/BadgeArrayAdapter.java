package au.com.dius.androidbierebeacon;

import android.content.Context;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;

import java.util.List;

public class BadgeArrayAdapter extends ArrayAdapter<Badge> {

    final static String TAG = BadgeArrayAdapter.class.getName();

	public BadgeArrayAdapter(Context context, int resource, List<Badge> objects) {
		super(context, resource, objects);
	}
	
	@Override
    public View getView(int position, View convertView, ViewGroup parent) {
        Log.d(TAG, String.format("get view with pos: %d", position));

        LayoutInflater inflater = (LayoutInflater) this.getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        View view = inflater.inflate(R.layout.badge, parent, false);

        ImageView imageView = (ImageView) view.findViewById(R.id.badgeImage);

        if(this.getItem(position).isUnlocked()) {
            imageView.setImageResource(this.getItem(position).resource());
            Log.d(TAG, "unlocked");
        }
        else {
            imageView.setVisibility(imageView.INVISIBLE);
            Log.d(TAG, "locked");
        }

        return view;
    }


    @Override
    public boolean areAllItemsEnabled() {
        return false;
    }

    @Override
    public boolean isEnabled(int position) {
        return false;
    }
}
