//
//  GraphView.h
//  Calculator
//
//  Created by David Barton on 21/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GraphView;

@protocol GraphViewDataSource
- (float)YValueForXValue:(float)xValue inGraphView:(GraphView *)sender;
- (void)storeScale:(float)scale ForGraphView: (GraphView *)sender;
- (void)storeAxisOriginX:(float)x andAxisOriginY:(float)y ForGraphView: (GraphView *)sender;

@end

@interface GraphView : UIView

@property(nonatomic, weak) IBOutlet id <GraphViewDataSource> dataSource;
@property(nonatomic) CGFloat scale;
@property(nonatomic) CGPoint axisOrigin;
@property(nonatomic) BOOL drawInDotMode;

@end
