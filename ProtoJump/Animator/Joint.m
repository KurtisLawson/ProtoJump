//
//  Joint.m
//  ProtoJump
//
//  Created by Kurtis Lawson on 2021-04-02.
//

#import "Joint.h"
#import <GLKit/GLKit.h>

@interface Joint() {
    // Transform to move from original position to current animated position, in model space.
    GLKMatrix4 animatedTransform;
    
    // == Used in the animator to calculate joint transforms
    GLKMatrix4 inverseBindTransform; // Original position relative to origin
    GLKMatrix4 localBindTransform; // Original pose relative to parent
}
@end

@implementation Joint

@synthesize index;
@synthesize name;
@synthesize children;
@synthesize invertable; // Set when inverting the bind transform. Can be used to check for success (?)

-(id) init:(int)index :(NSString *)name :(GLKMatrix4)bindLocalTransform {
    self = [super init];
    if (self) {
        NSLog(@"New joint has been initialized");
        // Init matrices
        children = [[NSMutableArray<Joint *> alloc] init];
        animatedTransform = GLKMatrix4Identity;
        inverseBindTransform = GLKMatrix4Identity;
        
        // Init properties
        self.index = index;
        self.name = name;
        self->localBindTransform = bindLocalTransform;
    }
    
    return self;
}

- (void)dealloc
{
    
}

-(void) addChild:(Joint *)child {
    [children addObject:child];
}

-(GLKMatrix4) getAnimatedTransform {
    return animatedTransform;
}

-(void) setAnimatedTransform:(GLKMatrix4)animationTransform {
    self->animatedTransform = animationTransform;
}

-(GLKMatrix4) getInverseBindTransform {
    return inverseBindTransform;
}

-(void) calcInverseBindTransform:(GLKMatrix4) parentBindTransform {
    // Calculate the model-space transform by multiplying the parent's transform with the local transform.
    GLKMatrix4 bindTransform = GLKMatrix4Multiply(parentBindTransform, localBindTransform);
    
    // The inverse bind transform is calculated recursively using the parent's model-space transform, for each child. This loop will not enter if no child exists.
    inverseBindTransform = GLKMatrix4Invert(bindTransform, invertable);
    for (Joint *child in children) {
        [child calcInverseBindTransform:bindTransform];
    }
}

@end
