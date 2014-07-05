//
//  Cave.m
//  CellularAutomataStarter
//
//  Created by Kim Pedersen on 23/02/14.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import "Cave.h"
#import "CaveCell.h"
#import "ShortestPathStep.h"

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
      _entrance = CGPointZero;
      _exit = CGPointZero;
      _minDistanceBetweenEntryAndExit = 32.0f;
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
            if ([self isEdgeAtGridCoordinate:coordinate]) {
                cell.type = CaveCellTypeWall;
            } else {
                cell.type = [self randomNumberBetween0and1] < self.chanceToBecomeWall ? CaveCellTypeWall :
                CaveCellTypeFloor;
            }
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
    
    if (self.connectedCave) {
        [self connectToMainCavern];
    } else {
        [self removeDisconnectedCaverns];
    }
    
    [self identifyCaverns];
    [self placeTreasure];
    [self placeEntranceAndExit];
    
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
                case CaveCellTypeEntry:
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile4_0"]];
                    break;
                    
                case CaveCellTypeExit:
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile3_0"]];
                    break;
                case CaveCellTypeTreasure:
                {
                    node = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"tile0_0"]];
                    
                    SKSpriteNode *treasure = [SKSpriteNode spriteNodeWithTexture:[self.atlas textureNamed:@"treasure"]];
                    treasure.name = @"TREASURE";
                    treasure.position = CGPointMake(0.0f, 0.0f);
                    [node addChild:treasure];
                    
                    break;
                }
                    
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

- (void)connectToMainCavern
{
    NSUInteger mainCavernIndex = [self mainCavernIndex];
    
    NSArray *mainCavern = (NSArray *)self.caverns[mainCavernIndex];
    
    for (NSUInteger cavernIndex = 0; cavernIndex < [self.caverns count]; cavernIndex++) {
        if (cavernIndex != mainCavernIndex) {
            NSArray *originCavern = self.caverns[cavernIndex];
            CaveCell *originCell = (CaveCell *)originCavern[arc4random() % [originCavern count]];
            CaveCell *destinationCell = (CaveCell *)mainCavern[arc4random() % [mainCavern count]];
            [self createPathBetweenOrigin:originCell destination:destinationCell];
        }
    }
}

// Added inList parameter as this implementation does not use properties to store
// open and closed lists.
- (void)insertStep:(ShortestPathStep *)step inList:(NSMutableArray *)list
{
    NSInteger stepFScore = [step fScore];
    NSInteger count = [list count];
    NSInteger i = 0;
    
    for (; i < count; i++) {
        if (stepFScore <= [[list objectAtIndex:i] fScore]) {
            break;
        }
    }
    
    [list insertObject:step atIndex:i];
}

- (NSInteger)costToMoveFromStep:(ShortestPathStep *)fromStep toAdjacentStep:(ShortestPathStep *)toStep
{
    // Always returns one, as it is equally expensive to move either up, down, left or right.
    return 1;
}

- (NSInteger)computeHScoreFromCoordinate:(CGPoint)fromCoordinate toCoordinate:(CGPoint)toCoordinate
{
    // Get the cell at the toCoordinate to calculate the hScore
    CaveCell *cell = [self caveCellFromGridCoordinate:toCoordinate];
    
    // It is 10 times more expensive to move through wall cells than floor cells.
    NSUInteger multiplier = cell.type = CaveCellTypeWall ? 10 : 1;
    
    return multiplier * (abs(toCoordinate.x - fromCoordinate.x) + abs(toCoordinate.y - fromCoordinate.y));
}

