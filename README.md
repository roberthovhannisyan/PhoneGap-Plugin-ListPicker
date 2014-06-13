ListPicker
=============

PhoneGap plugin to display a list picker dialog for Android and iOS.

Usage:

		// Prepare the picker configuration
		var config = {
    		title: "Select a Fruit", 
        items: [
        		{ text: "Orange", value: "orange" },
            { text: "Apple", value: "apple" },
            { text: "Watermelon", value: "watermelon" },
            { text: "Papaya", value: "papaya" },
            { text: "Banana", value: "banana" },
            { text: "Pear", value: "pear" }
        ]
    };
    
    // Show the picker
		window.plugins.listpicker.showPicker(config, 
				function(item) { 
						alert("You have selected " + item);
				}
		);
    
    