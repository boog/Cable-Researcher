
@interface AppController : NSObject
{
    IBOutlet NSTableView* tableView;
    IBOutlet NSOutlineView* outlineView;
    IBOutlet NSTextField* searchText;
    IBOutlet NSSearchField* tagFilter;
    IBOutlet NSView* rightPane;
    IBOutlet NSPopover* splashPopover;
    IBOutlet NSButton* searchButton;
    IBOutlet NSScrollView* contentView;
    IBOutlet NSSegmentedControl* tagMode;
}
- (IBAction)tagModeClick:(id)aSender;
- (IBAction)metaClick:(id)aSender;
- (IBAction)helpClick:(id)aSender;
- (IBAction)resetTags:(id)aSender;
- (IBAction)willFilter:(id)aSender;
- (IBAction)search:(id)aSender;
@end