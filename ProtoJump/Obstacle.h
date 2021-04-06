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

#define OBSTACLE_POS_X         900
#define OBSTACLE_MAX_POS_Y     400
#define OBSTACLE_MIN_POS_Y     200
#define OBSTACLE_MAX_WIDTH     100.0f
#define OBSTACLE_MIN_WIDTH     50.0f
#define OBSTACLE_MAX_HEIGHT    350.0f
#define OBSTACLE_MIN_HEIGHT    100.0f
//#define OBSTACLE_DISTANCE      900


@interface Obstacle : NSObject {}

@property (nonatomic, readwrite) float R, G, B;
@property (nonatomic, readwrite) int posY;
@property (nonatomic, readwrite) float width, height;

-(void)randomize;
-(void)dealloc;

@end
#endif /* Obstacle_h */
