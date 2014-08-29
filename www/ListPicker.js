
//  ListPicker.js
//
// Created by Robert Hovhannisyan on 2014-06-12
//
// Copyright 2014 Robert Hovhannisyan. All rights reserved.
// MIT Licensed
var exec = require('cordova/exec');

var ListPicker = function() {}

ListPicker.prototype.showPicker = function(options, callback, error_callback) {
    options || (options = {});
    var scope = options.scope || null;
    
    var config = {
        title: options.title || ' ',
        selectedValue: options.selectedValue || '',
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
    
    var _error_callback = function() {
        if(typeof error_callback == 'function') { 
          error_callback.apply(scope, arguments);
        }
    };
    cordova.exec(_callback, _error_callback, 'ListPicker', 'showPicker', [config]);
}
module.exports = new ListPicker();