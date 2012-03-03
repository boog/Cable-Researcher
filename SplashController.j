@import <Foundation/CPObject.j>
	
////	Help View
@implementation SplashController : CPViewController
{
	@outlet var mixedBox;
	@outlet var onboBox;
	id appDelegate;
}

- (void)awakeFromCib
{
	appDelegate = [[CPApplication sharedApplication] delegate];
	[mixedBox setState:CPMixedState];
	[mixedBox setEnabled:false];
	[onboBox setState:CPOnState];
	[onboBox setEnabled:false];
}

- (@action)understood:(id)sender
{
	[appDelegate dismissPopover];
	
	// Set cookie to never show popover again
	setCookie(c_name, c_value, 120);
}

@end