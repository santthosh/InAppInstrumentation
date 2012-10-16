//
//  IAIView.m
//  InAppInstrumentation
//
//  Created by Santthosh on 10/16/12.
//  Copyright (c) 2012 Santthosh. All rights reserved.
//

#import "IAIView.h"

#ifdef DEBUG

#import "IAIDeviceInfo.h"
#import "IAIPageView.h"

#if !defined(__has_feature) || !__has_feature(objc_arc)
#error "Nimbus requires ARC support."
#endif

@interface IAIView()

- (CGFloat)pageHorizontalMargin;
- (CGRect)frameForPagingScrollView;

@end

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
@implementation IAIView

@synthesize translucent = _translucent;


///////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _pageViews = [[NSMutableArray alloc] init];
        
        _backgroundImage = [UIImage imageNamed:@"linen.png"];
        self.backgroundColor = [UIColor colorWithPatternImage:_backgroundImage];
        self.backgroundColor = [UIColor blackColor];
        
        _pagingScrollView = [[UIScrollView alloc] initWithFrame:[self frameForPagingScrollView]];
        _pagingScrollView.pagingEnabled = YES;
        _pagingScrollView.scrollIndicatorInsets = UIEdgeInsetsMake(0, self.pageHorizontalMargin,
                                                                   0, self.pageHorizontalMargin);
        
        _pagingScrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth
                                              | UIViewAutoresizingFlexibleHeight);
        
        [self addSubview:_pagingScrollView];
    }
    return self;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Page Layout


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat)pageHorizontalMargin {
    return 10;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGRect)frameForPagingScrollView {
    CGRect frame = self.bounds;
    
    // We make the paging scroll view a little bit wider on the side edges so that there
    // there is space between the pages when flipping through them.
    frame.origin.x -= self.pageHorizontalMargin;
    frame.size.width += (2 * self.pageHorizontalMargin);
    
    return frame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGSize)contentSizeForPagingScrollView {
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [_pageViews count], bounds.size.height);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (CGRect)frameForPageAtIndex:(NSInteger)pageIndex {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page
    // placement. When the device is in landscape orientation, the frame will still be in
    // portrait because the pagingScrollView is the root view controller's view, so its
    // frame is in window coordinate space, which is never rotated. Its bounds, however,
    // will be in landscape because it has a rotation transform applied.
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    
    // We need to counter the extra spacing added to the paging scroll view in
    // frameForPagingScrollView:
    pageFrame.size.width -= self.pageHorizontalMargin * 2;
    pageFrame.origin.x = (bounds.size.width * pageIndex) + self.pageHorizontalMargin;
    
    return pageFrame;
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)layoutPages {
    _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
    
    for (NSUInteger ix = 0; ix < [_pageViews count]; ++ix) {
        UIView* pageView = [_pageViews objectAtIndex:ix];
        pageView.frame = [self frameForPageAtIndex:ix];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (NSInteger)visiblePageIndex {
    CGFloat offset = _pagingScrollView.contentOffset.x;
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    
    return (NSInteger)(offset / pageWidth);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setBounds:(CGRect)bounds {
    NSInteger visiblePageIndex = [self visiblePageIndex];
    
    [super setBounds:bounds];
    
    [self layoutPages];
    
    CGFloat pageWidth = _pagingScrollView.bounds.size.width;
    CGFloat newOffset = (visiblePageIndex * pageWidth);
    _pagingScrollView.contentOffset = CGPointMake(newOffset, 0);
}


///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Public Methods


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setTranslucent:(BOOL)translucent {
    if (_translucent != translucent) {
        _translucent = translucent;
        
        _pagingScrollView.indicatorStyle = (_translucent
                                            ? UIScrollViewIndicatorStyleWhite
                                            : UIScrollViewIndicatorStyleDefault);
        
        self.backgroundColor = (_translucent
                                ? [UIColor colorWithWhite:0 alpha:0.5f]
                                : [UIColor colorWithPatternImage:_backgroundImage]);
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)addPageView:(IAIPageView *)page {
    [_pageViews addObject:page];
    [_pagingScrollView addSubview:page];
    
    [self layoutPages];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)removePageView:(IAIPageView *)page {
    [_pageViews removeObject:page];
    [page removeFromSuperview];
    
    [self layoutPages];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)updatePages {
    for (IAIPageView* pageView in _pageViews) {
        [pageView update];
    }
}


///////////////////////////////////////////////////////////////////////////////////////////////////
- (void)flashScrollIndicators {
    [_pagingScrollView flashScrollIndicators];
}


@end

#endif
