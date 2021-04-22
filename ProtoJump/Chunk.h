//
//  Chunk.h
//  ProtoJump
//
//  Created by socas on 2021-04-06.
//

#ifndef Chunk_h
#define Chunk_h

#import <Foundation/Foundation.h>
#include <stdlib.h>

#include "Obstacle.h"
#include "Hazard.h"

// Chunk parameters
#define TOTAL_HAZ_SLOTS 4
#define MAX_HAZ         3
#define HAZ_CHANCE      50
#define MIN_HAZ_RATIO   5.0
#define MAX_HAZ_RATIO   2.0

// Correspodning Hazard index for hazards array
typedef enum {
    haz_left = 0,
    haz_top,
    haz_right,
    haz_bottom
} Side;

@interface Chunk : NSObject {}

// Reference to obstacle in this chunk
@property Obstacle* obs;
// Array of hazards in this chunk
@property NSMutableArray* hazards;

// Randomize the chunk
-(void)randomize;
// Convert relative value to pixel value
-(float)toPixel:(float)dec :(float)pix;
// Convert pixel value to relative value
-(float)toDec:(float)curr :(float)pix;
-(void)dealloc;

@end
#endif /* Chunk_h */
