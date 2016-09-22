//
//  NSURLSession+RMUserAgent.h
//  MapView
//
//  Created by Natalia Paula Osiecka on 22/09/16.
//  Copyright (c) 2014 Ordnance Survey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSession (RMUserAgent)

+ (NSData *)fetchDataSynchronouslyWithRequest:(NSURLRequest *)request error:(NSError **)error;
+ (NSData *)fetchDataSynchronouslyWithRequest:(NSURLRequest *)request error:(NSError **)error response:(NSURLResponse **)response;

@end
