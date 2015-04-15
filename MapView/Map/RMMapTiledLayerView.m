//
//  RMMapTiledLayerView.m
//  MapView
//
// Copyright (c) 2008-2013, Route-Me Contributors
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// * Redistributions of source code must retain the above copyright notice, this
//   list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above copyright notice,
//   this list of conditions and the following disclaimer in the documentation
//   and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

#import "RMMapTiledLayerView.h"

#import "RMMapView.h"
#import "RMTileSource.h"
#import "RMTileImage.h"
#import "RMTileCache.h"
#import "RMMBTilesSource.h"
#import "RMDBMapSource.h"
#import "RMAbstractWebMapSource.h"
#import "RMDatabaseCache.h"
#import "RMTileDownloadOperation.h"

#define IS_VALID_TILE_IMAGE(image) (image != nil && [image isKindOfClass:[UIImage class]])

@interface RMMapTiledLayerView ()

/**
 *  The NSOperation LIFO queue (i.e. stack) used to download tile image data.
 */
@property (nonatomic, strong) NSOperationQueue *tileDownloadQueue;

@end

@implementation RMMapTiledLayerView
{
    __weak RMMapView *_mapView;
    id<RMTileSource> _tileSource;
}

@synthesize useSnapshotRenderer = _useSnapshotRenderer;
@synthesize tileSource = _tileSource;

+ (Class)layerClass
{
    return [CATiledLayer class];
}

- (CATiledLayer *)tiledLayer
{
    return (CATiledLayer *)self.layer;
}

- (id)initWithFrame:(CGRect)frame mapView:(RMMapView *)aMapView forTileSource:(id<RMTileSource>)aTileSource
{
    if (!(self = [super initWithFrame:frame]))
    {
        return nil;
    }

    self.opaque = NO;

    _mapView = aMapView;
    _tileSource = aTileSource;
    _tileDownloadQueue = [[NSOperationQueue alloc] init];
    _tileDownloadQueue.maxConcurrentOperationCount = 16;

    self.useSnapshotRenderer = NO;

    CATiledLayer *tiledLayer = [self tiledLayer];
    size_t levelsOf2xMagnification = _mapView.tileSourcesMaxZoom;
    if (_mapView.adjustTilesForRetinaDisplay && _mapView.screenScale > 1.0)
    {
        levelsOf2xMagnification += 1;
    }
    tiledLayer.levelsOfDetail = levelsOf2xMagnification;
    tiledLayer.levelsOfDetailBias = levelsOf2xMagnification;

    return self;
}

- (void)dealloc
{
    [_tileSource cancelAllDownloads];
    self.layer.contents = nil;
    _mapView = nil;
}

- (void)didMoveToWindow
{
    self.contentScaleFactor = 1.0f;
}

