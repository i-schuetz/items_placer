//
//  Item.m
//  Dresser
//
//  Created by ischuetz on 02/07/2014.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Item.h"

@interface Item ()


@end

@implementation Item

- (id)initWithLetter: (NSString *)letter bgColor:(UIColor*)bgColor name:(NSString *)name description:(NSString *)description {
    self = [super init];
    if (self) {
        [self setLetter:letter];
        [self setBgColor:bgColor];
        [self setName:name];
        [self setDescription:description];
    }
    return self;
}


@end