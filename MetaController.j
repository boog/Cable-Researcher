@import <Foundation/CPObject.j>
	
////	About View
@implementation MetaController : CPViewController
{
}

- (@action)flattrClicked:(id)sender
{
	window.location = 'http://flattr.com/thing/532393/Cable-Researcher';
}