//
//  CalculatorViewController.m
//  Calculator
//
//  Created by David Barton on 26/03/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CalculatorViewController.h"
#import "GraphViewController.h"

@interface CalculatorViewController ()

@property (nonatomic) BOOL userIsInTheMiddleOfEnteringNumber;
@property (nonatomic, strong) NSDictionary *testVariableValues;
@property (nonatomic, strong) CalculatorBrain *brain;

@end

@implementation CalculatorViewController

@synthesize display = _display;
@synthesize calculation = _calculation;
@synthesize variables = _variables;
@synthesize popoverDelegate = _popoverDelegate;
@synthesize brain = _brain;

@synthesize userIsInTheMiddleOfEnteringNumber;

@synthesize testVariableValues = _testVariableValues;

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
	return self.splitViewController ? 
	YES : UIInterfaceOrientationIsPortrait(toInterfaceOrientation);
}


- (GraphViewController *)graphViewController {
	return self.popoverDelegate ? 
	self.popoverDelegate :[self.splitViewController.viewControllers lastObject];
}


- (CalculatorBrain *)brain {
	if (self.popoverDelegate) _brain = [[self.popoverDelegate masterViewController] brain];
	if (!_brain) _brain = [[CalculatorBrain alloc] init];
	return _brain;
}


- (void)setBrain:(CalculatorBrain *)brain {
	_brain = brain;
}

- (NSDictionary *)testVariableValues {
	if (!_testVariableValues) {
		_testVariableValues = [NSDictionary dictionaryWithObjectsAndKeys:
									  [NSNumber numberWithDouble:5], @"x",
									  [NSNumber numberWithDouble:4.8], @"a",
									  [NSNumber numberWithDouble:0], @"b", nil];
	}
	return _testVariableValues;
}

- (NSDictionary *)programVariableValues {   
	
	// Find the variables in the current program in the brain as an array
	NSArray *variableArray = 
	[[CalculatorBrain variablesUsedInProgram:self.brain.program] allObjects];
	
	// Return a description of a dictionary which contains keys and values for the keys 
	// that are in the variable array
	return [self.testVariableValues dictionaryWithValuesForKeys:variableArray];
}

-(void)synchronizeView {   
	
	// Find the result by running the program passing in the test variable values
	id result = [CalculatorBrain runProgram:self.brain.program 
							  usingVariableValues:self.testVariableValues];   
	
	// If the result is a string, then display it, otherwise get the Number's description
	if ([result isKindOfClass:[NSString class]])    self.display.text = result;
	else self.display.text = [NSString stringWithFormat:@"%g", [result doubleValue]];
	
	// Now the calculation label, from the latest description of program    
	self.calculation.text = 
	[CalculatorBrain descriptionOfProgram:self.brain.program];
	
	// And finally the variables text, with a bit of formatting
	self.variables.text = [[[[[[[self programVariableValues] description]
										stringByReplacingOccurrencesOfString:@"{" withString:@""]
									  stringByReplacingOccurrencesOfString:@"}" withString:@""]
									 stringByReplacingOccurrencesOfString:@";" withString:@""]
									stringByReplacingOccurrencesOfString:@"\"" withString:@""]
								  stringByReplacingOccurrencesOfString:@"<null>" withString:@"0"];
	
	// And the user isn't in the middle of entering a number
	self.userIsInTheMiddleOfEnteringNumber = NO;
}


- (IBAction)digitPressed:(UIButton *)sender {
	NSString *digit = [sender currentTitle];
	
	if (self.userIsInTheMiddleOfEnteringNumber) {
		self.display.text = [self.display.text stringByAppendingString:digit]; 
	} else {
		self.display.text = digit;
		self.userIsInTheMiddleOfEnteringNumber = YES;
	}    
}

- (IBAction)operationPressed:(UIButton *)sender {
	
	if (self.userIsInTheMiddleOfEnteringNumber) {
		[self enterPressed];
	}	
	
	[self.brain pushOperation:[sender currentTitle]];
	[self synchronizeView];	
}

- (IBAction)enterPressed {
	[self.brain pushOperand:[self.display.text doubleValue]];
	[self synchronizeView];	
}

