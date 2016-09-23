//
//  RMBackgroundOperationWorker.m
//  MapView
//
//  Created by Natalia Paula Osiecka on 22/09/16.
//  Copyright (c) 2014 Ordnance Survey. All rights reserved.
//

#import "RMBackgroundOperationWorker.h"

@interface RMBackgroundOperationWorker()

@property(nonatomic, readonly) NSArray<id> *observerIds;
@property(nonatomic) UIBackgroundTaskIdentifier backgroundTaskIdentifier;

@end

@implementation RMBackgroundOperationWorker

#pragma mark - Memory Management

- (instancetype)initWithBackgroundTaskName:(NSString *)backgroundTaskName
                     taskExpirationHandler:(nullable RMBackgroundWorkerExpirationHandler)backgroundTaskExpirationHandler
               appEnteredForegroundHandler:(nullable RMBackgroundWorkerForegroundEnterHandler)appEnteredForegroundHandler
{
    if (self = [super init])
    {
        _backgroundTaskName = [backgroundTaskName copy];

        [self setUpBackgroundExecutionWithBackgroundTaskExpirationHandler:backgroundTaskExpirationHandler appEnteredForegroundHandler:appEnteredForegroundHandler];
    }

    return self;
}

- (void)dealloc
{
    for (id observerId in self.observerIds)
    {
        [NSNotificationCenter.defaultCenter removeObserver:observerId];
    }
}

#pragma mark - Background Worker Setup

- (void)setUpBackgroundExecutionWithBackgroundTaskExpirationHandler:(nullable RMBackgroundWorkerExpirationHandler)backgroundTaskExpirationHandler
                                        appEnteredForegroundHandler:(nullable RMBackgroundWorkerForegroundEnterHandler)appEnteredForegroundHandler
{

    __weak typeof(self) weakSelf = self;
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    id backgroundEntryObserver = [notificationCenter addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification *_Nonnull notification)
    {
        typeof(weakSelf) strongSelf = weakSelf;

        if ([notification.object isKindOfClass:[UIApplication class]]) {
            UIApplication *application = notification.object;
            strongSelf.backgroundTaskIdentifier = [application beginBackgroundTaskWithName:strongSelf.backgroundTaskName expirationHandler:backgroundTaskExpirationHandler];
        }
        else
        {
            NSAssert(NO, @"The documentation states the object in the note should always be an instance of the UIApplication class");
        }
    }];

    id foregroundEntryObserver = [notificationCenter addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification *_Nonnull notification)
    {
        if (appEnteredForegroundHandler)
        {
            appEnteredForegroundHandler();
        }
    }];

    _observerIds = @[backgroundEntryObserver, foregroundEntryObserver];
}

@end
