//
//  IAIView.h
//  InAppInstrumentation
//
//  Created by Santthosh on 10/16/12.
//  Copyright (c) 2012 Santthosh. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef DEBUG

@class IAIPageView;

/**
 * The root scrolling page view of the Overview.
 *
 *      @ingroup Overview
 */
@interface IAIView : UIView {
@private
    UIImage*  _backgroundImage;
    
    // State
    BOOL            _translucent;
    NSMutableArray* _pageViews;
    
    // Views
    UIScrollView* _pagingScrollView;
}

/**
 * Whether the view has a translucent background or not.
 */
@property (nonatomic, readwrite, assign) BOOL translucent;

/**
 * Adds a new page to the Overview.
 */
- (void)addPageView:(IAIPageView *)page;

/**
 * Removes a page from the Overview.
 */
- (void)removePageView:(IAIPageView *)page;

/**
 * Update all of the views.
 */
- (void)updatePages;

- (void)flashScrollIndicators;

@end

#endif