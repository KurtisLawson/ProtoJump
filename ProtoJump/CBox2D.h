//
//  Copyright © Borna Noureddin. All rights reserved.
//

#ifndef MyGLGame_CBox2D_h
#define MyGLGame_CBox2D_h

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>


// Set up brick and ball physics parameters here:
//   position, width+height (or radius), velocity,
//   and how long to wait before dropping brick
#define SCREEN_BOUNDS_X        800
#define SCREEN_BOUNDS_Y        600

// Physics & Game-Speed Parameters
#define JUMP_MAGNITUDE         400
#define GRAVITY                -350
#define REFRESH_RATE           0.05/60


#define Left_Wall_POS_X            0
#define Left_Wall_POS_Y            300
#define Left_Wall_WIDTH            100.0f
#define Left_Wall_HEIGHT           600.0f

#define BRICK_POS_X            400
#define BRICK_POS_Y            500
#define BRICK_WIDTH            100.0f
#define BRICK_HEIGHT           100.0f
#define BRICK_WAIT             0.0f

#define BALL_POS_X             400
#define BALL_POS_Y             50
#define BALL_RADIUS            50.0f
#define BALL_VELOCITY          100000.0f
#define BALL_SPHERE_SEGS       128

#define OBSTACLE_POS_X         900
#define OBSTACLE_MAX_POS_Y     400
#define OBSTACLE_MIN_POS_Y     200
#define OBSTACLE_MAX_WIDTH     100.0f
#define OBSTACLE_MIN_WIDTH     50.0f
#define OBSTACLE_MAX_HEIGHT    400.0f
#define OBSTACLE_MIN_HEIGHT    100.0f

@interface CBox2D : NSObject

@property float xDir;
@property float yDir;

// @property b2Vec2 _targetVector;

-(void) SetTargetVector:(float)posX:(float)posY;

//-(void) GenerateObstacle;

-(void) Update:(float)elapsedTime;  // update the Box2D engine
-(void) RegisterHit;                // Register when the ball hits the brick
-(void *)GetObjectPositions;        // Get the positions of the ball and brick

-(void) InitiateNewJump:(float)posX:(float)posY;
-(void) UpdateJumpTarget:(float)posX:(float)posY;
-(void) LaunchJump;


@end

#endif
