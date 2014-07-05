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
    
    NSLog(@"Generated cave in %f seconds", [[NSDate date] timeIntervalSinceDate:startDate]);
}

@end
