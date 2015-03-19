#import "ListPicker.h"
#import <Cordova/CDVDebug.h>

#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )
#define IS_IPAD UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad
#define DEVICE_ORIENTATION [UIDevice currentDevice].orientation

// UIInterfaceOrientationMask vs. UIInterfaceOrientation
// A function like this isn't available in the API. It is derived from the enum def for
// UIInterfaceOrientationMask.
#define OrientationMaskSupportsOrientation(mask, orientation)   ((mask & (1 << orientation)) != 0)


@implementation ListPicker

@synthesize callbackId = _callbackId;
@synthesize pickerView = _pickerView;
@synthesize popoverController = _popoverController;
@synthesize modalView = _modalView;
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
    NSString *doneButtonLabel = [options objectForKey:@"doneButtonLabel"] ?: @"Done";
    NSString *cancelButtonLabel = [options objectForKey:@"cancelButtonLabel"] ?: @"Cancel";

    // Hold items in an instance variable
    self.items = [options objectForKey:@"items"];

    // Initialize the toolbar with Cancel and Done buttons and title
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0, 0, self.viewSize.width, 44)];
    toolbar.barStyle = (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? UIBarStyleDefault : UIBarStyleBlackTranslucent;
    NSMutableArray *buttons =[[NSMutableArray alloc] init];
    
    // Create Cancel button
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc]initWithTitle:cancelButtonLabel style:UIBarButtonItemStylePlain target:self action:@selector(didDismissWithCancelButton:)];
    [buttons addObject:cancelButton];
    
    // Create title label aligned to center and appropriate spacers
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [buttons addObject:flexSpace];
    UILabel *label =[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 180, 30)];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setTextColor: (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) ? [UIColor blackColor] : [UIColor whiteColor]];
    [label setFont: [UIFont boldSystemFontOfSize:16]];
    [label setBackgroundColor:[UIColor clearColor]];
     label.text = title;
     UIBarButtonItem *labelButton = [[UIBarButtonItem alloc] initWithCustomView:label];
    [buttons addObject:labelButton];
    [buttons addObject:flexSpace];
     
     // Create Done button
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:doneButtonLabel style:UIBarButtonItemStyleDone target:self action:@selector(didDismissWithDoneButton:)];
     [buttons addObject:doneButton];
     [toolbar setItems:buttons animated:YES];
     
    // Initialize the picker
    self.pickerView = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 22.0f, self.viewSize.width, 216)];
    self.pickerView.showsSelectionIndicator = YES;
    self.pickerView.delegate = self;

    // Define selected value
    if([options objectForKey:@"selectedValue"]) {
        int i = [self getRowWithValue:[options objectForKey:@"selectedValue"]];
        if (i != -1) [self.pickerView selectRow:i inComponent:0 animated:NO];
    }
   
    // Initialize the View that should conain the toolbar and picker
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, self.viewSize.height - 260, self.viewSize.width, 260)];
    if(NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
      [view setBackgroundColor:[UIColor colorWithRed:0.97 green:0.97 blue:0.97 alpha:1.0]];
    }
    [view addSubview: toolbar];
    
    //ios7 picker draws a darkened alpha-only region on the first and last 8 pixels horizontally, but blurs the rest of its background.  To make the whole popup appear to be edge-to-edge, we have to add blurring to the remaining left and right edges.
    if ( NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1 )
    {
        CGRect f = CGRectMake(0, toolbar.frame.origin.y, 8, view.frame.size.height - toolbar.frame.origin.y);
        UIToolbar *leftEdge = [[UIToolbar alloc] initWithFrame:f];
        f.origin.x = view.frame.size.width - 8;
        UIToolbar *rightEdge = [[UIToolbar alloc] initWithFrame:f];
        [view insertSubview:leftEdge atIndex:0];
        [view insertSubview:rightEdge atIndex:0];
    }
    
    [view addSubview:self.pickerView];
  
    // Check if device is iPad to display popover
    if ( IS_IPAD ) {
        return [self presentPopoverForView:view];
    } else {
        return [self presentModalViewForView:view];
    }
}
     
-(void)presentModalViewForView:(UIView *)view {

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(didRotate:) 
                                                 name:UIApplicationWillChangeStatusBarOrientationNotification 
                                               object:nil];

    CGRect viewFrame = CGRectMake(0, 0, self.viewSize.width, self.viewSize.height);
    [view setFrame: CGRectMake(0, viewFrame.size.height, viewFrame.size.width, 260)];
    
    // Create the modal view to display
    self.modalView = [[UIView alloc] initWithFrame: viewFrame];
    [self.modalView setBackgroundColor:[UIColor clearColor]];
    [self.modalView addSubview: view];
    
    // Add the modal view to current controller
    [self.webView.superview addSubview:self.modalView];
    [self.webView.superview bringSubviewToFront:self.modalView];
    
    //Present the view animated
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options: 0
                     animations:^{
                         [self.modalView.subviews[0] setFrame: CGRectOffset(viewFrame, 0, viewFrame.size.height - 260)];;
                         [self.modalView setBackgroundColor:[UIColor colorWithWhite:0.0 alpha:0.5]];
                     }
                     completion:nil];
}

