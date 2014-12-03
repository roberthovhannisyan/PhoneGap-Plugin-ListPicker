package am.armsoft.plugins;

import java.util.ArrayList;
import java.util.List;

import org.json.JSONObject;
import org.json.JSONArray;
import org.json.JSONException;

import android.app.AlertDialog;
import android.content.DialogInterface;

import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.PluginResult;

/**
 * This class provides a service.
 */
public class ListPicker extends CordovaPlugin {

    /**
     * Constructor.
     */
    public ListPicker() {
    }

    /**
     * Executes the request and returns PluginResult.
     *
     * @param action        The action to execute.
     * @param args          JSONArry of arguments for the plugin.
     * @param callbackId    The callback id used when calling back into JavaScript.
     * @return              A PluginResult object with a status and message.
     */
    @Override
    public boolean execute(String action, JSONArray args, final CallbackContext callbackContext) throws JSONException {
        if (action.equals("showPicker")) {
            this.showPicker(args, callbackContext);
            return true;
        }
        return false;
    }

    // --------------------------------------------------------------------------
    // LOCAL METHODS
    // --------------------------------------------------------------------------
    
    public void showPicker(final JSONArray data, final CallbackContext callbackContext) throws JSONException {
    
        final CordovaInterface cordova = this.cordova;
        
        final JSONObject options = data.getJSONObject(0);
        final String title = options.getString("title");
        final String selectedValue = options.getString("selectedValue");
        final JSONArray items = options.getJSONArray("items");
        
                
        // Get the texts to display
        int index = -1;
        List<String> list = new ArrayList<String>();
        for(int i = 0; i < items.length(); i++) {
            JSONObject item = items.getJSONObject(i);
            list.add(item.getString("text"));
            if (selectedValue.equals(item.getString("value"))) {
              index = i;
            }
        }
        final CharSequence[] texts = list.toArray(new CharSequence[list.size()]);
        final int selectedIndex = index;
        
        // Create and show the alert dialog
        Runnable runnable = new Runnable() {
            public void run() {
                AlertDialog.Builder builder = new AlertDialog.Builder(cordova.getActivity());
                
                // Set dialog properties
                builder.setTitle(title);
                builder.setCancelable(true);
                builder.setSingleChoiceItems(texts, selectedIndex, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int index) {
                        try {
                            final JSONObject selectedItem = items.getJSONObject(index);
                            final String selectedValue = selectedItem.getString("value");
                            dialog.dismiss();
                            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.OK, selectedValue));
                        }
                        catch (JSONException e) {
                            callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.JSON_EXCEPTION));
                        }
                    }
                });
                builder.setOnCancelListener(new  DialogInterface.OnCancelListener() { 
                    public void onCancel(DialogInterface dialog) { 
                        callbackContext.sendPluginResult(new PluginResult(PluginResult.Status.ERROR));
                    } 
                }); 
                
                // Show alert dialog
                AlertDialog alert = builder.create();
                alert.getWindow().getAttributes().windowAnimations = android.R.style.Animation_Dialog;
                alert.show(); 
            }
        };
        this.cordova.getActivity().runOnUiThread(runnable);
    }

}