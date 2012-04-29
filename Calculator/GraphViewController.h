//
//  GraphViewController.h
//  Calculator
//
//  Created by David Barton on 21/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GraphViewController : UIViewController <UISplitViewControllerDelegate>

@property (nonatomic, strong) id program;

- (void)refreshProgramDependancies;

@end