-(void)presentPopoverForView:(UIView *)view {

    // Create a generic content view controller
    UIViewController* popoverContent = [[UIViewController alloc] initWithNibName:nil bundle:nil];
    popoverContent.view = view;

    // Resize the popover to the view's size
    popoverContent.preferredContentSize = view.frame.size;

    // Create a popover controller
    self.popoverController = [[UIPopoverController alloc] initWithContentViewController:popoverContent];
    self.popoverController.delegate = self;
    
    // display the picker at the center of the view
    CGRect sourceRect = CGRectMake(self.webView.superview.center.x, self.webView.superview.center.y, 1, 1);

    //present the popover view non-modal with a
    //refrence to the button pressed within the current view
    [self.popoverController presentPopoverFromRect:sourceRect
                                            inView:self.webView.superview
                          permittedArrowDirections: 0
                                          animated:YES];

}

//
// Dismiss methods
//

- (void) didRotate:(NSNotification *)notification
{
    UIInterfaceOrientationMask supportedInterfaceOrientations = (UIInterfaceOrientationMask) [[UIApplication sharedApplication]
                                                     supportedInterfaceOrientationsForWindow:
                                                     [UIApplication sharedApplication].keyWindow];

    if (OrientationMaskSupportsOrientation(supportedInterfaceOrientations, DEVICE_ORIENTATION)) {
        // Check if device is iPad
        if ( IS_IPAD ) {
            [self dismissPopoverController:self.popoverController withButtonIndex:0 animated:YES];
        } else {
            [self dismissModalView:self.modalView withButtonIndex:0 animated:YES];
        }
    }
}

// Picker with toolbar dismissed with done
- (IBAction)didDismissWithDoneButton:(id)sender {

    // Check if device is iPad
    if ( IS_IPAD ) {
        // Emulate a new delegate method
        [self dismissPopoverController:self.popoverController withButtonIndex:1 animated:YES];
    } else {
        [self dismissModalView:self.modalView withButtonIndex:1 animated:YES];
    }
}

// Picker with toolbar dismissed with cancel
- (IBAction)didDismissWithCancelButton:(id)sender {

    // Check if device is iPad
    if ( IS_IPAD ) {
        // Emulate a new delegate method
        [self dismissPopoverController:self.popoverController withButtonIndex:0 animated:YES];
    } else {
        [self dismissModalView:self.modalView withButtonIndex:0 animated:YES];
    }
}

// Popover generic dismiss - iPad
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {

    // Simulate a cancel click
    [self sendResultsFromPickerView:self.pickerView withButtonIndex:0];
}

// Popover emulated button-powered dismiss - iPad
- (void)dismissPopoverController:(UIPopoverController *)popoverController withButtonIndex:(NSInteger)buttonIndex animated:(Boolean)animated {
  
  // Manually dismiss the popover
  [popoverController dismissPopoverAnimated:animated];

  // Send the result according to the button selected
  [self sendResultsFromPickerView:self.pickerView withButtonIndex:buttonIndex];
}

// View generic dismiss - iPhone (iOS8)
- (void)dismissModalView:(UIView *)modalView withButtonIndex:(NSInteger)buttonIndex animated:(Boolean)animated {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillChangeStatusBarOrientationNotification
                                                  object:nil];
		
    //Hide the view animated and then remove it.
    [UIView animateWithDuration:0.5
                          delay:0.0
                        options: 0
                     animations:^{
                        CGRect viewFrame = CGRectMake(0, 0, self.viewSize.width, self.viewSize.height);
                        [self.modalView.subviews[0] setFrame: CGRectOffset(viewFrame, 0, viewFrame.size.height)];
                        [self.modalView setBackgroundColor:[UIColor clearColor]];
                     }
                     completion:^(BOOL finished) {
                        [self.modalView removeFromSuperview];
                     }];
  
    // Retreive pickerView
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
    CDVPluginResult* pluginResult;
    if (buttonIndex == 0) {
        // Create ERROR result if cancel was clicked
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR];
    }else {
        // Create OK result otherwise
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:selectedValue];
    }
    
    // Call appropriate javascript function
    [self.commandDelegate sendPluginResult:pluginResult callbackId:self.callbackId];;
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
  return pickerView.frame.size.width - 30;
}

//
// Utilities
//

- (CGSize)viewSize
{
    CGSize winSize = [UIApplication sharedApplication].keyWindow.rootViewController.view.frame.size;
    if ( IS_IPAD )
    {
        return CGSizeMake(320, 320);
    }
    
#if defined(__IPHONE_8_0)
    if (floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_7_1) {
        //iOS 7.1 or earlier
        if ( [self isViewPortrait] )
            return CGSizeMake(winSize.width , IS_WIDESCREEN ? 568 : winSize.height);
        return CGSizeMake(IS_WIDESCREEN ? 568 : MAX(winSize.width, winSize.height), MIN(winSize.width , winSize.height));
        
    }else{
        //iOS 8 or later
        return [[UIScreen mainScreen] bounds].size;
    }
#else
    if ( [self isViewPortrait] )
        return CGSizeMake(320 , IS_WIDESCREEN ? 568 : 480);
    return CGSizeMake(IS_WIDESCREEN ? 568 : MAX(winSize.width, winSize.height), MIN(winSize.width, winSize.height));
#endif
}

- (BOOL) isViewPortrait {
    return UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation);
}

@end
