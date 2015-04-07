//
//  RMTileDownloadOperation.h
//  MapView
//
//  Created by David Haynes on 31/03/2015.
//
//

#import <Foundation/Foundation.h>
#import "RMTileSource.h"
#import "RMTile.h"
#import "RMMapTiledLayerView.h"

/**
 NSOperation subclass that downloads a tile into a tile cache.
 */
@interface RMTileDownloadOperation : NSOperation

/**
 *  Designated initialiser
 *
 *  @param tile                         The tile to download.
 *  @param source                       The tile source this tile belongs to.
 *  @param cache                        The cache we will be storing this tile in.
 *  @param boundsInScrollViewContent    The bounds of this tile in the map's scroll view content.
 *  @param retryCount                   How many times to retry if the request fails.
 *  @param timeout                      How long to wait until timing out the request.
 *
 *  @return The tile download operation. N.B. Interaction with UIKit (e.g. to request this tile be
 *  drawn in a layer) should be done on the main thread, either in a completion block, or using
 *  NSOperation dependencies.
 */
- (id)initWithTile:(RMTile)tile
     forTileSource:(id<RMTileSource>)source
        usingCache:(RMTileCache *)cache
boundsInScrollView:(CGRect)bounds
        retryCount:(NSUInteger)retryCount
           timeout:(NSTimeInterval)timeout;

/**
 *  If there is an error in the request, this property will contain it.
 */
@property (nonatomic, strong) NSError *error;

/**
 *  The HTTP response from the tile request.
 */
@property (nonatomic, strong) NSHTTPURLResponse *response;

/**
 *  The bounds of this tile in its map scroll view's content.
 */
@property (nonatomic, assign) CGRect boundsInScrollViewContent;

@end
