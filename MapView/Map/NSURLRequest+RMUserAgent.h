//
//  NSURLRequest+RMUserAgent.h
//  MapView
//
//  Created by Natalia Paula Osiecka on 22/09/16.
//  Copyright (c) 2014 Ordnance Survey. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (RMUserAgent)

+ (instancetype)rm_requestWithHeaderForURL:(NSURL *)url;
+ (instancetype)rm_requestWithHeaderForURL:(NSURL *)url cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval;

@end
