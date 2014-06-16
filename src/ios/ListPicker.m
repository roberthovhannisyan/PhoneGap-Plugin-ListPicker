#import "PickerView.h"
#import <Cordova/CDVDebug.h>

@implementation PickerView

@synthesize callbackId = _callbackId;
@synthesize pickerView = _pickerView;
@synthesize actionSheet = _actionSheet;
@synthesize popoverController = _popoverController;
@synthesize items = _items;


- (int)getRowWithValue:(NSString * )name {
  for(int i = 0; i < [self.items count]; i++) {
    NSDictionary *item = [self.items objectAtIndex:i];
    if([name isEqualToString:[item objectForKey:@"value"]]) {
      return i;
    }
  }
  return -1;
}

- (void)showPicker:(CDVInvokedUrlCommand*)command {

  self.callbackId = command.callbackId;
  NSDictionary *options = [command.arguments objectAtIndex:0];
  
  // Compiling options with defaults
  NSString *title = [options objectForKey:@"title"] ?: @" ";
  NSString *style = [options objectForKey:@"style"] ?: @"default";
  NSString *doneButtonLabel = [options objectForKey:@"doneButtonLabel"] ?: @"Done";
  NSString *cancelButtonLabel = [options objectForKey:@"cancelButtonLabel"] ?: @"Cancel";

  // Hold items in an instance variable
  self.items = [options objectForKey:@"items"];

  // Initialize PickerView
  self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 40.0f, 320.0f, 162.0f)];
  self.pickerView.showsSelectionIndicator = YES;
  self.pickerView.delegate = self;

  // Define selected value
  if([options objectForKey:@"selectedValue"]) {
    int i = [self getRowWithValue:[options objectForKey:@"selectedValue"]];
    if (i != -1) [self.pickerView selectRow:i inComponent:0 animated:NO];
  }
  
  // Check if device is iPad as we won't be able to use an ActionSheet there
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    return [self createForIpad:command];
  }

  // Create actionSheet
  self.actionSheet = [[UIActionSheet alloc] 
    initWithTitle:title
    delegate:self
    cancelButtonTitle:nil
    destructiveButtonTitle:nil
    otherButtonTitles:nil];

  // Style actionSheet, defaults to UIActionSheetStyleDefault
  if([style isEqualToString:@"black-opaque"]) self.actionSheet.actionSheetStyle = UIActionSheetStyleBlackOpaque;
  else if([style isEqualToString:@"black-translucent"]) self.actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
  else self.actionSheet.actionSheetStyle = UIActionSheetStyleDefault;

  // Append pickerView
  [self.actionSheet addSubview:self.pickerView];
  
  // Create segemented cancel button
  UISegmentedControl *cancelButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:cancelButtonLabel]];
  cancelButton.momentary = YES;
  cancelButton.frame = CGRectMake(5.0f, 7.0f, 50.0f, 30.0f);
  cancelButton.segmentedControlStyle = UISegmentedControlStyleBar;
  cancelButton.tintColor = [UIColor blackColor];
  [cancelButton addTarget:self action:@selector(segmentedControl:didDismissWithCancelButton:) forControlEvents:UIControlEventValueChanged];
  // Append close button
  [self.actionSheet addSubview:cancelButton];

  // Create segemented done button
  UISegmentedControl *doneButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:doneButtonLabel]];
  doneButton.momentary = YES;
  doneButton.frame = CGRectMake(265.0f, 7.0f, 50.0f, 30.0f);
  doneButton.segmentedControlStyle = UISegmentedControlStyleBar;
  doneButton.tintColor = [UIColor colorWithRed:51.0f/255.0f green:102.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
  [doneButton addTarget:self action:@selector(segmentedControl:didDismissWithDoneButton:) forControlEvents:UIControlEventValueChanged];
  // Append done button
  [self.actionSheet addSubview:doneButton];
  
  // Toggle ActionSheet
  [self.actionSheet showInView:self.webView.superview];

  // Resize actionSheet was 360
  float actionSheetHeight;
  int systemMajorVersion = [[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] integerValue];
  if(systemMajorVersion >= 5) {
    actionSheetHeight = 360.0f;
  } else {
    actionSheetHeight = 472.0f;
  }
  [self.actionSheet setBounds:CGRectMake(0, 0, 320.0f, actionSheetHeight)];
}

