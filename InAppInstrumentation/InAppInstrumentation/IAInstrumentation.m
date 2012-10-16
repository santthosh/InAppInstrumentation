//
//  InAppInstrumentation.m
//  InAppInstrumentation
//
//  Created by Santthosh on 10/16/12.
//  Copyright (c) 2012 Santthosh. All rights reserved.
//

#import "IAInstrumentation.h"
#import <UIKit/UIKit.h>

#ifdef DEBUG

#import "IAIDeviceInfo.h"
#import "IAIView.h"
#import "IAIPageView.h"
#import "IAILogger.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "Nimbus requires ARC support."
#endif

// Static state.
static CGFloat  sOverviewHeight   = 150;
static BOOL     sOverviewIsAwake  = NO;

static NSTimer* sOverviewHeartbeatTimer = nil;

static IAIView* sOverviewView = nil;
static IAILogger* sOverviewLogger = nil;

///////////////////////////////////////////////////////////////////////////////////////////////////
CGFloat IAIStatusBarHeight(void) {
    CGRect statusBarFrame = [[UIApplication sharedApplication] statusBarFrame];
    CGFloat statusBarHeight = MIN(statusBarFrame.size.width, statusBarFrame.size.height);
    return statusBarHeight;
}

///////////////////////////////////////////////////////////////////////////////////////////////////
UIInterfaceOrientation IAIInterfaceOrientation(void) {
    UIInterfaceOrientation orient = [UIApplication sharedApplication].statusBarOrientation;
    
    // This code used to use the navigator to find the currently visible view controller and
    // fall back to checking its orientation if we didn't know the status bar's orientation.
    // It's unclear when this was actually necessary, though, so this assertion is here to try
    // to find that case. If this assertion fails then the repro case needs to be analyzed and
    // this method made more robust to handle that case.
    IAIDASSERT(UIDeviceOrientationUnknown != orient);
    
    return orient;
}


CGAffineTransform IAIRotateTransformForOrientation(UIInterfaceOrientation orientation) {
    if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return CGAffineTransformMakeRotation((CGFloat)(M_PI * 1.5));
        
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGAffineTransformMakeRotation((CGFloat)(M_PI / 2.0));
        
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return CGAffineTransformMakeRotation((CGFloat)(-M_PI));
        
    } else {
        return CGAffineTransformIdentity;
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Logging


///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * @internal
 *
 * An undocumented method that replaces the default logging mechanism with a custom implementation.
 *
 * Your method prototype should look like this:
 *
 *   void logger(const char *message, unsigned length, BOOL withSyslogBanner)
 *
 *      @attention This method is undocumented, unsupported, and unlikely to be around
 *                 forever. Don't go using it in production code.
 *
 * Source: http://support.apple.com/kb/TA45403?viewlocale=en_US
 */
extern void _NSSetLogCStringFunction(void(*)(const char *, unsigned, BOOL));

void IAILogMethod(const char* message, unsigned length, BOOL withSyslogBanner);


///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * Pipes NSLog messages to the Overview and stderr.
 *
 * This method is passed as an argument to _NSSetLogCStringFunction to pipe all NSLog
 * messages through here.
 */
void IAILogMethod(const char* message, unsigned length, BOOL withSyslogBanner) {
    static NSDateFormatter* formatter = nil;
    if (nil == formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeStyle:NSDateFormatterMediumStyle];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
    }
    
    // Don't autorelease here in an attempt to minimize autorelease thrashing in tight
    // loops.
    
    NSString* formattedLogMessage = [[NSString alloc] initWithCString: message
                                                             encoding: NSUTF8StringEncoding];
    
    IAIConsoleLogEntry* entry = [[IAIConsoleLogEntry alloc]
                                        initWithLog:formattedLogMessage];
    
    [[IAInstrumentation logger] addConsoleLog:entry];
    
    formattedLogMessage = [[NSString alloc] initWithFormat:
                           @"%@: %s\n", [formatter stringFromDate:[NSDate date]], message];
    
    fprintf(stderr, "%s", [formattedLogMessage UTF8String]);
}

