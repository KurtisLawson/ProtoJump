//
//  Obstacle.h
//  ProtoJump
//
//  Created by Houman on 2021-03-02.
//

#ifndef Obstacle_h
#define Obstacle_h
#import <Foundation/Foundation.h>
#include <time.h>
#include <stdlib.h>

// Obstcale Constraints
#define OBSTACLE_MAX_POS_Y     0.72f
#define OBSTACLE_MIN_POS_Y     0.28f
#define OBSTACLE_POS_X         1.0f
#define OBSTACLE_MAX_WIDTH     0.12f
#define OBSTACLE_MIN_WIDTH     0.06f
#define OBSTACLE_MAX_HEIGHT    0.5f
#define OBSTACLE_MIN_HEIGHT    0.25f

@interface Obstacle : NSObject {}

@property (nonatomic, readwrite) float width, height;
@property (nonatomic, readwrite) float posX, posY;

-(void)randomize;
-(void)dealloc;

@end
#endif /* Obstacle_h */
