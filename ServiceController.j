@import <Foundation/CPObject.j>
	
////	This is a helper class for handling JSON web services
@implementation ServiceController : CPObject
{
	CPURLConnection connection;
	CPURLConnection queuedConnection;
	CPString endpoint;
	id delegate;
	CPString data;
}

+ (id)serviceWithURL:(CPString)path startPostWithObject:(id)obj delegate:(id)del
{
	var ret = [[ServiceController alloc] initWithEndPoint:""];
	[ret setDelegate:del];
	[ret post:path withData:obj];
	return ret;
}

- (id)initWithEndPoint:(CPString)e
{
	self = [super init];
	if (self) {
		data = "";
		endpoint = e;
	}
	return self;
}

- (void)connection:(CPURLConnection)c didFailWithError:(id)error 
{
	if ([delegate respondsToSelector:@selector(serviceDelegate:failedWithError:)]) {
		[delegate serviceDelegate:self failedWithError:error];
	}
}

//-(void)connection:(CPURLConnection)connection didReceiveResponse:(CPHTTPURLResponse)response; 

- (void)connection:(CPURLConnection)c didReceiveData:(CPString)d 
{
	data += d;
}

- (void)connectionDidFinishLoading:(CPURLConnection)c
{
	connection = undefined;
	if ([delegate respondsToSelector:@selector(serviceDelegate:gotJSONObject:)]) {
		var obj;
		try {
			obj = JSON.parse(data);
		}
		catch (e) {
		}
		if (obj) {
			[delegate serviceDelegate:self gotJSONObject:obj];
		}
		else {
			if ([delegate respondsToSelector:@selector(serviceDelegate:failedWithError:)]) {
				[delegate serviceDelegate:self failedWithError:"Unexpected response from server"];
			}
		}
	}
	data = "";
	if (queuedConnection) {
		connection = queuedConnection;
		[self start];
		queuedConnection = undefined;
	}
}

- (void)start
{
	if ([delegate respondsToSelector:@selector(serviceDelegateDidBeginConnection:)]) {
		[delegate serviceDelegateDidBeginConnection:self];
	}
	[connection start];
}

//-(void)get:(CPString)path;

-(void)post:(CPString)path withData:(id)obj
{
	var url = [CPURL URLWithString:endpoint + path];
	var request = [CPURLRequest requestWithURL:url];
	[request setHTTPBody:JSON.stringify(obj)];
	[request setHTTPMethod:"POST"];
	var conn = [CPURLConnection connectionWithRequest:request delegate:self];
	
	// If an active connection, then queueConnection for later
	if (!connection) {
		connection = conn;
		[self start];
	}
	else {
		[connection cancel];
		queuedConnection = conn;
	}
}


// - (void)serviceDelegate:(id)svc gotJSONObject:(id)obj
// - (void)serviceDelegate:(id)svc failedWithError:(id)error;
// - (void)serviceDelegateDidBeginConnection:(id)svc
-(void)setDelegate:(id)del
{
	delegate = del;
}

@end