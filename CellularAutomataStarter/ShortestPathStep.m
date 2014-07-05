//
//  ShortestPathStep.m
//  CellularAutomataStarter
//
//  Created by Jesus Magana on 7/5/14.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import "ShortestPathStep.h"

@implementation ShortestPathStep

- (instancetype)initWithPosition:(CGPoint)pos
{
    if ((self = [super init])) {
        _position = pos;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@  pos=%@  g=%ld  h=%ld  f=%ld", [super description],
            NSStringFromCGPoint(self.position), (long)self.gScore, (long)self.hScore, (long)[self fScore]];
}

- (BOOL)isEqual:(ShortestPathStep *)other
{
    return CGPointEqualToPoint(self.position, other.position);
}

- (NSInteger)fScore
{
    return self.gScore + self.hScore;
}

@end
