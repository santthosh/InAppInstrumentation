//
//  IAIPageView.h
//  InAppInstrumentation
//
//  Created by Santthosh on 10/16/12.
//  Copyright (c) 2012 Santthosh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IAIGraphView.h"

#ifdef DEBUG

/**
 * A page in the Overview.
 *
 *      @ingroup Overview-Pages
 */
@interface IAIPageView : UIView {
@private
    NSString* _pageTitle;
    UILabel*  _titleLabel;
}

#pragma mark Creating a Page /** @name Creating a Page */

/**
 * Returns an autoreleased instance of this view.
 */
+ (IAIPageView *)page;


#pragma mark Updating a Page /** @name Updating a Page */

/**
 * Request that this page update its information.
 *
 * Should be implemented by the subclass. The default implementation does nothing.
 */
- (void)update;


#pragma mark Configuring a Page /** @name Configuring a Page */

/**
 * The title of the page.
 */
@property (nonatomic, readwrite, copy) NSString* pageTitle;


/**
 * The following methods are provided to aid in subclassing and are not meant to be
 * used externally.
 */
#pragma mark Subclassing /** @name Subclassing */

/**
 * The title label for this page.
 *
 * By default this label will be placed flush to the bottom middle of the page.
 */
@property (nonatomic, readonly, IAI_STRONG) UILabel* titleLabel;

/**
 * Creates a generic label for use in the page.
 */
- (UILabel *)label;

@end


/**
 * A page that renders a graph and two labels.
 *
 *      @ingroup Overview-Pages
 */
@interface IAIGraphPageView : IAIPageView <IAIGraphViewDataSource> {
@private
    UILabel* _label1;
    UILabel* _label2;
    IAIGraphView* _graphView;
    NSEnumerator* _eventEnumerator;
}

@property (nonatomic, readonly, IAI_STRONG) UILabel* label1;
@property (nonatomic, readonly, IAI_STRONG) UILabel* label2;
@property (nonatomic, readonly, IAI_STRONG) IAIGraphView* graphView;

@end


/**
 * A page that renders a graph showing free memory.
 *
 * @image html overview-memory1.png "The memory page."
 *
 *      @ingroup Overview-Pages
 */
@interface IAIMemoryPageView : IAIGraphPageView {
@private
    NSEnumerator* _enumerator;
    unsigned long long _minMemory;
}

@end


/**
 * A page that renders a graph showing free disk space.
 *
 * @image html overview-disk1.png "The disk page."
 *
 *      @ingroup Overview-Pages
 */
@interface IAIDiskPageView : IAIGraphPageView {
@private
    NSEnumerator* _enumerator;
    unsigned long long _minDiskUse;
}

@end


/**
 * A page that shows all of the logs sent to the console.
 *
 * @image html overview-log1.png "The log page."
 *
 *      @ingroup Overview-Pages
 */
@interface IAIConsoleLogPageView : IAIGraphPageView {
@private
    UIScrollView* _logScrollView;
    UILabel* _logLabel;
}

@end

#endif
