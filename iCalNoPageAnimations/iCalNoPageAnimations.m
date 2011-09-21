//
//  iCalNoPageAnimations.m
//  iCalNoPageAnimations
//
//  Created by Lukas Pitschl on 20.09.11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
#import "JRSwizzle.h"
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "iCalNoPageAnimations.h"

@implementation iCalNoPageAnimations

+ (void) load
{
    iCalNoPageAnimations* plugin = [iCalNoPageAnimations sharedInstance];
    // ... do whatever
    NSLog(@"iCalNoPageAnimations installed");
    NSError *error;
    [NSClassFromString(@"CalUIViewController") jr_addMethod:@selector(ICIsPageTransitionAnimationDisabled) fromClass:self error:&error];
    if(error)
        NSLog(@"[DEBUG] Error: %@", error);
    error = nil;
    [NSClassFromString(@"CalUIViewController") jr_swizzleMethod:@selector(isPageTransitionAnimationDisabled) withMethod:@selector(ICIsPageTransitionAnimationDisabled) error:&error];
    if(error)
        NSLog(@"[DEBUG] Error: %@", error);
    [NSClassFromString(@"CALPreferencesPanesController") jr_addMethod:@selector(ICSwitchToView:) fromClass:self error:&error];
    if(error)
        NSLog(@"[DEBUG] Error: %@", error);
    error = nil;
    [NSClassFromString(@"CALPreferencesPanesController") jr_swizzleMethod:@selector(switchToView:) withMethod:@selector(ICSwitchToView:) error:&error];
    if(error)
        NSLog(@"[DEBUG] Error: %@", error);
}

/**
 * @return the single static instance of the plugin object
 */
+ (iCalNoPageAnimations*) sharedInstance
{
    static iCalNoPageAnimations* plugin = nil;
    
    if (plugin == nil)
        plugin = [[iCalNoPageAnimations alloc] init];
    
    return plugin;
}

- (void)switchDisableState:(id)action {
    NSButton *button = (NSButton *)action;
    if(button.state == NSOnState) {
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:YES] forKey:@"LPDisablePageAnimation"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithBool:NO] forKey:@"LPDisablePageAnimation"];
    }
}

- (BOOL)ICIsPageTransitionAnimationDisabled {
    id value = [[NSUserDefaults standardUserDefaults] valueForKey:@"LPDisablePageAnimation"];
    if(value == nil)
        return YES;
    return [value boolValue];
}

- (void)ICSwitchToView:(NSView *)view {
    NSView *lastView = [[view subviews] lastObject];
    // Only insert the checkbox if this is the correct preference pane.
    BOOL loadPreference = NO;
    if([lastView isKindOfClass:[NSButton class]] && 
       ([NSStringFromSelector([(NSButton *)lastView action]) isEqualToString:@"showAdvancedHelp:"] &&
        ![NSStringFromSelector([(NSButton *)lastView action]) isEqualToString:@"switchDisableState:"]))
        loadPreference = YES;
    if(!loadPreference) {
        [self ICSwitchToView:view];
        return;
    }
    
    NSButton *disableAnimationButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
    disableAnimationButton.buttonType = NSSwitchButton;
    disableAnimationButton.title = @"Disable Page Curl Animation";
    disableAnimationButton.font = [NSFont systemFontOfSize:13.0f];
    [disableAnimationButton sizeToFit];
    NSRect frame = disableAnimationButton.frame;
    frame.origin.y = lastView.frame.origin.y - 5;
    frame.origin.x = 41;
    disableAnimationButton.frame = frame;
    disableAnimationButton.target = [iCalNoPageAnimations sharedInstance];
    disableAnimationButton.action = @selector(switchDisableState:);
    id enabled = [[NSUserDefaults standardUserDefaults] valueForKey:@"LPDisablePageAnimation"];
    if(enabled == nil)
        disableAnimationButton.state = YES;
    else
        disableAnimationButton.state = [enabled boolValue] ? NSOnState : NSOffState;
    
    view.frame = NSMakeRect(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, view.frame.size.height + frame.size.height);
    
    [view addSubview:disableAnimationButton];
    [view setNeedsDisplay:YES];
    
    [self ICSwitchToView:view];
}

@end
