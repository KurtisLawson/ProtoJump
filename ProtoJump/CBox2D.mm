//
//  Copyright © Borna Noureddin. All rights reserved.
//

#include <Box2D/Box2D.h>
#include "CBox2D.h"
#include <stdio.h>
#include <map>

// Some Box2D engine paremeters
const float MAX_TIMESTEP = REFRESH_RATE;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;


#pragma mark - Box2D contact listener class

// This C++ class is used to handle collisions
class CContactListener : public b2ContactListener
{
public:
    void BeginContact(b2Contact* contact) {};
    void EndContact(b2Contact* contact) {};
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());
        if (state2[0] == b2_addState)
        {
            // Use contact->GetFixtureA()->GetBody() to get the body
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            CBox2D *parentObj = (__bridge CBox2D *)(bodyA->GetUserData());
            // Call RegisterHit (assume CBox2D object is in user data)
            [parentObj RegisterHit];    // assumes RegisterHit is a callback function to register collision
        }
    }
    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
};


#pragma mark - CBox2D

@interface CBox2D ()
{
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;
    //Obstacle *obstacle;

    //b2BodyDef *groundBodyDef;
    //b2Body *groundBody;
    //b2PolygonShape *groundBox;

    b2Body *theLeftWall, *theBall, *theGround, *theRoof, *theObstacle;

    CContactListener *contactListener;
    CGFloat width, height;
    float totalElapsedTime;
    int step;
    // You will also need some extra variables here for the logic
    bool ballHitLeftWall;
    bool ballLaunched;
    bool obstacleHitCleaner;
}
@end

@implementation CBox2D

@synthesize xDir, yDir;
@synthesize dead;
@synthesize obstacle;
//@synthesize _targetVector;

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, GRAVITY);
        world = new b2World(*gravity);
        
        b2BodyDef gdBodyDef;
        gdBodyDef.type = b2_staticBody;
        gdBodyDef.position.Set(GROUND_ROOF_POS_X, GROUND_ROOF_PADDING);//width, height of the ground
        theGround = world->CreateBody(&gdBodyDef);
        b2PolygonShape gdBox;
        gdBox.SetAsBox(GROUND_ROOF_WIDTH, GROUND_ROOF_HEIGHT);
        theGround->CreateFixture(&gdBox, 0.0f);
        
        b2BodyDef rfBodyDef;
        rfBodyDef.type = b2_staticBody;
        rfBodyDef.position.Set(GROUND_ROOF_POS_X, SCREEN_BOUNDS_Y - GROUND_ROOF_PADDING);
        theRoof = world->CreateBody(&rfBodyDef);
        b2PolygonShape rfBox;
        rfBox.SetAsBox(GROUND_ROOF_WIDTH, GROUND_ROOF_HEIGHT);// physical box
        theRoof->CreateFixture(&rfBox, 0.0f);

        // For brick & ball sample
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Set up the brick and ball objects for Box2D
        b2BodyDef leftwallBodyDef;
        leftwallBodyDef.type = b2_kinematicBody;
        leftwallBodyDef.position.Set(Left_Wall_POS_X, Left_Wall_POS_Y);
        theLeftWall = world->CreateBody(&leftwallBodyDef);
        if (theLeftWall)
        {
            theLeftWall->SetUserData((__bridge void *)self);
            theLeftWall->SetAwake(false);
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(Left_Wall_WIDTH/2, Left_Wall_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 0.0f;
            theLeftWall->CreateFixture(&fixtureDef);
            
            b2BodyDef ballBodyDef;
            ballBodyDef.type = b2_dynamicBody;
            ballBodyDef.position.Set(BALL_POS_X, BALL_POS_Y);
            theBall = world->CreateBody(&ballBodyDef);
            
            if (theBall)
            {
                theBall->SetUserData((__bridge void *)self);
                theBall->SetAwake(false);
                b2CircleShape circle;
                circle.m_p.Set(0, 0);
                circle.m_radius = BALL_RADIUS;
                b2FixtureDef circleFixtureDef;
                circleFixtureDef.shape = &circle;
                circleFixtureDef.density = 0.1f;
                circleFixtureDef.friction = 0.3f;
                circleFixtureDef.restitution = 0.0f;
                theBall->CreateFixture(&circleFixtureDef);
            }
        }
        
        obstacle = [[Obstacle alloc]init];
        b2BodyDef obstacleBodyDef;
        obstacleBodyDef.type = b2_staticBody;
        obstacleBodyDef.position.Set(OBSTACLE_POS_X, obstacle.posY);
        theObstacle = world->CreateBody(&obstacleBodyDef);
        if (theObstacle)
        {
            theObstacle->SetUserData((__bridge void *)self);
            theObstacle->SetAwake(false);
            b2PolygonShape staticBox;
            staticBox.SetAsBox(obstacle.width/2, obstacle.height/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &staticBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 0.0f;
            theObstacle->CreateFixture(&fixtureDef);
        }
        
        totalElapsedTime = 0;
        ballHitLeftWall = false;
        ballLaunched = false;
    }
    return self;
}

- (void)dealloc
{
    if (gravity) delete gravity;
    if (world) delete world;
    if (contactListener) delete contactListener;
}

