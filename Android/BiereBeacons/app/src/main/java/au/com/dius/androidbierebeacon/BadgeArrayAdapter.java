package au.com.dius.androidbierebeacon;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.ImageView;

import java.util.List;

public class BadgeArrayAdapter extends ArrayAdapter<Badge> {

	public BadgeArrayAdapter(Context context, int resource, List<Badge> objects) {
		super(context, resource, objects);
	}
	
	@Override
    public View getView(int position, View convertView, ViewGroup parent) {
        LayoutInflater inflater = (LayoutInflater) this.getContext().getSystemService(Context.LAYOUT_INFLATER_SERVICE);

        View view = inflater.inflate(R.layout.badge, parent, false);

        ImageView imageView = (ImageView) view.findViewById(R.id.badgeImage);

        if(this.getItem(position).isUnlocked()) {
            imageView.setImageResource(this.getItem(position).resource());
        }
        else {
            imageView.setVisibility(imageView.INVISIBLE);
        }

        return view;
    }
	

}
