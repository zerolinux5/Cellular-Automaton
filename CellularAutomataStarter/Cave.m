//
//  Cave.m
//  CellularAutomataStarter
//
//  Created by Kim Pedersen on 23/02/14.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import "Cave.h"
#import "CaveCell.h"

@interface Cave ()
// Add private properties to the class extension
@property (strong, nonatomic) NSMutableArray *grid;
@end

@implementation Cave

- (instancetype)initWithAtlasNamed:(NSString *)name gridSize:(CGSize)gridSize
{
  if ((self = [super init])) {
    // Set properties
    _atlas = [SKTextureAtlas atlasNamed:name];
    _gridSize = gridSize;
    _tileSize = [self sizeOfTiles];
  }
  return self;
}

- (void)initializeGrid
{
    self.grid = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.height];
    
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.width];
        
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            CGPoint coordinate = CGPointMake(x, y);
            CaveCell *cell = [[CaveCell alloc] initWithCoordinate:coordinate];
            cell.type = CaveCellTypeFloor;
            [row addObject:cell];
        }
        
        [self.grid addObject:row];
    }
}

- (void)generateWithSeed:(unsigned int)seed
{
    NSLog(@"Generating cave...");
    NSDate *startDate = [NSDate date];
    
    [self initializeGrid];
    [self generateTiles];
    
    NSLog(@"Generated cave in %f seconds", [[NSDate date] timeIntervalSinceDate:startDate]);
}

- (BOOL)isValidGridCoordinate:(CGPoint)coordinate
{
    return !(coordinate.x < 0 ||
             coordinate.x >= self.gridSize.width ||
             coordinate.y < 0 ||
             coordinate.y >= self.gridSize.height);
}

- (CaveCell *)caveCellFromGridCoordinate:(CGPoint)coordinate
{
    if ([self isValidGridCoordinate:coordinate]) {
        return (CaveCell *)self.grid[(NSUInteger)coordinate.y][(NSUInteger)coordinate.x];
    }
    
    return nil;
}

- (void)generateTiles
{
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            CaveCell *cell = [self caveCellFromGridCoordinate:CGPointMake(x, y)];
            
            SKSpriteNode *node;
            
            switch (cell.type) {
                case CaveCellTypeWall:
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile2_0"]];
                    break;
                    
                default:
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile0_0"]];
                    break;
            }
            
            // Add code to position node here:
            node.position = [self positionForGridCoordinate:CGPointMake(x, y)];
            
            node.blendMode = SKBlendModeReplace;
            node.texture.filteringMode = SKTextureFilteringNearest;
            
            [self addChild:node];
        }
    }
}

- (CGSize)sizeOfTiles
{
    SKTexture *texture = [self.atlas textureNamed:@"tile0_0"];
    return texture.size;
}

- (CGPoint)positionForGridCoordinate:(CGPoint)coordinate
{
    return CGPointMake(coordinate.x * self.tileSize.width + self.tileSize.width / 2.0f,
                       (coordinate.y * self.tileSize.height + self.tileSize.height / 2.0f));
}

@end