#endif

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation IAInstrumentation


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Device Orientation Changes

#ifdef DEBUG

///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)didChangeOrientation {
    static UIDeviceOrientation lastOrientation = UIDeviceOrientationUnknown;
    
    // Don't animate the overview if the device didn't actually change orientations.
    if (lastOrientation != [[UIDevice currentDevice] orientation]
        && [[UIDevice currentDevice] orientation] != UIDeviceOrientationUnknown
        && [[UIDevice currentDevice] orientation] != UIDeviceOrientationFaceUp
        && [[UIDevice currentDevice] orientation] != UIDeviceOrientationFaceDown) {
        
        // When we flip from landscape to landscape or portait to portait the animation lasts
        // twice as long.
        UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
        lastOrientation = currentOrientation;
        
        // Hide the overview right away, we'll make it fade back in when the rotation is
        // finished.
        sOverviewView.hidden = YES;
        
        // Delay showing the overview again until the rotation finishes.
        [self cancelPreviousPerformRequestsWithTarget:self];
        [self performSelector:@selector(showoverviewAfterRotation) withObject:nil
                   afterDelay:0.8];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)statusBarWillChangeFrame {
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.35];
    [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
    CGRect frame = [IAInstrumentation frame];
    sOverviewView.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    [UIView commitAnimations];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)showoverviewAfterRotation {
    // Don't modify the overview's frame directly, just modify the transform/center/bounds
    // properties so that the view is rotated with the device.
    
    sOverviewView.transform = IAIRotateTransformForOrientation(IAIInterfaceOrientation());
    
    // Fetch the frame only to calculate the center.
    CGRect frame = [IAInstrumentation frame];
    sOverviewView.center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
    
    CGRect bounds = sOverviewView.bounds;
    bounds.size.width = (UIInterfaceOrientationIsLandscape(IAIInterfaceOrientation())
                         ? frame.size.height
                         : frame.size.width);
    sOverviewView.bounds = bounds;
    
    // Get ready to fade the overview back in.
    sOverviewView.hidden = NO;
    sOverviewView.alpha = 0;
    
    [sOverviewView flashScrollIndicators];
    
    // Fade!
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.2];
    sOverviewView.alpha = 1;
    [UIView commitAnimations];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)didReceiveMemoryWarning {
    [sOverviewLogger addEventLog:
     [[IAIEventLogEntry alloc] initWithType:IAIEventDidReceiveMemoryWarning]];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)heartbeat {
    [IAIDeviceInfo beginCachedDeviceInfo];
    IAIDeviceLogEntry* logEntry =
    [[IAIDeviceLogEntry alloc] initWithTimestamp:[NSDate date]];
    logEntry.bytesOfTotalDiskSpace = [IAIDeviceInfo bytesOfTotalDiskSpace];
    logEntry.bytesOfFreeDiskSpace = [IAIDeviceInfo bytesOfFreeDiskSpace];
    logEntry.bytesOfFreeMemory = [IAIDeviceInfo bytesOfFreeMemory];
    logEntry.bytesOfTotalMemory = [IAIDeviceInfo bytesOfTotalMemory];
    logEntry.batteryLevel = [IAIDeviceInfo batteryLevel];
    logEntry.batteryState = [IAIDeviceInfo batteryState];
    [IAIDeviceInfo endCachedDeviceInfo];
    
    [sOverviewLogger addDeviceLog:logEntry];
    
    [sOverviewView updatePages];
}


