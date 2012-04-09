@import <Foundation/CPObject.j>

////	This class allows text-fields to act as buttons by overriding the mouseDown event.
@implementation TextFieldButton : CPTextField
{
	id fn;
}

-(void)mouseDown:(CPEvent)theEvent
{
	if (fn) fn();
}

-(void)mouseDragged:(CPEvent)event
{
	//CPBackgroundColorAttributeName
}

- (void)setClickFn:(id)callback
{
	fn = callback;
}