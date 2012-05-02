//
//  GraphViewController.m
//  Calculator
//
//  Created by David Barton on 21/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GraphViewController.h"
#import "CalculatorBrain.h"
#import "GraphView.h"
#import "CalculatorViewController.h"

@interface GraphViewController () <GraphViewDataSource, MasterViewControllerPopoverDelegate>

@property (nonatomic, weak) IBOutlet GraphView *graphView;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (strong, nonatomic) UIPopoverController *popover;

@end

@implementation GraphViewController

@synthesize program = _program;
@synthesize graphView = _graphView;
@synthesize toolbar = _toolbar;
@synthesize popover = _popover;

@synthesize masterViewController = _masterViewController;


- (id)masterViewController {
	return [self.splitViewController.viewControllers objectAtIndex:0];	
}

- (void)awakeFromNib {
	[super awakeFromNib];
	self.splitViewController.delegate = self;
	self.splitViewController.presentsWithGesture = NO;	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return YES;
}

- (BOOL)splitViewController:(UISplitViewController *)svc 
	shouldHideViewController:(UIViewController *)vc 
				  inOrientation:(UIInterfaceOrientation)orientation {	

	// Hide the the master controller in portrait mode
	return UIInterfaceOrientationIsPortrait(orientation);
}

- (void)splitViewController:(UISplitViewController *)svc 
	  willHideViewController:(UIViewController *)aViewController 
			 withBarButtonItem:(UIBarButtonItem *)barButtonItem 
		 forPopoverController:(UIPopoverController *)pc {
	
	// Show the bar button item on the toolbar
	barButtonItem.title = aViewController.title;
	
	//self.popover = [[UIPopoverController alloc] initWithContentViewController:aViewController];
	
	barButtonItem.target = self;
	barButtonItem.action = @selector(barButtonPressed:);
		
	// Add the button to the toolbar
	NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
	[toolbarItems insertObject:barButtonItem atIndex:0];
	self.toolbar.items = toolbarItems;	
	
}


- (void)barButtonPressed:(id) sender {	
	
	//[self.popover presentPopoverFromBarButtonItem:sender 
	//						permittedArrowDirections:UIPopoverArrowDirectionAny 
	//											 animated:YES];
  	
   [self performSegueWithIdentifier:@"ShowCalculator" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	[segue.destinationViewController setPopoverDelegate:self];	
	self.popover = ((UIStoryboardPopoverSegue *)segue).popoverController;
}

- (void) splitViewController:(UISplitViewController *)svc 
		willShowViewController:(UIViewController *)aViewController 
	invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem {
	
	// Hide the bar button item on the detail controller
	NSMutableArray *toolbarItems = [self.toolbar.items mutableCopy];
	[toolbarItems removeObject:barButtonItem];
	self.toolbar.items = toolbarItems;
	
	if (self.popover) [self.popover dismissPopoverAnimated:YES];
	
}

- (void)refreshProgramDependancies {

	// Need a program to recall scale and axis origin
	if (! self.program) return;
	
	// Need a graph view to set initial scale and axis origin
	if (! self.graphView) return;
	
	NSString *program = [CalculatorBrain descriptionOfProgram:self.program];
	
	// Retrieve the scale from storage
	float scale = [[NSUserDefaults standardUserDefaults] 
						floatForKey:[@"scale." stringByAppendingString:program]];	
	
	// Retrieve the x axis origin from storage
	float xAxisOrigin = [[NSUserDefaults standardUserDefaults] 
								floatForKey:[@"x." stringByAppendingString:program]];
	
	// Retrieve the y axis origin from storage
	float yAxisOrigin = [[NSUserDefaults standardUserDefaults]
								floatForKey:[@"y." stringByAppendingString:program]];
	
	// If we have scale in storage, then set this as the scale for the graph view
	if (scale) self.graphView.scale = scale;
	
	// If we have a value for the xAxisOrigin and yAxisOrigin then set it in the graph view
	if (xAxisOrigin && yAxisOrigin) {
		
		CGPoint axisOrigin;
		
		axisOrigin.x = xAxisOrigin;
		axisOrigin.y = yAxisOrigin;
		
		self.graphView.axisOrigin = axisOrigin;
	}
	
	// Refresh the graph View
	[self.graphView setNeedsDisplay];

}

- (void) setProgram:(id)program {
	
	_program = program;

	// We want to set the title of the controller if the program changes
	self.title = [NSString stringWithFormat:@"y = %@", 
					  [CalculatorBrain descriptionOfProgram:self.program]];
} 


- (void) setGraphView:(GraphView *)graphView {
	_graphView = graphView;
	self.graphView.dataSource = self;
	
	// enable pinch gesture in the GraphView using pinch: handler
	[self.graphView addGestureRecognizer:[[UIPinchGestureRecognizer alloc] 
													  initWithTarget:self.graphView 
													  action:@selector(pinch:)]];

	// enable pan gesture in the GraphView using pan: handler
	[self.graphView addGestureRecognizer:[[UIPanGestureRecognizer alloc]
													  initWithTarget:self.graphView
													  action:@selector(pan:)]];
	
	// enable triple tap gesture in the GraphView using tripleTap: handler	
	UITapGestureRecognizer *tapGestureRecognizer = 
		[[UITapGestureRecognizer alloc] initWithTarget:self.graphView 
															 action:@selector(tripleTap:)];	
	tapGestureRecognizer.numberOfTapsRequired = 3;
	[self.graphView addGestureRecognizer:tapGestureRecognizer];	
	
	// We want to update the graphView to set the starting values for the program. In iPad mode 
	// this method is called before a program is set, in which case we don't want to do anything
	[self refreshProgramDependancies];
}

- (IBAction)drawModeSwitched:(id)sender {
	self.graphView.drawInDotMode = [(UISwitch *)sender isOn];
	[self.graphView setNeedsDisplay];	
}

- (void)storeScale:(float)scale ForGraphView:(GraphView *)sender {
	
	// Store the scale in user defaults
	[[NSUserDefaults standardUserDefaults] 
	 setFloat:scale forKey:[@"scale." stringByAppendingString:
									[CalculatorBrain descriptionOfProgram:self.program]]];	
	
	// Save the scale
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)storeAxisOriginX:(float)x andAxisOriginY:(float)y ForGraphView:(GraphView *)sender {
	
	
	NSString *program = [CalculatorBrain descriptionOfProgram:self.program];
	
	// Store the x axis origin in user defaults
	[[NSUserDefaults standardUserDefaults] setFloat:x 
														  forKey:[@"x." stringByAppendingString:program]];
	
	// Store the y axis origin in user defaults
	[[NSUserDefaults standardUserDefaults] setFloat:y 
														  forKey:[@"y." stringByAppendingString:program]];
	
	// Save the axis origin
	[[NSUserDefaults standardUserDefaults] synchronize];

}
	 
- (float)YValueForXValue:(float)xValue inGraphView:(GraphView *)sender {
	
	// Find the corresponding Y value by passing the x value to the calculator Brain
	id yValue = [CalculatorBrain runProgram:self.program usingVariableValues:
					 [NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:xValue] 
														  forKey:@"x"]];

	return ((NSNumber *)yValue).floatValue;	
}


- (void)viewDidUnload {
	[self setToolbar:nil];
	[super viewDidUnload];
}


@end