#endif


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)applicationDidFinishLaunching {
#ifdef DEBUG
    if (!sOverviewIsAwake) {
        sOverviewIsAwake = YES;
        
        // Set up the logger right away so that all calls to NSLog will be captured by the
        // overview.
        _NSSetLogCStringFunction(IAILogMethod);
        
        sOverviewLogger = [[IAILogger alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(didChangeOrientation)
                                                     name: UIDeviceOrientationDidChangeNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(statusBarWillChangeFrame)
                                                     name: UIApplicationWillChangeStatusBarFrameNotification
                                                   object: nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(didReceiveMemoryWarning)
                                                     name: UIApplicationDidReceiveMemoryWarningNotification
                                                   object: nil];
        
        sOverviewHeartbeatTimer = [NSTimer scheduledTimerWithTimeInterval: 0.5
                                                                   target: self
                                                                 selector: @selector(heartbeat)
                                                                 userInfo: nil
                                                                  repeats: YES];
    }
#endif
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)addOverviewToWindow:(UIWindow *)window {
#ifdef DEBUG
    if (nil != sOverviewView) {
        // Remove the old overview in case this gets called multiple times (not sure why you would
        // though).
        [sOverviewView removeFromSuperview];
    }
    
    sOverviewView = [[IAIView alloc] initWithFrame:[self frame]];
    
    [sOverviewView addPageView:[IAIConsoleLogPageView page]];
    [sOverviewView addPageView:[IAIMemoryPageView page]];
    [sOverviewView addPageView:[IAIDiskPageView page]];
    
    // Hide the view initially because the initial frame will be wrong when the device
    // starts the app in any orientation other than portrait. Don't worry, we'll fade the
    // view in once we get our first device notification.
    sOverviewView.hidden = YES;
    
    [window addSubview:sOverviewView];
    
    NSLog(@"The overview has been added to a window.");
#endif
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (IAILogger *)logger {
#ifdef DEBUG
    return sOverviewLogger;
#else
    return nil;
#endif
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGFloat)height {
#ifdef DEBUG
    return sOverviewHeight;
#else
    return 0;
#endif
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (CGRect)frame {
#ifdef DEBUG
    UIInterfaceOrientation orient = IAIInterfaceOrientation();
    CGFloat overviewWidth;
    CGRect frame;
    
    // We can't take advantage of automatic view positioning because the overview exists
    // at the topmost view level (even above the root view controller). As such, we have to
    // calculate the frame depending on the interface orientation.
    if (orient == UIInterfaceOrientationLandscapeLeft) {
        overviewWidth = [UIScreen mainScreen].bounds.size.height;
        frame = CGRectMake(IAIStatusBarHeight(), 0, sOverviewHeight, overviewWidth);
        
    } else if (orient == UIInterfaceOrientationLandscapeRight) {
        overviewWidth = [UIScreen mainScreen].bounds.size.height;
        frame = CGRectMake([UIScreen mainScreen].bounds.size.width
                           - (IAIStatusBarHeight() + sOverviewHeight), 0,
                           sOverviewHeight, overviewWidth);
        
    } else if (orient == UIInterfaceOrientationPortraitUpsideDown) {
        overviewWidth = [UIScreen mainScreen].bounds.size.width;
        frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height
                           - (IAIStatusBarHeight() + sOverviewHeight),
                           overviewWidth, sOverviewHeight);
        
    } else if (orient == UIInterfaceOrientationPortrait) {
        overviewWidth = [UIScreen mainScreen].bounds.size.width;
        frame = CGRectMake(0, IAIStatusBarHeight(), overviewWidth, sOverviewHeight);
        
    } else {
        overviewWidth = [UIScreen mainScreen].bounds.size.width;
        frame = CGRectMake(0, IAIStatusBarHeight(), overviewWidth, sOverviewHeight);
    }
    
    if ([[UIApplication sharedApplication] isStatusBarHidden]) {
        // When the status bar is hidden we want to position the overview offscreen.
        switch (orient) {
            case UIInterfaceOrientationLandscapeLeft: {
                frame = CGRectOffset(frame, -frame.size.width, 0);
                break;
            }
            case UIInterfaceOrientationLandscapeRight: {
                frame = CGRectOffset(frame, frame.size.width, 0);
                break;
            }
            case UIInterfaceOrientationPortrait: {
                frame = CGRectOffset(frame, 0, -frame.size.height);
                break;
            }
            case UIInterfaceOrientationPortraitUpsideDown: {
                frame = CGRectOffset(frame, 0, frame.size.height);
                break;
            }
        }
    }
    return frame;
    
#else
    return CGRectZero;
#endif
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (UIView *)view {
#ifdef DEBUG
    return sOverviewView;
#else
    return nil;
#endif
}


@end

