//
//  NSURLSession+RMUserAgent.m
//  MapView
//
//  Created by Natalia Paula Osiecka on 22/09/16.
//  Copyright (c) 2014 Ordnance Survey. All rights reserved.
//

#import "NSURLSession+RMUserAgent.h"

@implementation NSURLSession (RMUserAgent)

static int64_t semaphoreTimeout = (int64_t)(2 * 60 * NSEC_PER_SEC); // 2 minutes

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
    NSURLSessionTask *task = [NSURLSession.sharedSession dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *requestError)
                              {
                                  blockData = data;
                                  blockError = requestError;
                                  blockResponse = response;
                                  dispatch_semaphore_signal(semaphore);
                              }];
    [task resume];

    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, semaphoreTimeout));

    if (blockError && error)
    {
        *error = blockError;
    }
    if (blockResponse && response)
    {
        *response = blockResponse;
    }
    
    return blockData;
}

@end
