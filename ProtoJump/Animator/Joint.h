//
//  Joint.h
//  ProtoJump
//
//  Created by Kurtis Lawson on 2021-04-02.
//      This solution was adapted to Objective C from a ThinMaxtrix Java solution.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Joint : NSObject
    
@property const int index;
@property const NSString* name;
@property const NSMutableArray<Joint *> *children;

// System property for calculating Inverse Bind Transform
@property bool *invertable;

- (id) init:(int) index: (NSString *) name: (GLKMatrix4) bindLocalTransform;

- (void) addChild:(Joint *) child;
- (GLKMatrix4) getAnimatedTransform;
- (void) setAnimatedTransform: (GLKMatrix4) animationTransform;
- (GLKMatrix4) getInverseBindTransform;
- (void) calcInverseBindTransform:(GLKMatrix4) parentBindTransform;

@end

NS_ASSUME_NONNULL_END
