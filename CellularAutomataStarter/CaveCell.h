//
//  CaveCell.h
//  CellularAutomataStarter
//
//  Created by Jesus Magana on 7/5/14.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, CaveCellType) {
    CaveCellTypeInvalid = -1,
    CaveCellTypeWall,
    CaveCellTypeFloor,
    CaveCellTypeMax
};

@interface CaveCell : NSObject

@property (assign, nonatomic) CGPoint coordinate;
@property (assign, nonatomic) CaveCellType type;

- (instancetype)initWithCoordinate:(CGPoint)coordinate;

@end
