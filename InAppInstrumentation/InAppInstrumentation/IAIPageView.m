//
//  IAIPageView.m
//  InAppInstrumentation
//
//  Created by Santthosh on 10/16/12.
//  Copyright (c) 2012 Santthosh. All rights reserved.
//

#import "IAIPageView.h"

#ifdef DEBUG

#import "IAInstrumentation.h"
#import "IAIDeviceInfo.h"
#import "IAIGraphView.h"
#import "IAILogger.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "Nimbus requires ARC support."
#endif

static UIEdgeInsets kPagePadding;
static const CGFloat kGraphRightMargin = 5;

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation IAIPageView

@synthesize pageTitle = _pageTitle;
@synthesize titleLabel = _titleLabel;


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (void)initialize {
    kPagePadding = UIEdgeInsetsMake(5, 5, 10, 5);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
+ (IAIPageView *)page {
    return [[[self class] alloc] initWithFrame:CGRectZero];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UILabel *)label {
    UILabel* label = [[UILabel alloc] init];
    label.backgroundColor = [UIColor clearColor];
    label.font = [UIFont boldSystemFontOfSize:12];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor colorWithWhite:0 alpha:0.5f];
    label.shadowOffset = CGSizeMake(0, 1);
    
    return label;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.clipsToBounds = YES;
        
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:11];
        _titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.8f];
        [self addSubview:_titleLabel];
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
    [super layoutSubviews];
    
    [_titleLabel sizeToFit];
    CGRect frame = _titleLabel.frame;
    frame.origin.x = floorf((self.bounds.size.width - frame.size.width) / 2);
    frame.origin.y = self.bounds.size.height - frame.size.height;
    _titleLabel.frame = frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setPageTitle:(NSString *)pageTitle {
    if (_pageTitle != pageTitle) {
        _pageTitle = [pageTitle copy];
        
        _titleLabel.text = _pageTitle;
        [self setNeedsLayout];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)update {
    // No-op.
}


@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation IAIGraphPageView

@synthesize label1 = _label1;
@synthesize label2 = _label2;
@synthesize graphView = _graphView;


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.pageTitle = NSLocalizedString(@"Memory", @"Overview Page Title: Memory");
        
        _label1 = [self label];
        [self addSubview:_label1];
        _label2 = [self label];
        [self addSubview:_label2];
        
        _graphView = [[IAIGraphView alloc] init];
        _graphView.dataSource = self;
        [self addSubview:_graphView];
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat contentWidth = self.frame.size.width - kPagePadding.left - kPagePadding.right;
    CGFloat contentHeight = self.frame.size.height - kPagePadding.top - kPagePadding.bottom;
    
    [_label1 sizeToFit];
    [_label2 sizeToFit];
    
    CGFloat maxLabelWidth = MAX(_label1.frame.size.width,
                                _label2.frame.size.width);
    CGFloat remainingContentWidth = contentWidth - maxLabelWidth - kGraphRightMargin;
    
    CGRect frame = _label1.frame;
    frame.origin.x = kPagePadding.left + remainingContentWidth + kGraphRightMargin;
    frame.origin.y = kPagePadding.top;
    _label1.frame = frame;
    
    frame = _label2.frame;
    frame.origin.x = kPagePadding.left + remainingContentWidth + kGraphRightMargin;
    frame.origin.y = CGRectGetMaxY(_label1.frame);
    _label2.frame = frame;
    
    frame = self.titleLabel.frame;
    frame.origin.x = kPagePadding.left + remainingContentWidth + kGraphRightMargin;
    frame.origin.y = CGRectGetMaxY(_label2.frame);
    self.titleLabel.frame = frame;
    
    _graphView.frame = CGRectMake(kPagePadding.left, kPagePadding.top,
                                  remainingContentWidth, contentHeight);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)update {
    [_graphView setNeedsDisplay];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IAIGraphViewDataSource


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)graphViewXRange:(IAIGraphView *)graphView {
    IAILinkedList* deviceLogs = [[IAInstrumentation logger] deviceLogs];
    IAILogEntry* firstEntry = [deviceLogs firstObject];
    IAILogEntry* lastEntry = [deviceLogs lastObject];
    NSTimeInterval interval = [lastEntry.timestamp timeIntervalSinceDate:firstEntry.timestamp];
    return (CGFloat)interval;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)graphViewYRange:(IAIGraphView *)graphView {
    return 0;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)resetPointIterator {
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)nextPointInGraphView: (IAIGraphView *)graphView
                       point: (CGPoint *)point {
    return NO;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDate *)initialTimestamp {
    return nil;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)resetEventIterator {
    _eventEnumerator = [[[IAInstrumentation logger] eventLogs] objectEnumerator];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)nextEventInGraphView: (IAIGraphView *)graphView
                      xValue: (CGFloat *)xValue
                       color: (UIColor **)color {
    static NSArray* sEventColors = nil;
    if (nil == sEventColors) {
        sEventColors = [NSArray arrayWithObjects:
                        [UIColor redColor], // IAIEventDidReceiveMemoryWarning
                        nil];
    }
    IAIEventLogEntry* entry = [_eventEnumerator nextObject];
    if (nil != entry) {
        NSTimeInterval interval = [entry.timestamp timeIntervalSinceDate:[self initialTimestamp]];
        *xValue = (CGFloat)interval;
        *color = [sEventColors objectAtIndex:entry.type];
    }
    return nil != entry;
}


