
//  ListPicker.js
//
// Created by Robert Hovhannisyan on 2014-06-12
//
// Copyright 2014 Robert Hovhannisyan. All rights reserved.
// MIT Licensed
var exec = require('cordova/exec');

var ListPicker = function() {}

ListPicker.prototype.create = function(options, callback) {
		options || (options = {});
		var scope = options.scope || null;
		
		var config = {
				title: options.title || ' ',
				items: options.items || {},
				style: options.style || 'default',
				doneButtonLabel: options.doneButtonLabel || 'Done',
				cancelButtonLabel: options.cancelButtonLabel || 'Cancel'
		};
		
		var _callback = function() {
				if(typeof callback == 'function') { 
					callback.apply(scope, arguments);
				}
		};
		return cordova.exec(_callback, null, 'ListPicker', 'showPicker', [config]);
}
module.exports = new ListPicker();