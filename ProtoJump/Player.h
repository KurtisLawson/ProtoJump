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

typedef enum {
    grounded,
    leftCollision,
    rightCollision,
    bottomCollision,
    airborne
} PlayerState;

@interface Player : NSObject{
    @public PlayerState state;
}
@property (nonatomic, readwrite) float posX, posY, jumpTimer, jumpCount, maxJump;
@property (nonatomic, readwrite)bool dead, initialJump;

-(void)updatePos:(float)positionX:(float)positionY;
-(void) checkCollision:(float)positionX:(float)positionY:(float)width:(float)height;
-(void)dealloc;
@end
#endif /* Player_h */
