//
//  CalculatorViewController.h
//  Calculator
//
//  Created by David Barton on 26/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CalculatorBrain.h"

@interface CalculatorViewController : UIViewController

@property (weak, nonatomic) IBOutlet UILabel *display;
@property (weak, nonatomic) IBOutlet UILabel *calculation;
@property (weak, nonatomic) IBOutlet UILabel *variables;


@end
