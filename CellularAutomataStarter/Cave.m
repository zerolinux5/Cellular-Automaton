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
@property (strong, nonatomic) NSMutableArray *caverns;
@end

@implementation Cave

- (instancetype)initWithAtlasNamed:(NSString *)name gridSize:(CGSize)gridSize
{
  if ((self = [super init])) {
    // Set properties
    _atlas = [SKTextureAtlas atlasNamed:name];
    _gridSize = gridSize;
    _tileSize = [self sizeOfTiles];
    _chanceToBecomeWall = 0.45f;
    _floorsToWallConversion = 4;
    _wallsToFloorConversion = 3;
    _numberOfTransitionSteps = 2;
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
            cell.type = [self randomNumberBetween0and1] < self.chanceToBecomeWall ? CaveCellTypeWall : CaveCellTypeFloor;
            [row addObject:cell];
        }
        
        [self.grid addObject:row];
    }
}

- (void)generateWithSeed:(unsigned int)seed
{
    NSLog(@"Generating cave...");
    NSDate *startDate = [NSDate date];
    
    srandom(seed);
    
    [self initializeGrid];
    
    for (NSUInteger step = 0; step < self.numberOfTransitionSteps; step++) {
        NSLog(@"Performing transition step %lu", (unsigned long)step + 1);
        [self doTransitionStep];
    }
    
    [self identifyCaverns];
    
    [self removeDisconnectedCaverns];
    
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

- (CGFloat) randomNumberBetween0and1
{
    return random() / (float)0x7fffffff;
}

- (NSUInteger)countWallMooreNeighborsFromGridCoordinate:(CGPoint)coordinate
{
    NSUInteger wallCount = 0;
    
    for (NSInteger i = -1; i < 2; i++) {
        for (NSInteger j = -1; j < 2; j++) {
            // The middle point is the same as the passed Grid Coordinate, so skip it
            if ( i == 0 && j == 0 ) {
                break;
            }
            
            CGPoint neighborCoordinate = CGPointMake(coordinate.x + i, coordinate.y + j);
            if (![self isValidGridCoordinate:neighborCoordinate]) {
                wallCount += 1;
            } else if ([self caveCellFromGridCoordinate:neighborCoordinate].type == CaveCellTypeWall) {
                wallCount += 1;
            }
        }
    }
    return wallCount;
}

- (void)doTransitionStep
{
    // 1
    NSMutableArray *newGrid = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.height];
    
    // 2
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        NSMutableArray *newRow = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.width];
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            CGPoint coordinate = CGPointMake(x, y);
            
            // 3
            NSUInteger mooreNeighborWallCount = [self countWallMooreNeighborsFromGridCoordinate:coordinate];
            
            // 4
            CaveCell *oldCell = [self caveCellFromGridCoordinate:coordinate];
            CaveCell *newCell = [[CaveCell alloc] initWithCoordinate:coordinate];
            
            // 5
            // 5a
            if (oldCell.type == CaveCellTypeWall) {
                newCell.type = (mooreNeighborWallCount < self.wallsToFloorConversion) ?
                CaveCellTypeFloor : CaveCellTypeWall;
            } else {
                // 5b
                newCell.type = (mooreNeighborWallCount > self.floorsToWallConversion) ?
                CaveCellTypeWall : CaveCellTypeFloor;
            }
            [newRow addObject:newCell];
        }
        [newGrid addObject:newRow];
    }
    
    // 6
    self.grid = newGrid;
}

- (void)floodFillCavern:(NSMutableArray *)array fromCoordinate:(CGPoint)coordinate
             fillNumber:(NSInteger)fillNumber
{
    // 1
    CaveCell *cell = (CaveCell *)array[(NSUInteger)coordinate.y][(NSUInteger)coordinate.x];
    
    // 2
    if (cell.type != CaveCellTypeFloor) {
        return;
    }
    
    // 3
    cell.type = fillNumber;
    
    // 4
    [[self.caverns lastObject] addObject:cell];
    
    // 5
    if (coordinate.x > 0) {
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x - 1, coordinate.y)
                   fillNumber:fillNumber];
    }
    if (coordinate.x < self.gridSize.width - 1) {
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x + 1, coordinate.y)
                   fillNumber:fillNumber];
    }
    if (coordinate.y > 0) {
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x, coordinate.y - 1)
                   fillNumber:fillNumber];
    }
    if (coordinate.y < self.gridSize.height - 1) {
        [self floodFillCavern:array fromCoordinate:CGPointMake(coordinate.x, coordinate.y + 1)
                   fillNumber:fillNumber];
    }
}

- (void)identifyCaverns
{
    // 1
    self.caverns = [NSMutableArray array];
    
    // 2
    NSMutableArray *floodFillArray = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.height];
    
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        NSMutableArray *floodFillArrayRow = [NSMutableArray arrayWithCapacity:(NSUInteger)self.gridSize.width];
        
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            CaveCell *cellToCopy = (CaveCell *)self.grid[y][x];
            CaveCell *copiedCell = [[CaveCell alloc] initWithCoordinate:cellToCopy.coordinate];
            copiedCell.type = cellToCopy.type;
            [floodFillArrayRow addObject:copiedCell];
        }
        
        [floodFillArray addObject:floodFillArrayRow];
    }
    
    // 3
    NSInteger fillNumber = CaveCellTypeMax;
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            if (((CaveCell *)floodFillArray[y][x]).type == CaveCellTypeFloor) {
                [self.caverns addObject:[NSMutableArray array]];
                [self floodFillCavern:floodFillArray fromCoordinate:CGPointMake(x, y) fillNumber:fillNumber];
                fillNumber++;
            }
        }
    }
    
    NSLog(@"Number of caverns in cave: %lu", (unsigned long)[self.caverns count]);
}

- (NSInteger)mainCavernIndex
{
    NSInteger mainCavernIndex = -1;
    NSUInteger maxCavernSize = 0;
    
    for (NSUInteger i = 0; i < [self.caverns count]; i++) {
        NSArray *caveCells = (NSArray *)self.caverns[i];
        NSUInteger caveCellsCount = [caveCells count];
        
        if (caveCellsCount > maxCavernSize) {
            maxCavernSize = caveCellsCount;
            mainCavernIndex = i;
        }
    }
    
    return mainCavernIndex;
}

- (void) removeDisconnectedCaverns
{
    NSInteger mainCavernIndex = [self mainCavernIndex];
    NSUInteger cavernsCount = [self.caverns count];
    
    if (cavernsCount > 0) {
        for (NSUInteger i = 0; i < cavernsCount; i++) {
            if (i != mainCavernIndex) {
                NSArray *array = (NSArray *)self.caverns[i];
                
                for (CaveCell *cell in array) {
                    ((CaveCell *)self.grid[(NSUInteger)cell.coordinate.y][(NSUInteger)cell.coordinate.x]).type =
                    CaveCellTypeWall;
                }
            }
        }
    }
}

@end
