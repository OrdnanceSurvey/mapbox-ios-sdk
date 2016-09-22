//
//  NSURLSession+RMUserAgent.h
//  MapView
//
//  Created by Natalia Paula Osiecka on 22/09/16.
//  Copyright (c) 2014 Ordnance Survey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSession (RMUserAgent)

/**
 Stops the thread to perform a synchronous request to the server.
 @warning Not intended to use on the main thread.

 @param request An NSURLRequest object that provides the URL, cache policy, request type, body data or body stream, and so on.
 @param error   An error object that indicates why the request failed, or nil if the request was successful.

 @return The data returned by the server.
 */
+ (nullable NSData *)rm_fetchDataSynchronouslyWithRequest:(NSURLRequest *)request error:(NSError **)error;


/**
 Stops the thread to perform a synchronous request to the server.
 @warning Not intended to use on the main thread.

 @param request  An NSURLRequest object that provides the URL, cache policy, request type, body data or body stream, and so on.
 @param error    An error object that indicates why the request failed, or nil if the request was successful.
 @param response An object that provides response metadata, such as HTTP headers and status code. If you are making an HTTP or HTTPS request, the returned object is actually an NSHTTPURLResponse object.

 @return The data returned by the server.
 */
+ (nullable NSData *)rm_fetchDataSynchronouslyWithRequest:(NSURLRequest *)request error:(NSError **)error response:(NSURLResponse *_Nullable *_Nullable)response;

@end

NS_ASSUME_NONNULL_END