- (IBAction)pointPressed {  
	
	// If the user isn't in the middle of entering number then display 
	// should be set to 0.
	if (!self.userIsInTheMiddleOfEnteringNumber) {
		self.display.text = @"0.";		
	} else { // Add a . into the number if there isn't already one there
		NSRange range = [self.display.text rangeOfString:@"."]; 		
		if (range.location == NSNotFound) {
			self.display.text = [self.display.text stringByAppendingString:@"."];
		}			
	}        
	self.userIsInTheMiddleOfEnteringNumber = YES;    
}

- (IBAction)clearPressed {
	[self.brain empty];
	[self synchronizeView];	
}

- (IBAction)signChangePressed:(UIButton *)sender {
	
	if (self.userIsInTheMiddleOfEnteringNumber) {        
		if ([[self.display.text substringToIndex:1] isEqualToString:@"-"]) {            
			self.display.text = [self.display.text substringFromIndex:1];
		} else {
			self.display.text = [@"-" stringByAppendingString:self.display.text]; 
		}
	} else {
		[self operationPressed:sender];
	}    
}

- (IBAction)variablePressed:(UIButton *)sender {
	[self.brain pushVariable:sender.currentTitle];
	[self synchronizeView];
}

- (IBAction)undoPressed {
	if (self.userIsInTheMiddleOfEnteringNumber) {
		// Remove the last digit or point from the display
		self.display.text =[self.display.text substringToIndex:
								  [self.display.text length] - 1]; 
		
		// If we are left with no digits or a "-" digit
		if ( [self.display.text isEqualToString:@""]
			 || [self.display.text isEqualToString:@"-"]) {
			
			[self synchronizeView];     
		}   
	} else {
		// Remove the last item from the stack and synchronize the view
		[self.brain removeLastItem];
		[self synchronizeView];
	}   
}

- (IBAction)drawGraphPressed {
	
	if ([self graphViewController]) {
		[[self graphViewController] setProgram:self.brain.program];
		[[self graphViewController] refreshProgramDependancies];
	} else {
		[self performSegueWithIdentifier:@"ShowGraph" sender:self];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
	[segue.destinationViewController setProgram:self.brain.program];
}

// Some different numbers to the defaults
- (IBAction)test1Pressed {
	self.testVariableValues = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithDouble:-4], @"x",
										[NSNumber numberWithDouble:3], @"a",
										[NSNumber numberWithDouble:4], @"b", nil];
	[self synchronizeView];
}

// Testing when only one number is provided
- (IBAction)test2Pressed {
	self.testVariableValues = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithDouble:-5], @"x", nil];
	[self synchronizeView]; 
}

// Should revert back to default values
- (IBAction)testNilPressed {
	self.testVariableValues = nil;  
	[self synchronizeView];
}

- (IBAction)brainPressed {
	
	CalculatorBrain *testBrain = [self brain];
	
	// Test a
	[testBrain empty];
	[testBrain pushOperand:3];
	[testBrain pushOperand:5];
	[testBrain pushOperand:6];
	[testBrain pushOperand:7];
	[testBrain pushOperation:@"+"];
	[testBrain pushOperation:@"*"];
	[testBrain pushOperation:@"-"];
	
	// Test b
	[testBrain pushOperand:3];
	[testBrain pushOperand:5];
	[testBrain pushOperation:@"+"];
	[testBrain pushOperation:@"sqrt"];
	
	// Test c
	//[testBrain empty];
	[testBrain pushOperand:3];
	[testBrain pushOperation:@"sqrt"];
	[testBrain pushOperation:@"sqrt"];
	
	// Test d
	[testBrain pushOperand:3];
	[testBrain pushOperand:5];
	[testBrain pushOperation:@"sqrt"];
	[testBrain pushOperation:@"+"];
	
	// Test e
	[testBrain pushOperation:@"?"];
	[testBrain pushVariable:@"r"];
	[testBrain pushVariable:@"r"];
	[testBrain pushOperation:@"*"];
	[testBrain pushOperation:@"*"];
	
	// Test f
	[testBrain pushVariable:@"a"];
	[testBrain pushVariable:@"a"];
	[testBrain pushOperation:@"*"];
	[testBrain pushVariable:@"b"];
	[testBrain pushVariable:@"b"];
	[testBrain pushOperation:@"*"];
	[testBrain pushOperation:@"+"];
	[testBrain pushOperation:@"sqrt"];
	
	//Print the description
	NSLog(@"Program is :%@",[CalculatorBrain descriptionOfProgram:[testBrain program]]);
	[testBrain empty];
}

- (void)viewDidAppear:(BOOL)animated {
	[self synchronizeView];
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

@end
