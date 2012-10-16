//
//  IAIGraphView.h
//  InAppInstrumentation
//
//  Created by Santthosh on 10/16/12.
//  Copyright (c) 2012 Santthosh. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol IAIGraphViewDataSource;

/**
 * A graph view.
 *
 *      @ingroup Overview-Pages
 */
@interface IAIGraphView : UIView {
@private
    __weak id<IAIGraphViewDataSource> _dataSource;
}

/**
 * The data source for this graph view.
 */
@property (nonatomic, readwrite, IAI_WEAK) id<IAIGraphViewDataSource> dataSource;

@end

/**
 * The data source for NIOverviewGraphView.
 *
 *      @ingroup Overview-Pages
 */
@protocol IAIGraphViewDataSource <NSObject>

@required

/**
 * Fetches the total range of all x values for this graph.
 */
- (CGFloat)graphViewXRange:(IAIGraphView *)graphView;

/**
 * Fetches the total range of all y values for this graph.
 */
- (CGFloat)graphViewYRange:(IAIGraphView *)graphView;

/**
 * The data source should reset its iterator for fetching points in the graph.
 */
- (void)resetPointIterator;

/**
 * Fetches the next point in the graph to plot.
 */
- (BOOL)nextPointInGraphView: (IAIGraphView *)graphView
                       point: (CGPoint *)point;

/**
 * The data source should reset its iterator for fetching events in the graph.
 */
- (void)resetEventIterator;

/**
 * Fetches the next event in the graph to plot.
 */
- (BOOL)nextEventInGraphView: (IAIGraphView *)graphView
                      xValue: (CGFloat *)xValue
                       color: (UIColor **)color;

@end
