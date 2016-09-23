//
//  NSURLSession+RMUserAgent.m
//  MapView
//
//  Created by Natalia Paula Osiecka on 22/09/16.
//  Copyright (c) 2014 Ordnance Survey. All rights reserved.
//

#import "NSURLSession+RMUserAgent.h"
#import "RMConfiguration.h"

@implementation NSURLSession (RMUserAgent)

static int64_t semaphoreExtraTimeout = 10;

+ (NSData *)rm_fetchDataSynchronouslyWithRequest:(NSURLRequest *)request error:(NSError **)error
{
    return [self rm_fetchDataSynchronouslyWithRequest:request error:error response:nil];
}

+ (NSData *)rm_fetchDataSynchronouslyWithRequest:(NSURLRequest *)request error:(NSError **)error response:(NSURLResponse **)response
{
    __block NSData *blockData;
    __block NSError *blockError;
    __block NSURLResponse *blockResponse;

    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    NSURLSessionTask *task = [RMConfiguration.sharedInstance.mapBoxUrlSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *requestError)
                              {
                                  blockData = data;
                                  blockError = requestError;
                                  blockResponse = response;
                                  dispatch_semaphore_signal(semaphore);
                              }];
    [task resume];

    int64_t semaphoreTimeout = (int64_t)((request.timeoutInterval + semaphoreExtraTimeout) * NSEC_PER_SEC);
    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, semaphoreTimeout));

    // if it happens that the semaphore will quit before the task does stop the task.
    // such behaviour is unexpected and should not happen, so we can treat it as an error.
    if (task.state == NSURLSessionTaskStateRunning)
    {
        if (error)
        {
            NSDictionary *errorUserInfo = @{
                                            NSLocalizedDescriptionKey: NSLocalizedString(@"Could not download part of the map.", nil),
                                            NSLocalizedFailureReasonErrorKey: NSLocalizedString(@"The operation timed out.", nil),
                                            NSLocalizedRecoverySuggestionErrorKey: NSLocalizedString(@"Try to connect to a better network.", nil)
                                            };
            *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:errorUserInfo];
        }
        [task cancel];
    }

    if (error)
    {
        *error = blockError;
    }
    if (response)
    {
        *response = blockResponse;
    }
    
    return blockData;
}

@end
