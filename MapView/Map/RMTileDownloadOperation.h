//
//  RMTileDownloadOperation.h
//  MapView
//
//  Created by David Haynes on 31/03/2015.
//
//

#import <Foundation/Foundation.h>
#import "RMTile.h"
#import "RMTileSource.h"

@interface RMTileDownloadOperation : NSOperation

- (id)initWithTile:(RMTile)tile forTileSource:(id <RMTileSource>)source; // usingCache:(RMTileCache *)cache;

@property (nonatomic, strong) NSError *error;

@end
