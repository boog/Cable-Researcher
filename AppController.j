@import <Foundation/CPObject.j>
@import "Constants.j"
@import "TagTreeController.j"
@import "ServiceController.j"
@import "SplashController.j"
@import "MetaController.j"

@implementation AppController : CPObject
{
    CPWindow    theWindow; //this "outlet" is connected automatically by the Cib
    @outlet CPTableView tableView;
	@outlet CPOutlineView outlineView;
	@outlet CPTextField searchText;
	@outlet CPSearchField tagFilter;
	@outlet CPView rightPane;
	@outlet CPPopover splashPopover;
	@outlet CPButton searchButton;
	@outlet CPScrollView contentView;
	@outlet CPSegmentedControl tagMode;
	CPPopover metaPopover;
	CPTextField contentText;
	TagTreeController treeController; // Controls the tag browser
	CPArrayController arrayController; // Datasource for cable list
	ServiceController searchService;
	ServiceController detailService;
	BOOL interactiveUser;
	var itemTags;
	var searchParams;
	var timer; // Query-UI delay timer
}

////	Interface actions

- (@action)tagModeClick:(id)sender
{
	switch([tagMode selectedSegment]) {
		case 0: // Filter
		default:
			[treeController filter:""];
			break;
		case 1: // Active
			[treeController filter:"active tags"];
			break;
		case 2:
			[treeController setFilteredTags:itemTags];
			break;
	}
}

- (@action)metaClick:(id)sender
{
	if ([metaPopover shown]) {
		[metaPopover close];
	}
	else {
		[metaPopover showRelativeToRect:nil ofView:sender preferredEdge:CPMinYEdge];
	}
}

- (@action)helpClick:(id)sender {
	if ([splashPopover shown]) {
		[splashPopover close];
	}
	else {
		[splashPopover showRelativeToRect:nil ofView:sender preferredEdge:CPMinYEdge];
	}
}

- (void)dismissPopover
{
	[splashPopover close];
}

- (@action)resetTags:(id)sender
{
	[tagMode setSelectedSegment:0];
	[searchText setStringValue:""];
	[tagFilter setStringValue:""];
	[treeController reset];
	[self setHashBang];
}

- (@action)willFilter:(id)sender
{
	[tagMode setSelectedSegment:0]; // Switch to Filter mode
	[self tagModeClick:nil];
	[treeController filter:[tagFilter stringValue]];
}

- (@action)search:(id)interactive
{
	interactiveUser = NO;
	if (interactive) interactiveUser = YES;
	// Search button pressed
	searchParams.text = [searchText stringValue];
	searchParams.tags = [treeController getCheckedTags];
	searchParams.or = [treeController getOrTags];
	
	// Serialize the searchParms in to the hash bang fragment
	if (interactiveUser === YES) [self setHashBang];
	
	// Generate JSON request to populate search results dataSource
	[searchService post:queryPath withData:searchParams];
}

- (void)setHashBang
{
	var hashBang = "";
	if (searchParams) {
		var params = [];
		var text = escape(searchParams.text);
		var ref = escape(searchParams.refid);
		var tags = escape(searchParams.tags.join(','));
		var ors = escape(searchParams.or.join(','));

		if (text.length > 0) params.push("q=" + text);
		if (tags.length > 0) params.push("t=" + tags);
		if (ors.length > 0) params.push("o=" + ors);
		if (searchParams.refid && ref.length > 0) params.push("i=" + ref);
		hashBang = "#!/" + params.join('/');
	}

	window.location.hash = hashBang;
}

- (void)loadHashBang
{
	var hashBang = window.location.hash.split('/');
	if (hashBang.length > 0)
		// Load whatever search is passed in the url hash fragment
		var params = {};
		for (var i=0; i<hashBang.length; i++) {
			var kvp = hashBang[i].split('=');
			if (kvp.length === 2) {
				params[kvp[0]] = unescape(kvp[1]);
			}
		}
		if (params['q'] || params['t'] || params['o']) {
			searchParams = {
				text: params['q'] ? params['q'] : "",
				tags: params['t'] ? params['t'].split(',') : [],
				or: params['o'] ? params['o'].split(',') : [],
				refid: params['i'] ? params['i'] : "",
			}
			[treeController loadAllTags];
			[searchText setStringValue:searchParams.text];
			[treeController setCheckedTags:searchParams.tags];
			[treeController setOrTags:searchParams.or];
			[treeController filter:[tagFilter stringValue]];
			[tagMode setSelectedSegment:1];
			[self search:YES];
		}
	}
}

////	TagTree View methods

- (void)checkBoxTree:(id)tree didItemCheckChange:(CPObject)item toValue:(id)state
{
	// Checked tags changed, show live search - delay incase series of UI events
	if (timer) clearInterval(timer);
	timer = setInterval(function() { 
		clearInterval(timer);
		[self search:nil]; 
	}, 700);
}

