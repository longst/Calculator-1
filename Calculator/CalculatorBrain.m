//
//  CalculatorBrain.m
//  Calculator
//
//  Created by David Barton on 27/02/2012.
//  Copyright (c) 2012. All rights reserved.
//

#import "CalculatorBrain.h"

@interface CalculatorBrain()

@property (nonatomic, strong) NSMutableArray *programStack;


@end

@implementation CalculatorBrain

static NSDictionary *OPERAND_COUNTS;

@synthesize programStack = _programStack;

- (NSMutableArray *)programStack {
	if (_programStack == nil) _programStack = [[NSMutableArray alloc] init];
	return _programStack;
}

+ (NSDictionary *)operandCounts {
	if (OPERAND_COUNTS == nil) {
		OPERAND_COUNTS = [NSDictionary dictionaryWithObjectsAndKeys: 
								[NSNumber numberWithInt:0], @"π", 
								[NSNumber numberWithInt:1], @"sin",
								[NSNumber numberWithInt:1], @"cos", 
								[NSNumber numberWithInt:1], @"sqrt",
								[NSNumber numberWithInt:1], @"±", 
								[NSNumber numberWithInt:2], @"+", 
								[NSNumber numberWithInt:2], @"-", 
								[NSNumber numberWithInt:2], @"*", 
								[NSNumber numberWithInt:2], @"/", nil];
	}
	return OPERAND_COUNTS;
}

- (id)program {	
	return [self.programStack copy];
}

- (void)pushOperand:(double)operand {		
	[self.programStack addObject:[NSNumber numberWithDouble:operand]];    
}

- (void)pushVariable:(NSString *) variable {
	[self.programStack addObject:variable];	
}

- (void)pushOperation:(NSString *) operation {
	[self.programStack addObject:operation];	
}

- (id)performOperation:(NSString *)operation {	
	[self pushOperation:operation];
	return [[self class] runProgram:self.programStack];	
}

- (void)empty {
	self.programStack = nil;
}

- (void)removeLastItem {
	[self.programStack removeLastObject];
}

+ (BOOL)isNoOperandOperation:(NSString *)operation {
	
	return [[self operandCounts] objectForKey:operation] == [NSNumber numberWithInt:0];
}

+ (BOOL)isOneOperandOperation:(NSString *)operation {
	
	return [[self operandCounts] objectForKey:operation] == [NSNumber numberWithInt:1];
}

+ (BOOL)isTwoOperandOperation:(NSString *)operation {
	
	return [[self operandCounts] objectForKey:operation] == [NSNumber numberWithInt:2];
}

+ (BOOL)isOperation:(NSString *)operation {	
	
	// Check to see if it's in the operandCounts dictionary
	return [[self operandCounts] objectForKey:operation] != nil;
}

+ (BOOL)isValidProgram:(id)program {
	// It's valid if it's an NSArray
	return [program isKindOfClass:[NSArray class]];
}

+ (NSString *)deBracket:(NSString *)expression {
	
	NSString *description = expression;
	
	// Check to see if there is a bracket at the start and end of the expression
	// If so, then strip the description of these brackets and return.
	if ([expression hasPrefix:@"("] && [expression hasSuffix:@")"]) {
		description = [description substringFromIndex:1];
		description = [description substringToIndex:[description length] - 1];
	}	
	
	// Also need to do a final check, to cover the case where removing the brackets
	// results in a + b) * (c + d. Have a look at the position of the brackets and
	// if there is a ) before a (, then we need to revert back to expression
	NSRange openBracket = [description rangeOfString:@"("];
	NSRange closeBracket = [description rangeOfString:@")"];
	
	if (openBracket.location <= closeBracket.location) return description;
	else return expression;	
}


+ (NSString *)descriptionOffTopOfStack:(NSMutableArray *)stack {
	
	NSString *description;
	
	// Retrieve and remove the object at the top of the stack 
	id topOfStack = [stack lastObject];
	if (topOfStack) [stack removeLastObject]; else return @"";
	
	// If the top of stack is an NSNumber then just return it as a NSString
	if ([topOfStack isKindOfClass:[NSNumber class]]) {
		return [topOfStack description];
	}		
	// but if it's an NSString we need to do some formatting
	else if ([topOfStack isKindOfClass:[NSString class]]) {	
		// If top of stack is a no operand operation, or it's a variable then we
		// want to return description in the form "x"
		if (![self isOperation:topOfStack] ||
			 [self isNoOperandOperation:topOfStack]) {	
			description = topOfStack;
		} 
		// If the top of stack is one operand operation, then we want to return an
		// expression in the form "f(x)"
		else if ([self isOneOperandOperation:topOfStack]) {
			// We need to remove any outside brackets on the recursive description
			// because we are going to put some new brackets on.
			NSString *x = [self deBracket:[self descriptionOffTopOfStack:stack]];
			description = [NSString stringWithFormat:@"%@(%@)", topOfStack, x];	
		}
		// If the top of stack is a two operand operation then we want to return
		// an expression in the form "x op. y".
		else if ([self isTwoOperandOperation:topOfStack]) {
			NSString *y = [self descriptionOffTopOfStack:stack];
			NSString *x = [self descriptionOffTopOfStack:stack];
			
			// If the top of stack is For + and - we need to add brackets so that
			// we support precedence rules.  
			if ([topOfStack isEqualToString:@"+"] || [topOfStack isEqualToString:@"-"]) {				
				// Strip any existing brackets, before re-adding
				description = [NSString stringWithFormat:@"(%@ %@ %@)",
					[self deBracket:x], topOfStack, [self deBracket:y]];
			} else if ([topOfStack isEqualToString:@"/"]) {
				// We want to bracket the y operand before the new operation
				description = [NSString stringWithFormat:@"%@ %@ (%@)", 
									x, topOfStack,[self deBracket:y]];
			}
			// Otherwise, we are dealing with * so no need for brackets
			else {
			  description = [NSString stringWithFormat:@"%@ %@ %@",	x, topOfStack ,y];
			}
		}		
	}
	return description ;		
}

