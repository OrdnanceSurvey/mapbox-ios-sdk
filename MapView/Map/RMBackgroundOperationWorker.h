//
//  RMBackgroundOperationWorker.h
//  MapView
//
//  Created by Natalia Paula Osiecka on 22/09/16.
//  Copyright (c) 2014 Ordnance Survey. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^RMBackgroundWorkerExpirationHandler)(void);
typedef void(^RMBackgroundWorkerForegroundEnterHandler)(void);

@interface RMBackgroundOperationWorker : NSObject

/**
 The name to display in the debugger when viewing the background task. If you specify nil for this parameter, this method generates a name based on the name of the calling function or method.
 */
@property(nonatomic, readonly) NSString *backgroundTaskName;

/**
 Attaches the observers for background enter/leave system notifications. In case the app will enter the background, there will be a new task started with given task name. When the worker is dealloc'ed, all of the observers are removed.

 @param backgroundTaskName              The name to display in the debugger when viewing the background task. If you specify nil for this parameter, this method generates a name based on the name of the calling function or method.
 @param backgroundTaskExpirationHandler A handler to be called shortly before the app’s remaining background time reaches 0. You should use this handler to pause the background task.
 @param appEnteredForegroundHandler     A handler to be called shortly before an app leaves the background state on its way to becoming the active app. You should use this handler to resume all of the work which was paused during backgroundTaskExpirationHandler.

 @return The newly created background worker.
 */
- (instancetype)initWithBackgroundTaskName:(NSString *)backgroundTaskName
                     taskExpirationHandler:(nullable RMBackgroundWorkerExpirationHandler)backgroundTaskExpirationHandler
               appEnteredForegroundHandler:(nullable RMBackgroundWorkerForegroundEnterHandler)appEnteredForegroundHandler;

@end

@interface RMBackgroundOperationWorker (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