@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation IAIMemoryPageView


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.pageTitle = NSLocalizedString(@"Memory", @"Overview Page Title: Memory");
        
        self.graphView.dataSource = self;
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)update {
    [super update];
    
    [IAIDeviceInfo beginCachedDeviceInfo];
    
    self.label1.text = [NSString stringWithFormat:@"%@ free",
                        NIStringFromBytes([IAIDeviceInfo bytesOfFreeMemory])];
    
    self.label2.text = [NSString stringWithFormat:@"%@ total",
                        NIStringFromBytes([IAIDeviceInfo bytesOfTotalMemory])];
    
    [IAIDeviceInfo endCachedDeviceInfo];
    
    [self setNeedsLayout];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IAIGraphViewDataSource


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)graphViewYRange:(IAIGraphView *)graphView {
    IAILinkedList* deviceLogs = [[IAInstrumentation logger] deviceLogs];
    if ([deviceLogs count] == 0) {
        return 0;
    }
    
    unsigned long long minY = (unsigned long long)-1;
    unsigned long long maxY = 0;
    for (IAIDeviceLogEntry* entry in deviceLogs) {
        minY = MIN(entry.bytesOfFreeMemory, minY);
        maxY = MAX(entry.bytesOfFreeMemory, maxY);
    }
    unsigned long long range = maxY - minY;
    _minMemory = minY;
    return (CGFloat)((double)range / 1024.0 / 1024.0);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)resetPointIterator {
    _enumerator = [[[IAInstrumentation logger] deviceLogs] objectEnumerator];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDate *)initialTimestamp {
    IAILinkedList* deviceLogs = [[IAInstrumentation logger] deviceLogs];
    IAILogEntry* firstEntry = [deviceLogs firstObject];
    return firstEntry.timestamp;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)nextPointInGraphView: (IAIGraphView *)graphView
                       point: (CGPoint *)point {
    IAIDeviceLogEntry* entry = [_enumerator nextObject];
    if (nil != entry) {
        NSTimeInterval interval = [entry.timestamp timeIntervalSinceDate:[self initialTimestamp]];
        *point = CGPointMake((CGFloat)interval,
                             (CGFloat)(((double)(entry.bytesOfFreeMemory - _minMemory))
                                       / 1024.0 / 1024.0));
    }
    return nil != entry;
}


@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation IAIDiskPageView


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.pageTitle = NSLocalizedString(@"Storage", @"Overview Page Title: Storage");
        
        self.graphView.dataSource = self;
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)update {
    [super update];
    
    [IAIDeviceInfo beginCachedDeviceInfo];
    
    self.label1.text = [NSString stringWithFormat:@"%@ free",
                        NIStringFromBytes([IAIDeviceInfo bytesOfFreeDiskSpace])];
    
    self.label2.text = [NSString stringWithFormat:@"%@ total",
                        NIStringFromBytes([IAIDeviceInfo bytesOfTotalDiskSpace])];
    
    [IAIDeviceInfo endCachedDeviceInfo];
    
    [self setNeedsLayout];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark IAIGraphViewDataSource


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)graphViewYRange:(IAIGraphView *)graphView {
    IAILinkedList* deviceLogs = [[IAInstrumentation logger] deviceLogs];
    if ([deviceLogs count] == 0) {
        return 0;
    }
    
    unsigned long long minY = (unsigned long long)-1;
    unsigned long long maxY = 0;
    for (IAIDeviceLogEntry* entry in deviceLogs) {
        minY = MIN(entry.bytesOfFreeDiskSpace, minY);
        maxY = MAX(entry.bytesOfFreeDiskSpace, maxY);
    }
    unsigned long long range = maxY - minY;
    _minDiskUse = minY;
    return (CGFloat)((double)range / 1024.0 / 1024.0);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)resetPointIterator {
    _enumerator = [[[IAInstrumentation logger] deviceLogs] objectEnumerator];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSDate *)initialTimestamp {
    IAILinkedList* deviceLogs = [[IAInstrumentation logger] deviceLogs];
    IAILogEntry* firstEntry = [deviceLogs firstObject];
    return firstEntry.timestamp;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL)nextPointInGraphView: (IAIGraphView *)graphView
                       point: (CGPoint *)point {
    IAIDeviceLogEntry* entry = [_enumerator nextObject];
    if (nil != entry) {
        NSTimeInterval interval = [entry.timestamp timeIntervalSinceDate:[self initialTimestamp]];
        double difference = ((double)entry.bytesOfFreeDiskSpace / 1024.0 / 1024.0
                             - (double)_minDiskUse / 1024.0 / 1024.0);
        *point = CGPointMake((CGFloat)interval, (CGFloat)difference);
    }
    return nil != entry;
}