+ (NSString *)descriptionOfProgram:(id)program {	
	
	// Check program is valid and if not return message
	if (![self isValidProgram:program]) return @"Invalid program!";
	
	// If program is empty return 0
	if ([program count] == 0) return @"0";
	
	NSMutableArray *stack= [program mutableCopy];
	NSMutableArray *expressionArray = [NSMutableArray array];
		  

	
	// Call recursive method to describe the stack, removing superfluous brackets at the
	// start and end of the resulting expression. Add the result into an expression array
	// and continue if there are still more items in the stack. 
	// our description Array, and if the 
	while (stack.count > 0) {
		[expressionArray addObject:[self deBracket:[self descriptionOffTopOfStack:stack]]];
	}
	
	// Return a list of comma seperated programs
	return [expressionArray componentsJoinedByString:@","];		 
}

+ (id)popOperandOffProgramStack:(NSMutableArray *) stack {
	
	NSString * INSUFFICIENT_OPERANDS = @"Insufficient operands!";
	NSString * INVALID_OPERATION = @"Operation not implemented!";
	
	double result = 0;
	
	id topOfStack = [stack lastObject];
	if (topOfStack) [stack removeLastObject]; else return @"0";
	
	// If it's a number then just return it
	if ([topOfStack isKindOfClass:[NSNumber class]]) return topOfStack;		
	
	//Otherwise it's a string
	NSString *operation = topOfStack;
	
	// First check the no operand operations
	if ([operation isEqualToString:@"π"]) { 
		result = M_PI;
	} // Next the one operand operations
	else if ([self isOneOperandOperation:operation]) {
		id operand1 = [self popOperandOffProgramStack:stack];
		// If the operand is a number then ok, otherwise we have insufficient operands
		if ([operand1 isKindOfClass:[NSNumber class]]) {
			// Go ahead and do the operations
			if ([operation isEqualToString:@"sin"]) {
				result = sin ([operand1 doubleValue]); 
			} else if ([operation isEqualToString:@"cos"]) {
				result = cos ([operand1 doubleValue]);
			} else if ([operation isEqualToString:@"sqrt"]) {
				result = sqrt([operand1 doubleValue]);
			} else if ([operation isEqualToString:@"±"]) {
				result = [operand1 doubleValue] * -1;	
			} 
		} else return INSUFFICIENT_OPERANDS;			
	} // A two operand operation methinks...
	else if ([self isTwoOperandOperation:operation]) {
		id operand1 = [self popOperandOffProgramStack:stack];
		id operand2 = [self popOperandOffProgramStack:stack];	
		// Both operands need to be numbers, or we are out of operands
		if ([operand1 isKindOfClass:[NSNumber class]] &&
			 [operand2 isKindOfClass:[NSNumber class]]) {
			// Do the operations
			if ([operation isEqualToString:@"+"]) {
				result = [operand2 doubleValue] + [operand1 doubleValue]; 
			} else if ([@"*" isEqualToString:operation]) {
				result = [operand2 doubleValue] * [operand1 doubleValue];
			} else if ([operation isEqualToString:@"-"]) {
				result = [operand2 doubleValue] - [operand1 doubleValue];
			} else if ([operation isEqualToString:@"/"]) {
				result = [operand2 doubleValue] / [operand1 doubleValue];
			}
		} else return INSUFFICIENT_OPERANDS;
	} else return INVALID_OPERATION;
	
	return [NSNumber numberWithDouble:result];
}

+ (id)runProgram:(id)program {
	// Call the new runProgram method with a nil dictionary
	return [self runProgram:program usingVariableValues:nil];
}

+ (id)runProgram:(id)program 
usingVariableValues:(NSDictionary *)variableValues {
	
	// Ensure program is valid
	if (![self isValidProgram:program]) return 0;
	
	NSMutableArray *stack= [program mutableCopy];
	
	// For each item in the program
	for (int i=0; i < [stack count]; i++) {
		id obj = [stack objectAtIndex:i]; 
		
		// See whether we think the item is a variable
		if ([obj isKindOfClass:[NSString class]] && ![self isOperation:obj]) {	
			id value = [variableValues objectForKey:obj];			
			// If value is not an instance of NSNumber, set it to zero
			if (![value isKindOfClass:[NSNumber class]]) {
				value = [NSNumber numberWithInt:0];
			}			
			// Replace program variable with value.
			[stack replaceObjectAtIndex:i withObject:value];
		}		
	}	
	// Starting popping off the stack
	return [self popOperandOffProgramStack:stack];	
}


+ (NSSet *)variablesUsedInProgram:(id)program {	
	
	// Ensure program is valid
	if (![self isValidProgram:program]) return nil;
	
	NSMutableSet *variables = [NSMutableSet set];
	
	// For each item in the program
	for (id obj in program) {
		// If we think it's a variable add it to the variables set
		if ([obj isKindOfClass:[NSString class]] && ![self isOperation:obj]) {
			[variables addObject:obj]; 	
		}
	}	
	// Return nil if we don't have any variables
	if ([variables count] == 0) return nil; else return [variables copy];
}

@end
