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
    b2BodyDef *groundBodyDef;
    b2Body *groundBody;
    b2PolygonShape *groundBox;
    b2Body *theBrick, *theBall;
    CContactListener *contactListener;
    float totalElapsedTime;

    // You will also need some extra variables here for the logic
    bool ballHitBrick;
    bool ballLaunched;
}
@end

@implementation CBox2D

@synthesize xDir, yDir;
//@synthesize _targetVector;

- (instancetype)init
{
    self = [super init];
    if (self) {
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, GRAVITY);
        world = new b2World(*gravity);
        
        // For HelloWorld
        groundBodyDef = NULL;
        groundBody = NULL;
        groundBox = NULL;

        // For brick & ball sample
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Set up the brick and ball objects for Box2D
        b2BodyDef brickBodyDef;
        brickBodyDef.type = b2_dynamicBody;
        brickBodyDef.position.Set(BRICK_POS_X, BRICK_POS_Y);
        theBrick = world->CreateBody(&brickBodyDef);
        if (theBrick)
        {
            theBrick->SetUserData((__bridge void *)self);
            theBrick->SetAwake(false);
            b2PolygonShape dynamicBox;
            dynamicBox.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            b2FixtureDef fixtureDef;
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            theBrick->CreateFixture(&fixtureDef);
            
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
                circleFixtureDef.restitution = 1.0f;
                theBall->CreateFixture(&circleFixtureDef);
            }
        }
        
        totalElapsedTime = 0;
        ballHitBrick = false;
        ballLaunched = false;
    }
    return self;
}

- (void)dealloc
{
    if (gravity) delete gravity;
    if (world) delete world;
    if (groundBodyDef) delete groundBodyDef;
    if (groundBox) delete groundBox;
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
    if ((totalElapsedTime > BRICK_WAIT) && theBrick)
        theBrick->SetAwake(true);
    
    // If the last collision test was positive,
    //  stop the ball and destroy the brick
//    if (ballHitBrick)
//    {
//        theBall->SetLinearVelocity(b2Vec2(0, 0));
//        theBall->SetAngularVelocity(0);
//        theBall->SetActive(false);
//        world->DestroyBody(theBrick);
//        theBrick = NULL;
//        ballHitBrick = false;
//    }

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
}

-(void)RegisterHit
{
    // Set some flag here for processing later...
    ballHitBrick = true;
}

-(void) SetTargetVector:(float)posX :(float)posY
{
    // Curate ball Pos value to be scaled to screen space.
    b2Vec2 currentBallPos = theBall->GetPosition();
    currentBallPos.x = (currentBallPos.x / SCREEN_BOUNDS_X);
    
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
    currentBallPos.x = (currentBallPos.x / SCREEN_BOUNDS_X);
    
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
    currentBallPos.x = (currentBallPos.x / SCREEN_BOUNDS_X);
    
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
    if (theBrick)
        (*objPosList)["brick"] = theBrick->GetPosition();
    return reinterpret_cast<void *>(objPosList);
}



-(void)HelloWorld
{
    groundBodyDef = new b2BodyDef;
    groundBodyDef->position.Set(0.0f, -10.0f);
    groundBody = world->CreateBody(groundBodyDef);
    groundBox = new b2PolygonShape;
    groundBox->SetAsBox(50.0f, 10.0f);
    
    groundBody->CreateFixture(groundBox, 0.0f);
    
    // Define the dynamic body. We set its position and call the body factory.
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(0.0f, 4.0f);
    b2Body* body = world->CreateBody(&bodyDef);
    
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(1.0f, 1.0f);
    
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &dynamicBox;
    
    // Set the box density to be non-zero, so it will be dynamic.
    fixtureDef.density = 1.0f;
    
    // Override the default friction.
    fixtureDef.friction = 0.3f;
    
    // Add the shape to the body.
    body->CreateFixture(&fixtureDef);
    
    // Prepare for simulation. Typically we use a time step of 1/60 of a
    // second (60Hz) and 10 iterations. This provides a high quality simulation
    // in most game scenarios.
    float32 timeStep = 1.0f / 60.0f;
    int32 velocityIterations = 6;
    int32 positionIterations = 2;
    
    // This is our little game loop.
    for (int32 i = 0; i < 60; ++i)
    {
        // Instruct the world to perform a single step of simulation.
        // It is generally best to keep the time step and iterations fixed.
        world->Step(timeStep, velocityIterations, positionIterations);
        
        // Now print the position and angle of the body.
        b2Vec2 position = body->GetPosition();
        float32 angle = body->GetAngle();
        
//        printf("%4.2f %4.2f %4.2f\n", position.x, position.y, angle);
    }
}

@end