- (NSArray *)adjacentCellsCoordinateForCellCoordinate:(CGPoint)cellCoordinate
{
    NSMutableArray *tmp = [NSMutableArray arrayWithCapacity:4];
    
    // Top
    CGPoint p = CGPointMake(cellCoordinate.x, cellCoordinate.y - 1);
    if ([self isValidGridCoordinate:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
    }
    
    // Left
    p = CGPointMake(cellCoordinate.x - 1, cellCoordinate.y);
    if ([self isValidGridCoordinate:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
    }
    
    // Bottom
    p = CGPointMake(cellCoordinate.x, cellCoordinate.y + 1);
    if ([self isValidGridCoordinate:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
    }
    
    // Right
    p = CGPointMake(cellCoordinate.x + 1, cellCoordinate.y);
    if ([self isValidGridCoordinate:p]) {
        [tmp addObject:[NSValue valueWithCGPoint:p]];
    }
    
    return [NSArray arrayWithArray:tmp];
}

- (void)createPathBetweenOrigin:(CaveCell *)originCell destination:(CaveCell *)destinationCell
{
    NSMutableArray *openSteps = [NSMutableArray array];
    NSMutableArray *closedSteps = [NSMutableArray array];
    
    [self insertStep:[[ShortestPathStep alloc] initWithPosition:originCell.coordinate] inList:openSteps];
    
    do {
        // Get the lowest F cost step.
        // Because the list is ordered, the first step is always the one with the lowest F cost.
        ShortestPathStep *currentStep = [openSteps firstObject];
        
        // Add the current step to the closed list
        [closedSteps addObject:currentStep];
        
        // Remove it from the open list
        [openSteps removeObjectAtIndex:0];
        
        // If the currentStep is the desired cell coordinate, we are done!
        if (CGPointEqualToPoint(currentStep.position, destinationCell.coordinate)) {
            // Turn the path into floors to connect the caverns
            do {
                if (currentStep.parent != nil) {
                    CaveCell *cell = [self caveCellFromGridCoordinate:currentStep.position];
                    cell.type = CaveCellTypeFloor;
                }
                currentStep = currentStep.parent; // Go backwards
            } while (currentStep != nil);
            break;
        }
        
        // Get the adjacent cell coordinates of the current step
        NSArray *adjSteps = [self adjacentCellsCoordinateForCellCoordinate:currentStep.position];
        
        for (NSValue *v in adjSteps) {
            ShortestPathStep *step = [[ShortestPathStep alloc] initWithPosition:[v CGPointValue]];
            
            // Check if the step isn't already in the closed set
            if ([closedSteps containsObject:step]) {
                continue; // ignore it
            }
            
            // Compute the cost form the current step to that step
            NSInteger moveCost = [self costToMoveFromStep:currentStep toAdjacentStep:step];
            
            // Check if the step is already in the open list
            NSUInteger index = [openSteps indexOfObject:step];
            
            if (index == NSNotFound) { // Not on the open list, so add it
                
                // Set the current step as the parent
                step.parent = currentStep;
                
                // The G score is equal to the parent G score plus the cost to move from the parent to it
                step.gScore = currentStep.gScore + moveCost;
                
                // Compute the H score, which is the estimated move cost to move from that step
                // to the desired cell coordinate
                step.hScore = [self computeHScoreFromCoordinate:step.position
                                                   toCoordinate:destinationCell.coordinate];
                
                // Adding it with the function which is preserving the list ordered by F score
                [self insertStep:step inList:openSteps];
                
            } else { // Already in the open list
                
                // To retrieve the old one, which has its scores already computed
                step = [openSteps objectAtIndex:index];
                
                // Check to see if the G score for that step is lower if we use the current step to get there
                if ((currentStep.gScore + moveCost) < step.gScore) {
                    
                    // The G score is equal to the parent G score plus the cost to move the parent to it
                    step.gScore = currentStep.gScore + moveCost;
                    
                    // Because the G score has changed, the F score may have changed too.
                    // So to keep the open list ordered we have to remove the step, and re-insert it with
                    // the insert function, which is preserving the list ordered by F score.
                    ShortestPathStep *preservedStep = [[ShortestPathStep alloc] initWithPosition:step.position];
                    
                    // Remove the step from the open list
                    [openSteps removeObjectAtIndex:index];
                    
                    // Re-insert the step to the open list
                    [self insertStep:preservedStep inList:openSteps];
                }
            }
        }
        
    } while ([openSteps count] > 0);
}

- (void)constructPathFromStep:(ShortestPathStep *)step
{
    do {
        if (step.parent != nil) {
            CaveCell *cell = [self caveCellFromGridCoordinate:step.position];
            cell.type = CaveCellTypeFloor;
        }
        step = step.parent; // Go backwards
    } while (step != nil);
}

- (void)placeEntranceAndExit
{
    // 1
    NSUInteger mainCavernIndex = [self mainCavernIndex];
    NSArray *mainCavern = (NSArray *)self.caverns[mainCavernIndex];
    
    // 2
    NSUInteger mainCavernCount = [mainCavern count];
    CaveCell *entranceCell = (CaveCell *)mainCavern[arc4random() % mainCavernCount];
    
    // 3
    [self caveCellFromGridCoordinate:entranceCell.coordinate].type = CaveCellTypeEntry;
    _entrance = [self positionForGridCoordinate:entranceCell.coordinate];
    
    CaveCell *exitCell = nil;
    CGFloat distance = 0.0f;
    
    do
    {
        // 4
        exitCell = (CaveCell *)mainCavern[arc4random() % mainCavernCount];
        
        // 5
        NSInteger a = (exitCell.coordinate.x - entranceCell.coordinate.x);
        NSInteger b = (exitCell.coordinate.y - entranceCell.coordinate.y);
        distance = sqrtf(a * a + b * b);
        
        NSLog(@"Distance: %f", distance);
    }
    while (distance < self.minDistanceBetweenEntryAndExit);
    
    // 6
    [self caveCellFromGridCoordinate:exitCell.coordinate].type = CaveCellTypeExit;
    _exit = [self positionForGridCoordinate:exitCell.coordinate];
}

- (void)placeTreasure
{
    NSUInteger treasureHiddenLimit = 4;
    
    for (NSUInteger y = 0; y < self.gridSize.height; y++) {
        for (NSUInteger x = 0; x < self.gridSize.width; x++) {
            CaveCell *cell = (CaveCell *)self.grid[y][x];
            
            if (cell.type == CaveCellTypeFloor) {
                NSUInteger mooreNeighborWallCount =
                [self countWallMooreNeighborsFromGridCoordinate:CGPointMake(x, y)];
                
                if (mooreNeighborWallCount > treasureHiddenLimit) {
                    // Place treasure here
                    cell.type = CaveCellTypeTreasure;
                }
            }
        }
    }
}

- (CGPoint)gridCoordinateForPosition:(CGPoint)position
{
    return CGPointMake((position.x / self.tileSize.width), (position.y / self.tileSize.height));
}

- (CGRect)caveCellRectFromGridCoordinate:(CGPoint)coordinate
{
    if ([self isValidGridCoordinate:coordinate]) {
        CGPoint cellPosition = [self positionForGridCoordinate:coordinate];
        
        return CGRectMake(cellPosition.x - (self.tileSize.width / 2),
                          cellPosition.y - (self.tileSize.height / 2),
                          self.tileSize.width,
                          self.tileSize.height);
    }
    return CGRectZero;
}

- (BOOL)isEdgeAtGridCoordinate:(CGPoint)coordinate
{
    return ((NSUInteger)coordinate.x == 0 ||
            (NSUInteger)coordinate.x == (NSUInteger)self.gridSize.width - 1 ||
            (NSUInteger)coordinate.y == 0 ||
            (NSUInteger)coordinate.y == (NSUInteger)self.gridSize.height - 1);
}

@end