////	Application delegate methods

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
	interactiveUser = NO;
	searchParams = {};

	[self loadHashBang];

	if (getCookie(c_name) != c_value) {
		// Show splash popover
		[splashPopover setContentViewController:[[SplashController alloc] initWithCibName:"Splash" bundle:nil]];
		var andOrColumn= [outlineView tableColumnWithIdentifier:"and"];
		[splashPopover showRelativeToRect:nil ofView:[outlineView headerView] preferredEdge:CPMaxXEdge];
		// Expand first category node of tags
		[outlineView expandItem:"Subject"];
	}
}

- (void)awakeFromCib
{
    // In this case, we want the window from Cib to become our full browser window
    [theWindow setFullPlatformWindow:YES];

	metaPopover = [[CPPopover alloc] init];
	// Show splash popover
	[metaPopover setContentViewController:[[MetaController alloc] initWithCibName:"Meta" bundle:nil]];
	[splashPopover setContentViewController:[[SplashController alloc] initWithCibName:"Splash" bundle:nil]];

	treeController = [[TagTreeController alloc] initWithOutlineView:outlineView];
	[treeController setDelegate:self];

	[rightPane setBackgroundColor:[CPColor colorWithHexString:"DDDDDD"]];
	
	detailService = [[ServiceController alloc] initWithEndPoint:serverUrl];
	[detailService setDelegate:self];
	searchService = [[ServiceController alloc] initWithEndPoint:serverUrl];
	[searchService setDelegate:self];
	
	contentText = [CPTextField labelWithTitle:""];
	[contentText setFrameOrigin:{x:10, y:10}]; // content margin
	[contentText setSelectable:YES];
	[contentView setDocumentView:contentText];
}

////	Table View methods
- (void)tableViewSelectionDidChange:(CPNotification)aNotification
{
	interactiveUser = YES;
	// Show selected cable in the content viewer
	if ([arrayController selectedObjects]) {
		var selectedItem = [arrayController selectedObjects][0];
		searchParams.refid = [selectedItem objectForKey:"refid"];
		[detailService post:itemPath withData:{refid: searchParams.refid}];
	}
}

- (void)setSearchResults:(CPArray)dataSource
{
	arrayController = [[CPArrayController alloc] init];
	if (dataSource && dataSource.length > 0) {
		// Show count in header name
		[[[tableView tableColumnWithIdentifier:"Subject"] headerView] setStringValue:"Subjects (" + dataSource.length + ")"];
		for (var i=0; i<dataSource.length; i++)
		{
			[arrayController addObject:[CPDictionary dictionaryWithJSObject:dataSource[i]]];
		}	
		
	}
	else {
		[[[tableView tableColumnWithIdentifier:"Subject"] headerView] setStringValue:"Subjects (0)"];
		if (interactiveUser == YES) {
			[[CPAlert alertWithError:"No search results found."] beginSheetModalForWindow:theWindow];
		}
	}
	
	// Update data binding, even if empty
	[tableView setDelegate:nil]; // Don't listen to any event during data binding (i.e. selected row change)
	[[tableView tableColumnWithIdentifier:"Refid"] bind:@"value" toObject:arrayController withKeyPath:@"arrangedObjects.refid" options:nil];
	[[tableView tableColumnWithIdentifier:"Subject"] bind:@"value" toObject:arrayController withKeyPath:@"arrangedObjects.subject.capitalizedString" options:nil]; 
	[[tableView tableColumnWithIdentifier:"Date"] bind:@"value" toObject:arrayController withKeyPath:@"arrangedObjects.date" options:nil]; 
	[[tableView tableColumnWithIdentifier:"Classification"] bind:@"value" toObject:arrayController withKeyPath:@"arrangedObjects.classification" options:nil]; 
	[tableView sizeLastColumnToFit];
	if (interactiveUser) [tableView setDelegate:self];
	// Select none, or parameterized index
	var selectedRow = -1;
	if (searchParams.refid) {
		for (var i=0; i<dataSource.length; i++) {
			if (dataSource[i].refid == searchParams.refid) {
				selectedRow = i;
				break;
			}
		}
	}
	[tableView selectRowIndexes:[CPIndexSet indexSetWithIndex:selectedRow] byExtendingSelection:NO];
	[tableView setDelegate:self];
}

- (void)setContent:(id)item
{
	// Show selected item content
	[contentText setStringValue:item.content + "\n\n"]
	[contentText sizeToFit];

	// Set selected item tags
	itemTags = item.tags;
	if (interactiveUser) {
		[tagMode setSelectedSegment:2]; // Set selected tag mode
		[self setHashBang];
	}
	[self tagModeClick:nil];
}

////	Service delegate methods

 - (void)serviceDelegate:(id)del gotJSONObject:(id)obj
{
	if (del === detailService) {
		[self setContent:obj]
	}
	else if (del === searchService) {
		[self setSearchResults:obj];
	}
	[searchButton setEnabled:YES];
	interactiveUser = NO;
}

- (void)serviceDelegate:(id)del failedWithError:(id)error
{
	// Handle errors from the web service
	[[CPAlert alertWithError:"There was an error communicating with the server."] beginSheetModalForWindow:theWindow];
	[searchButton setEnabled:YES];
}

- (void)serviceDelegateDidBeginConnection:(id)svc
{
	// Indicate UI that actively searching
	[searchButton setEnabled:NO];
}

@end