-(void)Update:(float)elapsedTime
{
    // Check here if we need to launch the ball
    //  and if so, use ApplyLinearImpulse() and SetActive(true)
    if (ballLaunched)
    {
        theBall->ApplyLinearImpulse(b2Vec2(0, BALL_VELOCITY), theBall->GetPosition(), true);
        theBall->SetLinearVelocity(b2Vec2(xDir * JUMP_MAGNITUDE, yDir * JUMP_MAGNITUDE));
        theBall->SetActive(true);
#ifdef LOG_TO_CONSOLE
        NSLog(@"Applying impulse %f to ball\n", BALL_VELOCITY);
#endif
        ballLaunched = false;
    }
    
    // Check if it is time yet to drop the brick, and if so
    //  call SetAwake()
    totalElapsedTime += elapsedTime;
    if ((totalElapsedTime > BRICK_WAIT) && theLeftWall)
        theLeftWall->SetAwake(true);
    
    // If the last collision test was positive,
    //  stop the ball and destroy the brick
    if (ballHitLeftWall)
    {
        world->DestroyBody(theBall);
        theBall = NULL;
        ballHitLeftWall = false;
        dead = true;
    }
    
    if(theObstacle)
        theObstacle->SetAwake(true);

    //Makes the ground and roof in sync of viewport
    if (theGround){
        theGround->SetTransform(b2Vec2(400 + step/SCREEN_BOUNDS_X - step,0), theGround->GetAngle());
        theGround->SetAwake(true);
    }
    
    if (theRoof){
        theRoof->SetTransform(b2Vec2(400 + step/SCREEN_BOUNDS_X - step,SCREEN_BOUNDS_Y), theGround->GetAngle());
        theRoof->SetAwake(true);
    }
    
    if(theLeftWall){
        theLeftWall->SetTransform(b2Vec2(0 + step/SCREEN_BOUNDS_X - step,SCREEN_BOUNDS_Y/2), theLeftWall->GetAngle());
    }
    
    if (world)
    {
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
        }
        
        if (elapsedTime > 0.0f)
        {
            world->Step(elapsedTime, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
        }
    }
    step--;
}

-(void)RegisterHit
{
    // Set some flag here for processing later...
    ballHitLeftWall = true;
}

-(void) SetTargetVector:(float)posX :(float)posY
{
    // Curate ball Pos value to be scaled to screen space.
    b2Vec2 currentBallPos = theBall->GetPosition();
    currentBallPos.x = ((currentBallPos.x + step)/ SCREEN_BOUNDS_X);
    
    currentBallPos.y = -((currentBallPos.y / SCREEN_BOUNDS_Y) - 1);
    
    // Direction will be the vector between the two curated points.
    xDir = posX - currentBallPos.x;
    yDir =  currentBallPos.y - posY;
    
}

// Halt current velocity, set initial target position
-(void)InitiateNewJump:(float)posX :(float)posY
{
    theBall->SetLinearVelocity(b2Vec2(0, 150));
    
//    [SetTargetVector:posX :posY];
    
    // Curate ball Pos value to be scaled to screen space.
    b2Vec2 currentBallPos = theBall->GetPosition();
    currentBallPos.x = ((currentBallPos.x + step) / SCREEN_BOUNDS_X);
    
    currentBallPos.y = -((currentBallPos.y / SCREEN_BOUNDS_Y) - 1);
    
    // Direction will be the vector between the two curated points.
    xDir = posX - currentBallPos.x;
    yDir =  currentBallPos.y - posY;
    
    // Normalize the values
    float vectorMagnitude = sqrt((pow(xDir, 2) + pow(yDir, 2)));
    xDir = xDir / vectorMagnitude;
    yDir = yDir / vectorMagnitude;
    
    printf("New tap, velocity targer %4.2f, %4.2f...\n", xDir, yDir);
}

// Update current position vector
-(void)UpdateJumpTarget:(float)posX :(float)posY
{
    
    // Curate ball Pos value to be scaled to screen space.
    b2Vec2 currentBallPos = theBall->GetPosition();
    currentBallPos.x = ((currentBallPos.x + step)/ SCREEN_BOUNDS_X);
    
    currentBallPos.y = -((currentBallPos.y / SCREEN_BOUNDS_Y) - 1);
    
    // Direction will be the vector between the two curated points.
    
    xDir = posX - currentBallPos.x;
    yDir = currentBallPos.y - posY;
    
    // Normalize the values
    float vectorMagnitude = sqrt((pow(xDir, 2) + pow(yDir, 2)));
    xDir = xDir / vectorMagnitude;
    yDir = yDir / vectorMagnitude;
    
    printf("Updating Velocity Target to %4.2f, %4.2f..\n", xDir, yDir);
}

//
-(void)LaunchJump
{
    // Set some flag here for processing later...
    ballLaunched = true;
}

-(void *)GetObjectPositions
{
    auto *objPosList = new std::map<const char *,b2Vec2>;
    if (theBall)
        (*objPosList)["ball"] = theBall->GetPosition();
    if (theLeftWall)
        (*objPosList)["leftwall"] = theLeftWall->GetPosition();
    if (theObstacle)
        (*objPosList)["obstacle"] = theObstacle->GetPosition();
    if (theGround)
        (*objPosList)["ground"] = theGround->GetPosition();
    if (theRoof)
        (*objPosList)["roof"] = theRoof->GetPosition();
    return reinterpret_cast<void *>(objPosList);
}

@end
