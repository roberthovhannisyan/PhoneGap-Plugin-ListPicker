#import <Foundation/Foundation.h>
#import <Cordova/CDVPlugin.h>

@interface ListPicker : CDVPlugin <UIActionSheetDelegate, UIPopoverControllerDelegate, UIPickerViewDelegate> {
}

#pragma mark - Properties

@property (nonatomic, copy) NSString* callbackId;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, strong) UIPopoverController *popoverController;
@property (nonatomic, strong) UIView *modalView;
@property (nonatomic, strong) NSArray *items;

#pragma mark - Instance methods

- (void)showPicker:(CDVInvokedUrlCommand*)command;

@end