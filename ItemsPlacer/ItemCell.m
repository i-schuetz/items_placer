//
//  ItemCell.m
//  Dresser
//
//  Created by ischuetz on 30/06/2014.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

#import "ItemCell.h"

@implementation ItemCell

- (instancetype)initWithFrame:(CGRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        // Initialization code
        [self setBackgroundColor: [UIColor redColor]];
    }
    return self;
}

@end