@end


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation IAIConsoleLogPageView


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)dealloc {
    [[NSOperationQueue mainQueue] removeObserver:self];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (UILabel *)label {
    UILabel* label = [[UILabel alloc] init];
    
    label.font = [UIFont boldSystemFontOfSize:11];
    label.textColor = [UIColor whiteColor];
    label.shadowColor = [UIColor colorWithWhite:0 alpha:0.5f];
    label.shadowOffset = CGSizeMake(0, 1);
    label.backgroundColor = [UIColor clearColor];
    label.lineBreakMode = UILineBreakModeWordWrap;
    label.numberOfLines = 0;
    
    return label;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.pageTitle = NSLocalizedString(@"Logs", @"Overview Page Title: Logs");
        
        self.titleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.5f];
        
        _logScrollView = [[UIScrollView alloc] initWithFrame:self.bounds];
        _logScrollView.showsHorizontalScrollIndicator = NO;
        _logScrollView.alwaysBounceVertical = YES;
        _logScrollView.contentInset = kPagePadding;
        
        //_logScrollView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.2f];
        
        [self addSubview:_logScrollView];
        
        _logLabel = [self label];
        [_logScrollView addSubview:_logLabel];
        
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(didAddLog:)
                                                     name: IAILoggerDidAddConsoleLog
                                                   object: nil];
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)contentSizeChanged {
    BOOL isBottomNearby = NO;
    if (_logScrollView.contentOffset.y + _logScrollView.bounds.size.height
        >= _logScrollView.contentSize.height - _logScrollView.bounds.size.height) {
        isBottomNearby = YES;
    }
    
    _logScrollView.frame = CGRectMake(0, 0,
                                      self.bounds.size.width,
                                      self.bounds.size.height);
    
    CGSize labelSize = [_logLabel.text sizeWithFont: _logLabel.font
                                  constrainedToSize: CGSizeMake(_logScrollView.bounds.size.width,
                                                                CGFLOAT_MAX)
                                      lineBreakMode: _logLabel.lineBreakMode];
    _logLabel.frame = CGRectMake(0, 0,
                                 labelSize.width, labelSize.height);
    
    _logScrollView.contentSize = CGSizeMake(_logScrollView.bounds.size.width
                                            - kPagePadding.left - kPagePadding.right,
                                            _logLabel.frame.size.height);
    
    if (isBottomNearby) {
        _logScrollView.contentOffset = CGPointMake(-kPagePadding.left,
                                                   MAX(_logScrollView.contentSize.height
                                                       - _logScrollView.bounds.size.height
                                                       + kPagePadding.top,
                                                       -kPagePadding.top));
        [_logScrollView flashScrollIndicators];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    [self contentSizeChanged];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect labelFrame = self.titleLabel.frame;
    labelFrame.origin.x = (self.bounds.size.width
                           - kPagePadding.right - self.titleLabel.frame.size.width);
    labelFrame.origin.y = (self.bounds.size.height
                           - kPagePadding.bottom - self.titleLabel.frame.size.height);
    self.titleLabel.frame = labelFrame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)didAddLog:(NSNotification *)notification {
    IAIConsoleLogEntry* entry = [[notification userInfo] objectForKey:@"entry"];
    
    static NSDateFormatter* formatter = nil;
    if (nil == formatter) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        [formatter setDateStyle:NSDateFormatterNoStyle];
    }
    
    NSString* formattedLog = [NSString stringWithFormat:@"%@: %@",
                              [formatter stringFromDate:entry.timestamp],
                              entry.log];
    
    if (nil != _logLabel.text) {
        _logLabel.text = [_logLabel.text stringByAppendingFormat:@"\n%@", formattedLog];
    } else {
        _logLabel.text = formattedLog;
    }
    
    [self contentSizeChanged];
}

@end

#endif

