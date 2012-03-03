@import <Foundation/CPObject.j>
@import "TextFieldButton.j"
@import "Constants.j"

////	This class uses a CPOutlineView to display a grouped list of checkbox items.
@implementation TagTreeController : CPObject
{
	CPObject tags;
	CPObject checkedTags;
	CPObject orTags;
	CPObject filteredIndices;
	CPOutlineView outlineView;
	BOOL filterMode;
	id delegate;
}

- (id)initWithOutlineView:(CPOutlineView)o
{
	self = [super init];
	
	if (self) {
		outlineView = o;
		// Nothing checked by default
		checkedTags = {}; // Keyed with "TagCode": true
		orTags = {};
		// Available categories
		tags = {
			"Country": [],
			"Organization": [],
			"Program": [],
			"Subject": [],
			"Uncategorized": []
		};

		[outlineView setDataSource:self];
		[outlineView setDelegate:self];
		// Change label prototype to our custom clickable labels
		[[outlineView tableColumnWithIdentifier:"name"] setDataView:[[TextFieldButton alloc] init]];
	}
	
	return self;
}

// Returns the child item at an index of a given item. if item is nil you should return the appropriate root item.
- (id)outlineView:(CPOutlineView)o child:(CPInteger)index ofItem:(id)item
{
	// If filterMode map index to filter index
	if (filterMode && typeof(item) === "string") {
		index = filteredIndices[item][index];
	}
	
	// If root items, return string category
	if (item == nil) {
		var i = 0;
		for (var tag in tags) {
			if (i === index) return tag;
			i++;
		}
	}
	// If not root, then return object for the row
	else if (typeof(item) === "string" && tags[item].length >= index) {
		return [CPDictionary dictionaryWithJSObject:tags[item][index]];
	}
	return "foobar"; // Dont want to be here.
}

// Returns YES if the item is expandable, otherwise NO.
- (BOOL)outlineView:(CPOutlineView)o isItemExpandable:(id)item
{
	if (typeof(item) === "string") return YES; // Root nodes are expandable
	return NO; // Others are not.
}

// Returns the number of child items of a given item. If item is nil you should return the number of top level (root) items.
- (int)outlineView:(CPOutlineView)o numberOfChildrenOfItem:(id)item
{
	// If filterMode, only showing subset
	if (filterMode && typeof(item) === "string") {
		return filteredIndices[item].length;
	}
	
	var ret = 0; // No child nodes unless...
	if (item === nil)	{ // Root node
		// Count the number of tag categories
		for (var tag in tags) {
			ret++;
		}
	}
	else if (typeof(item) === "string") {
		// Return the length of given tag category
		if (!tags[item] || tags[item].length < 1) {
			[self retrieveTagsForCategory:item];
		}
		ret = tags[item].length;
	}
	
	return ret;
}

// Returns the object value of the item in a given column.
- (id)outlineView:(CPOutlineView)o objectValueForTableColumn:(CPTableColumn)tableColumn byItem:(id)item
{	
	// Set the row label
	if ([item isKindOfClass:[CPDictionary class]]) {
		// Set tag label
		return [[item valueForKey:'description'] capitalizedString] + " (" + [item valueForKey:'quantity'] + ")";
	}
	else
	{
		// Set category label
		return item;
	}
}

- (void)outlineView:(CPOutlineView)o setObjectValue:(id)object forTableColumn:(CPTableColumn)col byItem:(id)item
{
	// Toggle checked status
	var tag = [item valueForKey:'tag'];
	switch (checkedTags[tag]) {
		case CPOnState:
			checkedTags[tag] = CPMixedState;
			break;

		case CPMixedState:
			checkedTags[tag] = CPOffState;
			break;				
		default:
		case CPOffState:
			checkedTags[tag] = CPOnState;
			break;
	}
	if ([delegate respondsToSelector:@selector(checkBoxTree:didItemCheckChange:toValue:)]) {
		[delegate checkBoxTree:self didItemCheckChange:item toValue:checkedTags[tag]];
	}
}

- (void)outlineView:(CPOutlineView)o willDisplayView:(id)checkBox forTableColumn:(CPTableColumn)col item:(id)item
{
	// Set the checkbox view status
	if ([checkBox isKindOfClass:[CPCheckBox class]]) {
		if ([item isKindOfClass:[CPDictionary class]]) {
			[checkBox setHidden:NO];
			var tag = [item valueForKey:'tag'];
			// Set correct checked status
			if (checkedTags[tag]) [checkBox setState:checkedTags[tag]];
			else [checkBox setState:CPOffState];
			
		}
		else {
			// Categories can never be checked
			[checkBox setHidden:YES];
		}
	}
	else if ([checkBox isKindOfClass:[CPTextField class]]) {
		// Allow labels to be clicked to change check status
		var onclick;
		if (typeof(item) === 'string') {
			onclick = function() {
				if ([outlineView isItemExpanded:item]) [outlineView collapseItem:item];
				else [outlineView expandItem:item]; 
			};
		}
		else {
			onclick = function() {[self outlineView:o setObjectValue:o forTableColumn:col byItem:item]; [outlineView reloadData];};
		}
		[checkBox setClickFn:onclick];
	}
}

