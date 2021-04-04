//
//  Player.h
//  ProtoJump
//
//  Created by Henry Zhang on 2021-04-03.
//

#ifndef Player_h
#define Player_h
#import <Foundation/Foundation.h>
#include <time.h>
#include <stdlib.h>

#define BALL_POS_X             400
#define BALL_POS_Y             50
#define BALL_RADIUS            50.0f
#define BALL_VELOCITY          100000.0f
#define BALL_SPHERE_SEGS       128

@interface Player : NSObject{}

@property (nonatomic, readwrite) float posX, posY;
@property (nonatomic, readwrite)bool dead;

-(void)updatePos:(float)positionX:(float)positionY;
-(void)dealloc;
@end
#endif /* Player_h */
