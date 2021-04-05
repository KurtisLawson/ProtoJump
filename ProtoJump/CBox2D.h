//
//  Copyright © Borna Noureddin. All rights reserved.
//

#ifndef MyGLGame_CBox2D_h
#define MyGLGame_CBox2D_h

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

#import "Player.h"
#import "Obstacle.h"


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
#define GROUND_ROOF_PADDING    10.0f
#define GROUND_ROOF_POS_X      400
#define GROUND_ROOF_WIDTH      800.0f
#define GROUND_ROOF_HEIGHT     10.0f

#define GAME_SPEED             5

@interface CBox2D : NSObject

@property float xDir;
@property float yDir;
@property bool dead;
@property (nonatomic) Obstacle * obstacle;
@property (nonatomic) Player * player;

// @property b2Vec2 _targetVector;

-(void) SetTargetVector:(float)posX:(float)posY;

//-(void) GenerateObstacle;

-(void) Update:(float)elapsedTime;  // update the Box2D engine
-(void) RegisterHit;// Register when the ball hits the brick
-(void) RegisterHitObstacle;//when ball hits an obstacle body
-(void *)GetObjectPositions;        // Get the positions of the ball and brick

-(void) InitiateNewJump:(float)posX:(float)posY;
-(void) UpdateJumpTarget:(float)posX:(float)posY;
-(void) LaunchJump;


@end

#endif