// Disallow row selection
- (BOOL)outlineView:(CPOutlineView)o shouldSelectItem:(id)item
{
	return NO;
}

// Stylize header nodes differently
- (BOOL)outlineView:(CPOutlineView)o isGroupItem:(id)item
{
	// Causes the root nodes to be styled differently
 	return typeof(item) === "string";
}

- (CPArray)getCheckedTags
{
	// Convert checkedTags object to array of tag names
	var ret = [];
	for (var tag in checkedTags) {
		if (checkedTags[tag] === CPOnState) ret.push(tag);
	}
	return ret;
}

- (void)setCheckedTags:(CPArray)namedTags
{
	if (!checkedTags) checkedTags = {};
	for (var i=0; i<namedTags.length; i++) {
		checkedTags[namedTags[i]] = CPOnState;
	}
}

- (CPArray)getOrTags
{
	// Convert checkedTags object to array of tag names
	var ret = [];
	for (var tag in checkedTags) {
		if (checkedTags[tag] === CPMixedState) ret.push(tag);
	}
	return ret;
}

- (void)setOrTags:(CPArray)namedTags
{
	if (!checkedTags) checkedTags = {};
	for (var i=0; i<namedTags.length; i++) {
		checkedTags[namedTags[i]] = CPMixedState;
	}
}

// Reset checked and filtered state
- (void)reset
{
	checkedTags = {};
	[self filter:""];
	[outlineView reloadData];
}

// - (void)checkBoxTree:(CheckBoxTree)tree didItemCheckChange:(CPObject)item toValue:(CPButtonState)state
- (void)setDelegate:(id)d
{
	delegate = d;
}

// Retrieves and caches tags for all categories
- (void)loadAllTags
{
	if (!tags) tags = {};
	for (var item in tags) {
		[self retrieveTagsForCategory:item];
	}
}

- (void)setFilteredTags:(CPArray)filterTags
{
	// Expand all items to show filter results
	if (filterTags && filterTags.length > 0) {
		for (var category in tags) {
			[outlineView expandItem:category];
		}
		
		var set = {};
		for (var i=0; i<filterTags.length; i++) set[filterTags[i].tag] = true;
		// Find all indices of tags which should be filtered
		filterMode = YES;
		filteredIndices = {};
		for (var category in tags) {
			var items = tags[category];
			filteredIndices[category] = []; // Hold array of indices
			for (var index = 0; index < items.length; index++) {
				// If matches filter substring or already checked
				if (set[items[index].tag] || 
						checkedTags[items[index].tag] && checkedTags[items[index]] !== CPOffState) {
					filteredIndices[category].push(index);
				}
			}
		}
		// Recheck dataSource to refresh display
		[outlineView reloadData];
	}
}

- (void)filter:(CPString)str
{
	// Expand all items to show filter results
	if (str.length > 0) {
		for (var category in tags) {
			[outlineView expandItem:category];
		}
		
		// Find all indices of tags which should be filtered
		filterMode = YES;
		filteredIndices = {};
		var filter = new RegExp(".*" + str + ".*", "gi");
		for (var category in tags) {
			var items = tags[category];
			filteredIndices[category] = []; // Hold array of indices
			for (var index = 0; index < items.length; index++) {
				// If matches filter substring or already checked
				if (filter.exec(items[index].description + " " + items[index].tag) != null || 
						checkedTags[items[index].tag] && checkedTags[items[index]] !== CPOffState) {
					filteredIndices[category].push(index);
				}
			}
		}
	}
	else {
		// Turn filter mode off and reload all data
		filterMode = NO;
		// Collapse all categories
		for (var category in tags) {
			[outlineView collapseItem:category];
		}
	}
	
	// Recheck dataSource to refresh display
	[outlineView reloadData];
}

// Retrieve tags for a category and cache in tags object
- (void)retrieveTagsForCategory:(CPString)category
{
	// Make JSON request to populate datasource
	var endPoint = [CPURL URLWithString:serverUrl + tagsPath];
	var request = [CPURLRequest requestWithURL:endPoint];
	[request setHTTPBody:JSON.stringify({"category":category})];
	[request setHTTPMethod:"POST"];
	var dataSource = [CPURLConnection sendSynchronousRequest:request returningResponse:nil];
	if (dataSource) dataSource = [dataSource JSONObject];
	else dataSource = [];
	
	if (dataSource && dataSource.length > 0) {
		tags[category] = dataSource;
	}
}

@end