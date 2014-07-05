//
//  Cave.h
//  CellularAutomataStarter
//
//  Created by Kim Pedersen on 23/02/14.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface Cave : SKNode

// The texture atlas used
@property (strong, nonatomic, readonly) SKTextureAtlas *atlas;

// The size of the map in tiles
@property (assign, nonatomic, readonly) CGSize gridSize;

@property (assign, nonatomic, readonly) CGSize tileSize;

@property (assign, nonatomic) CGFloat chanceToBecomeWall;

@property (assign, nonatomic) NSUInteger floorsToWallConversion;
@property (assign, nonatomic) NSUInteger wallsToFloorConversion;

@property (assign, nonatomic) NSUInteger numberOfTransitionSteps;

@property (assign, nonatomic) BOOL connectedCave;

@property (assign, nonatomic, readonly) CGPoint entrance;
@property (assign, nonatomic, readonly) CGPoint exit;
@property (assign, nonatomic) CGFloat minDistanceBetweenEntryAndExit;

// Initializes a new instance of the cave class with a given texture atlas and grid size
- (instancetype)initWithAtlasNamed:(NSString *)name gridSize:(CGSize)gridSize;

- (void)generateWithSeed:(unsigned int)seed;


@end
