#import "callme.h"

@implementation callme

// This example action works with phone numbers.
- (NSString *)actionProperty
{
    return kABPhoneProperty;
}

// Our menu title will look like Speak 555-1212
- (NSString *)titleForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
    ABMultiValue *values = [person valueForProperty:[self actionProperty]];
    NSString *value = [values valueForIdentifier:identifier];

    return [NSString stringWithFormat:@"Deskphone %@", value];
}

// This method is called when the user selects your action. As above, this method
// is passed information about the data item rolled over.
- (void)performActionForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
    ABMultiValue *values = [person valueForProperty:[self actionProperty]];
    NSString *value = [values valueForIdentifier:identifier];

    // Unfortunately, this causes us to use com.apple.AddressBook as the preference domain.
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* managerHost = [userDefaults stringForKey:@"AsteriskManagerHost"];
    NSInteger managerPort = [userDefaults integerForKey:@"AsteriskManagerPort"];
    NSString* managerUsername = [userDefaults stringForKey:@"AsteriskManagerUsername"];
    NSString* managerPassword = [userDefaults stringForKey:@"AsteriskManagerPassword"];
    NSString* channel = [userDefaults stringForKey:@"AsteriskOriginateChannel"];
    NSString* context = [userDefaults stringForKey:@"AsteriskOriginateContext"];

    GCDAsyncSocket* socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    NSError *err = nil;
    if (![socket connectToHost:managerHost onPort:managerPort error:&err]) {
        NSLog(@"Connect failed: %@", err);
        return;
    }

    NSString* template = @"Action: Login\n"
        "Username: %@\n"
        "Secret: %@\n"
        "\n"
        "Action: Originate\n"
        "Channel: %@\n"
        "MaxRetries: 1\n"
        "RetryTime: 60\n"
        "WaitTime: 0\n"
        "Context: %@\n"
        "Exten: %@\n"
        "Priority: 1\n"
        "\n"
        ;

    NSString* destination = value;
    destination = [destination stringByReplacingOccurrencesOfString:@"(" withString:@""];
    destination = [destination stringByReplacingOccurrencesOfString:@")" withString:@""];
    destination = [destination stringByReplacingOccurrencesOfString:@"-" withString:@""];
    destination = [destination stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSString* message = [NSString stringWithFormat:template, managerUsername, managerPassword, channel, context, destination];

    [socket writeData:[message dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:1];
}

// Optional. Your action will always be enabled in the absence of this method. As
// above, this method is passed information about the data item rolled over.
- (BOOL)shouldEnableActionForPerson:(ABPerson *)person identifier:(NSString *)identifier
{
    ABMultiValue *values = [person valueForProperty:[self actionProperty]];
    NSString *value = [values valueForIdentifier:identifier];
    if (value == nil) {
        return NO;
    }

    return YES;
}

- (void)socket:(GCDAsyncSocket *)sender didConnectToHost:(NSString *)host port:(UInt16)port
{
    //NSLog(@"Cool, I'm connected! That was easy.");
}

@end
