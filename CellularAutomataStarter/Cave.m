//
//  Cave.m
//  CellularAutomataStarter
//
//  Created by Kim Pedersen on 23/02/14.
//  Copyright (c) 2014 Kim Pedersen. All rights reserved.
//

#import "Cave.h"

@interface Cave ()
// Add private properties to the class extension
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

@end
