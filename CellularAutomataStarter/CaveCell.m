//
//  CaveCell.m
//  CellularAutomataStarter
//
//  Created by Jesus Magana on 7/5/14.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import "CaveCell.h"

@implementation CaveCell

- (instancetype)initWithCoordinate:(CGPoint)coordinate
{
    if ((self = [super init])) {
        _coordinate = coordinate;
        _type = CaveCellTypeInvalid;
    }
    return self;
}

@end