-(void)createForIpad:(CDVInvokedUrlCommand*)command {

  NSString *doneButtonLabel = [options objectForKey:@"doneButtonLabel"] ?: @"Done";
  
  // Create a generic content view controller
  UINavigationController* popoverContent = [[UINavigationController alloc] init];

  // Create a generic container view
  UIView* popoverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320.0f, 162.0f)];
  popoverContent.view = popoverView;

  // Append pickerView
  [popoverView addSubview:self.pickerView];
  
  // Create segemented done button
  UISegmentedControl *doneButton = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObject:doneButtonLabel]];
  doneButton.momentary = YES;
  doneButton.frame = CGRectMake(265.0f, 7.0f, 50.0f, 30.0f);
  doneButton.segmentedControlStyle = UISegmentedControlStyleBar;
  doneButton.tintColor = [UIColor colorWithRed:51.0f/255.0f green:102.0f/255.0f blue:153.0f/255.0f alpha:1.0f];
  [doneButton addTarget:self action:@selector(segmentedControl:didDismissWithDoneButton:) forControlEvents:UIControlEventValueChanged];
  // Append done button
  [popoverView addSubview:doneButton];

  // Resize the popover view shown
  // in the current view to the view's size
  popoverContent.contentSizeForViewInPopover = CGSizeMake(320.0f, 162.0f);

  // Create a popover controller
  self.popoverController = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
  self.popoverController.delegate = self;

  CGRect sourceRect = CGRectNull;
  UIDeviceOrientation curDevOrientation = [[UIApplication sharedApplication] statusBarOrientation];
  if(UIDeviceOrientationIsLandscape(curDevOrientation)) {
    // 1024-20 / 2 & 768 - 10
    sourceRect = CGRectMake(502.0f, 758.0f, 20.0f, 20.0f);
  } else {
    sourceRect = CGRectMake(374.0f, 1014.0f, 20.0f, 20.0f);
  }

  //present the popover view non-modal with a
  //refrence to the button pressed within the current view
  [self.popoverController presentPopoverFromRect:sourceRect
      inView:self.webView.superview
      permittedArrowDirections:@"any"
      animated:YES];

}

//
// Dismiss methods
//

// Picker with segmentedControls dismissed with done
- (void)segmentedControl:(UISegmentedControl *)segmentedControl didDismissWithDoneButton:(NSInteger)buttonIndex {

  // Check if device is iPad
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    // Emulate a new delegate method
    [self popoverController:self.popoverController dismissWithClickedButtonIndex:1 animated:YES];
  } else {
    [self.actionSheet dismissWithClickedButtonIndex:1 animated:YES];
  }
}

// Picker with segmentedControls dismissed with cancel
- (void)segmentedControl:(UISegmentedControl *)segmentedControl didDismissWithCancelButton:(NSInteger)buttonIndex {

  // Check if device is iPad
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
    // Emulate a new delegate method
    [self popoverController:self.popoverController dismissWithClickedButtonIndex:0 animated:YES];
  } else {
    [self.actionSheet dismissWithClickedButtonIndex:0 animated:YES];
  }
}

// Popover generic dismiss - iPad
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {

    // Simulate a cancel click
    [self sendResultsFromPickerView:self.pickerView withButtonIndex:0];
}

// Popover emulated button-powered dismiss - iPad
- (void)popoverController:(UIPopoverController *)popoverController dismissWithClickedButtonIndex:(NSInteger)buttonIndex animated:(Boolean)animated {
  
  // Manually dismiss the popover
  [popoverController dismissPopoverAnimated:animated];
  
  // Retreive pickerView
  [self sendResultsFromPickerView:self.pickerView withButtonIndex:buttonIndex];
}

// ActionSheet generic dismiss - iPhone
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
  {
    // Simulate a cancel click
    [self sendResultsFromPickerView:self.pickerView withButtonIndex:buttonIndex];
  }

//
// Results
//

- (void)sendResultsFromPickerView:(UIPickerView *)pickerView withButtonIndex:(NSInteger)buttonIndex {

  // Build returned result
  NSInteger selectedRow = [pickerView selectedRowInComponent:0];
  NSString *selectedValue = [[self.items objectAtIndex:selectedRow] objectForKey:@"value"];
  
  // Create Plugin Result
  CDVPluginResult* pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:selectedValue];

  // Checking if cancel was clicked
  if (buttonIndex == 0) {
    // Call the Failure Javascript function
    [self writeJavascript: [pluginResult toErrorCallbackString:[self.callbackId]];
  }else {
    // Call the Success Javascript function
    [self writeJavascript: [pluginResult toSuccessCallbackString:[self.callbackId]];
  }

}

//
// Picker delegate
//


// Listen picker selected row
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
}

// Tell the picker how many rows are available for a given component
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return [self.items count];
}

// Tell the picker how many components it will have
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

// Tell the picker the title for a given component
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return [[self.items objectAtIndex:row] objectForKey:@"text"];
}

// Tell the picker the width of each row for a given component
- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
  return 300.0f;
}

@end