- (void)cancelOffscreenTileDownloadsForBounds:(CGRect)bounds
{
    for (RMTileDownloadOperation *operation in self.tileDownloadQueue.operations)
    {
        if (!CGRectIntersectsRect(operation.boundsInScrollViewContent, bounds))
        {
            [operation cancel];
        }
    }
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)context
{
    CGRect rect = CGContextGetClipBoundingBox(context);
    CGRect bounds = self.bounds;
    short zoom = log2(bounds.size.width / rect.size.width);

    if (self.useSnapshotRenderer)
    {
        zoom = (short)ceilf(_mapView.adjustedZoomForRetinaDisplay);
        CGFloat rectSize = bounds.size.width / powf(2.0, (float)zoom);

        int x1 = floor(rect.origin.x / rectSize),
            x2 = floor((rect.origin.x + rect.size.width) / rectSize),
            y1 = floor(fabs(rect.origin.y / rectSize)),
            y2 = floor(fabs((rect.origin.y + rect.size.height) / rectSize));

        if (zoom >= _tileSource.minZoom && zoom <= _tileSource.maxZoom)
        {
            UIGraphicsPushContext(context);

            for (int x = x1; x <= x2; ++x)
            {
                for (int y = y1; y <= y2; ++y)
                {
                    RMTile tile = RMTileMake(x, y, zoom);

                    UIImage *tileImage;

                    if ([_tileSource isKindOfClass:[RMAbstractWebMapSource class]])
                    {
                        tileImage = [_tileSource cachedImageForTile:tile inCache:[_mapView tileCache]];
                    } else {
                        tileImage = [_tileSource imageForTile:tile inCache:[_mapView tileCache]];
                    }

                    // If this tile's image is not present, try to obtain lower resolution tiles from higher zoom levels instead.
                    if (!tileImage)
                    {
                        if (_mapView.missingTilesDepth == 0)
                        {
                            tileImage = [RMTileImage errorTile];
                        } else {
                            NSUInteger currentTileDepth = 1, currentZoom = zoom - currentTileDepth;

                            while (!tileImage && currentZoom >= _tileSource.minZoom && currentTileDepth <= _mapView.missingTilesDepth)
                            {
                                float nextX = x / powf(2.0, (float)currentTileDepth),
                                      nextY = y / powf(2.0, (float)currentTileDepth);
                                float nextTileX = floor(nextX),
                                      nextTileY = floor(nextY);

                                if ([_tileSource isKindOfClass:[RMAbstractWebMapSource class]])
                                {
                                    tileImage = [_tileSource cachedImageForTile:RMTileMake((int)nextTileX, (int)nextTileY, currentZoom)
                                                                        inCache:[_mapView tileCache]];
                                } else {
                                    tileImage = [_tileSource imageForTile:RMTileMake((int)nextTileX, (int)nextTileY, currentZoom) inCache:[_mapView tileCache]];
                                }

                                if (IS_VALID_TILE_IMAGE(tileImage))
                                {
                                    // crop
                                    float cropSize = 1.0 / powf(2.0, (float)currentTileDepth);

                                    CGRect cropBounds = CGRectMake(tileImage.size.width * (nextX - nextTileX),
                                                                   tileImage.size.height * (nextY - nextTileY),
                                                                   tileImage.size.width * cropSize,
                                                                   tileImage.size.height * cropSize);

                                    CGImageRef imageRef = CGImageCreateWithImageInRect([tileImage CGImage], cropBounds);
                                    tileImage = [UIImage imageWithCGImage:imageRef];
                                    CGImageRelease(imageRef);
                                    break;
                                }
                                else
                                {
                                    tileImage = nil;
                                }
                                currentTileDepth++;
                                currentZoom = zoom - currentTileDepth;
                            }
                        }
                    }

                    if (IS_VALID_TILE_IMAGE(tileImage))
                    {
                        [tileImage drawInRect:CGRectMake(x * rectSize, y * rectSize, rectSize, rectSize)];
                    }
                }
            }
            UIGraphicsPopContext();
        }
    }
    else  // Not using snapshot renderer
    {
        int x = floor(rect.origin.x / rect.size.width),
            y = floor(fabs(rect.origin.y / rect.size.height));

        if (_mapView.adjustTilesForRetinaDisplay && _mapView.screenScale > 1.0)
        {
            zoom--;
            x >>= 1;
            y >>= 1;
        }
        
        // Ugly method to get the map content offset bounds, so we can cancel tile
        // downloads outside of it.
        id mapScrollView = self.superview.superview;
        CGRect mapScrollViewBounds = ((UIScrollView *)mapScrollView).bounds;
        [self cancelOffscreenTileDownloadsForBounds:mapScrollViewBounds];
        
        UIGraphicsPushContext(context);
        UIImage *tileImage = nil;

        if (zoom >= _tileSource.minZoom && zoom <= _tileSource.maxZoom)
        {
            RMDatabaseCache *databaseCache = nil;

            for (RMTileCache *componentCache in _mapView.tileCache.tileCaches)
            {
                if ([componentCache isKindOfClass:[RMDatabaseCache class]])
                {
                    databaseCache = (RMDatabaseCache *)componentCache;
                }
            }

            if (![_tileSource isKindOfClass:[RMAbstractWebMapSource class]] || !databaseCache || !databaseCache.capacity)
            {
                // for non-web tiles, query the source directly since trivial blocking
                tileImage = [_tileSource imageForTile:RMTileMake(x, y, zoom) inCache:[_mapView tileCache]];
            }
            else
            {
                // for non-local tiles, consult cache directly first (if possible)
                if (_tileSource.isCacheable)
                {
                    tileImage = [[_mapView tileCache] cachedImage:RMTileMake(x, y, zoom) withCacheKey:[_tileSource uniqueTilecacheKey]];
                }

                if (!tileImage)   // image was not in cache - fire off an asynchronous retrieval
                {
                    // Determine the bounds of the tile being rendered, in the coordinate
                    // system of the map scroll view content. The will be used later to
                    // determine if this tile download request can be cancelled.
                    CGRect tileBoundsInScrollView = [mapScrollView convertRect:rect fromView:self];

                    RMTileDownloadOperation *downloadOperation = [[RMTileDownloadOperation alloc] initWithTile:RMTileMake(x, y, zoom)
                                                                                                 forTileSource:_tileSource
                                                                                                    usingCache:_mapView.tileCache
                                                                                            boundsInScrollView:tileBoundsInScrollView
                                                                                                    retryCount:((RMAbstractWebMapSource *)_tileSource).retryCount
                                                                                                       timeout:((RMAbstractWebMapSource *)_tileSource).requestTimeoutSeconds];
                    
                    if (![self.tileDownloadQueue.operations containsObject:downloadOperation])
                    {
                        __weak RMTileDownloadOperation *weakDownloadOperation = downloadOperation;
                        downloadOperation.completionBlock = ^{
                            __strong RMTileDownloadOperation *strongDownloadOperation = weakDownloadOperation;
                            dispatch_async(dispatch_get_main_queue(), ^(void) {
                                if (!strongDownloadOperation.cancelled)
                                {
                                    // Tell the layer to draw itself again for this rect, which will now use the newly downloaded tile from the cache.
                                    [self.layer setNeedsDisplayInRect:rect];
                                }
                            });
                        };

                        [self.tileDownloadQueue addOperations:@[downloadOperation] waitUntilFinished:YES];
                    }
                }
            }
        }

        if (!tileImage)
        {
            if (_mapView.missingTilesDepth == 0)
            {
                tileImage = [RMTileImage errorTile];
            }
            else
            {
                NSUInteger currentTileDepth = 1, currentZoom = zoom - currentTileDepth;

                // tries to return lower zoom level tiles if a tile cannot be found
                while (!tileImage && currentZoom >= _tileSource.minZoom && currentTileDepth <= _mapView.missingTilesDepth) {
                    float nextX = x / powf(2.0, (float)currentTileDepth),
                          nextY = y / powf(2.0, (float)currentTileDepth);
                    float nextTileX = floor(nextX),
                          nextTileY = floor(nextY);

                    RMTile lowerResolutionTile = RMTileMake((int)nextTileX, (int)nextTileY, currentZoom);
                    tileImage = [_tileSource imageForTile:lowerResolutionTile inCache:[_mapView tileCache]];

                    if (IS_VALID_TILE_IMAGE(tileImage))
                    {
                        // crop
                        float cropSize = 1.0 / powf(2.0, (float)currentTileDepth);

                        CGRect cropBounds = CGRectMake(tileImage.size.width * (nextX - nextTileX),
                                                       tileImage.size.height * (nextY - nextTileY),
                                                       tileImage.size.width * cropSize,
                                                       tileImage.size.height * cropSize);

                        CGImageRef imageRef = CGImageCreateWithImageInRect([tileImage CGImage], cropBounds);
                        tileImage = [UIImage imageWithCGImage:imageRef];
                        CGImageRelease(imageRef);
                        break;
                    }
                    else
                    {
                        tileImage = nil;
                    }

                    currentTileDepth++;
                    currentZoom = zoom - currentTileDepth;
                }
            }
        }

        if (IS_VALID_TILE_IMAGE(tileImage))
        {
            if (_mapView.adjustTilesForRetinaDisplay && _mapView.screenScale > 1.0)
            {
                // Crop the image
                float xCrop = (floor(rect.origin.x / rect.size.width) / 2.0) - x;
                float yCrop = (floor(rect.origin.y / rect.size.height) / 2.0) - y;

                CGRect cropBounds = CGRectMake(tileImage.size.width * xCrop,
                                               tileImage.size.height * yCrop,
                                               tileImage.size.width * 0.5,
                                               tileImage.size.height * 0.5);

                CGImageRef imageRef = CGImageCreateWithImageInRect([tileImage CGImage], cropBounds);
                tileImage = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
            }

            if (_mapView.debugTiles)
            {
                UIGraphicsBeginImageContext(tileImage.size);
                CGContextRef debugContext = UIGraphicsGetCurrentContext();
                CGRect debugRect = CGRectMake(0, 0, tileImage.size.width, tileImage.size.height);
                [tileImage drawInRect:debugRect];
                UIFont *font = [UIFont systemFontOfSize:18.0];

                CGContextSetStrokeColorWithColor(debugContext, [UIColor whiteColor].CGColor);
                CGContextSetLineWidth(debugContext, 2.0);
                CGContextSetShadowWithColor(debugContext, CGSizeMake(0.0, 0.0), 5.0, [UIColor blackColor].CGColor);
                CGContextStrokeRect(debugContext, debugRect);
                CGContextSetFillColorWithColor(debugContext, [UIColor whiteColor].CGColor);

                NSString *debugString = [NSString stringWithFormat:@"Zoom %d", zoom];
                CGSize debugSize1 = [debugString sizeWithFont:font];
                [debugString drawInRect:CGRectMake(5.0, 5.0, debugSize1.width, debugSize1.height) withFont:font];
                debugString = [NSString stringWithFormat:@"(%d, %d)", x, y];
                CGSize debugSize2 = [debugString sizeWithFont:font];
                [debugString drawInRect:CGRectMake(5.0, 5.0 + debugSize1.height + 5.0, debugSize2.width, debugSize2.height) withFont:font];
                tileImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
            }
            [tileImage drawInRect:rect];
        }
        UIGraphicsPopContext();
    }
}

@end
