//
//  Copyright © Borna Noureddin. All rights reserved.
//

#ifndef Renderer_h
#define Renderer_h
#import <GLKit/GLKit.h>
#import "CBox2D.h"
#import "Obstacle.h"

@interface Renderer : NSObject

@property (strong, nonatomic) CBox2D *box2d;
@property float totalElapsedTime;

- (void)setup:(GLKView *)view;
- (void)loadModels;
- (void)update;
- (void)draw:(CGRect)drawRect;

- (GLuint)setupTexture:(NSString *)fileName;

@end

#endif /* Renderer_h */
