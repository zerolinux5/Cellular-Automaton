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

// Initializes a new instance of the cave class with a given texture atlas and grid size
- (instancetype)initWithAtlasNamed:(NSString *)name gridSize:(CGSize)gridSize;

- (void)generateWithSeed:(unsigned int)seed;


@end
