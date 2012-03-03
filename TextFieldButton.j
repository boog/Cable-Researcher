@import <Foundation/CPObject.j>

////	This class allows text-fields to act as buttons by overriding the mouseDown event.
@implementation TextFieldButton : CPTextField
{
	id fn;
}

-(void)mouseDown:(NSEvent*) theEvent
{
	if (fn) fn();
}

- (void)setClickFn:(id)callback
{
	fn = callback;
}