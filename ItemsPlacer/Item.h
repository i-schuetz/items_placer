//
//  Item.h
//  Dresser
//
//  Created by ischuetz on 02/07/2014.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface Item : NSObject

@property (nonatomic, strong) NSString *letter;
@property (nonatomic, strong) UIColor * bgColor;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *description;

- (id)initWithLetter: (NSString *)letter bgColor:(UIColor *)bgColor name:(NSString *)name description:(NSString *)description;

@end