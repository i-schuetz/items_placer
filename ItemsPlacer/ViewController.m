//
//  ViewController.m
//  Dresser
//
//  Created by ischuetz on 30/06/2014.
//  Copyright (c) 2014 ivanschuetz. All rights reserved.
//

#import "ViewController.h"
#import "Item.h"
#import "ItemCell.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView; //possible future use - currently this could be also a plain view
@property (weak, nonatomic) IBOutlet UICollectionView *itemsView;
@property (weak, nonatomic) IBOutlet UIView *deleteView;


@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, strong) UISnapBehavior *snapBehavior;
@property (weak, nonatomic) IBOutlet UIButton *modeButton;

//TODO infoView custom view
@property (weak, nonatomic) IBOutlet UIView *infoView;
@property (weak, nonatomic) IBOutlet UILabel *infoText;
@property (weak, nonatomic) IBOutlet UILabel *infoTitle;
@property (strong, nonatomic) IBOutlet UIView *infoImage;


@end

@implementation ViewController {
    NSMutableArray *items;
    
    UIView *draggingView;
    
    NSArray *draggingViewsTest;
    
    CGPoint itemStartPanPoint;
    CGPoint placedStartPanPoint;
    
    BOOL placedIsInItemsView;
    CGPoint lastPlacedLocation;
    
    float buttonRadius;
    
    //TODO infoView custom view
    BOOL infoViewIsShowing;
    
    BOOL draggingItemsViewBlocked; //used to prevent processing of new drags in the items bar while the snap-back animation of last drag is still active
    //the problem with this is that snap-back animation sets draggingView to null, and detaches it from the parent
    //if a new drag starts before snap-back from previous one finishes, the new drag will set draggingView to a new view, and snap-back finish will null and detach this new view.
    //and when we try to start snap-back on the new view, we get null reference crash
    
    BOOL draggingItemsViewBeganProcessed; //this is a lock to ensure that touches end and move is processed only when we processed the corresponding touches start
    //we have to prevent the situation that, because draggingItemsViewBlocked was set to true, touches start is not processed, but we process move or end and this leads to crash
}

- (void) snapView:(UIView *)view toPoint:(CGPoint)point  {
    self.animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.view];
    
    self.animator.delegate = self;
    
    self.snapBehavior = [[UISnapBehavior alloc] initWithItem:view snapToPoint:point];
    
    self.snapBehavior.damping = 1.0f;
    [self.animator addBehavior:self.snapBehavior];
}


- (void)dynamicAnimatorDidPause:(UIDynamicAnimator*)animator {
    if (draggingView && draggingView.superview && [draggingView isDescendantOfView:draggingView.superview]) {
        [draggingView removeFromSuperview];
    }
    draggingView = NULL;
    draggingItemsViewBlocked = false;
}


- (UIColor *)getRandomColor {
    float red = rand() % 256 / 255.0;
    float green = rand() % 256 / 255.0;
    float blue = rand() % 256 / 255.0;

    float add = .4; //make it brighter
    
    red = red + add;
    green = green + add;
    blue = blue + add;
    
    return [[UIColor alloc] initWithRed:red green:green blue:blue alpha:1];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    items = [[NSMutableArray alloc] init];
    
    NSArray *letters = @[@"A", @"B", @"C", @"D", @"E", @"F", @"G", @"H", @"I", @"J", @"K", @"L", @"M", @"N", @"O"];
    for (NSString *letter in letters) {
        [items addObject:[[Item alloc] initWithLetter:letter bgColor:[self getRandomColor] name:[NSString stringWithFormat:@"%@-Name", letter] description:@"Lorem ipsum dolor sit amet, consectetur adipiscing elit."]];
    }

    self.view.translatesAutoresizingMaskIntoConstraints = false;
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    [flowLayout setScrollDirection:UICollectionViewScrollDirectionHorizontal];
    [flowLayout setMinimumInteritemSpacing:30.0f];
    [flowLayout setMinimumLineSpacing:10.0f];
    [_itemsView setCollectionViewLayout:flowLayout];
    
    buttonRadius = 24.0f;
}


- (void)viewDidAppear:(BOOL)animated {
    //TODO add animated parameter to hideinfo view
    _infoView.frame = CGRectMake(0, -_infoView.frame.size.height, _infoView.frame.size.width, _infoView.frame.size.height);
    _infoView.hidden = YES;

}

- (void)showInfoView {
    infoViewIsShowing = true;
    
    //FIXME actions in pan gesture (adding draggingView to view and moving it) causes relayout and this causes hidden infoView to be again at 0,0
    //so when we select an item after pan, infoView will reappear without animation
    //might be related with autolayout - pin to top was already removed, no effect
    //this this hack we ensure it has the correct "hidden" top margin before showing
    _infoView.frame = CGRectMake(0, -_infoView.frame.size.height, _infoView.frame.size.width, _infoView.frame.size.height);

    
    [UIView animateWithDuration:.4 animations:^{
        _infoView.hidden = NO;
        _infoView.frame = CGRectMake(0, 0, _infoView.frame.size.width, _infoView.frame.size.height);
    } completion:^(BOOL finished) {
    }];
}


- (void)hideInfoView {
    infoViewIsShowing = false;
    
    [UIView animateWithDuration:.4 animations:^{
        _infoView.frame = CGRectMake(0, -_infoView.frame.size.height, _infoView.frame.size.width, _infoView.frame.size.height);
    } completion:^(BOOL finished) {
        _infoView.hidden = YES;
    }];
}

- (void)showInInfoView:(Item *)item itemView:(UIView *)itemView {
    _infoTitle.text = item.name;
    _infoText.text = item.description;
    
    UIView *itemViewCopy = [self copyView:itemView];
    [itemViewCopy.layer setCornerRadius:buttonRadius];
    [itemViewCopy.layer setBorderWidth:0.2];
    [itemViewCopy.layer setBorderColor:[[UIColor lightGrayColor] CGColor]];
    itemViewCopy.frame = CGRectMake(0.0, 0.0, itemViewCopy.frame.size.width, itemViewCopy.frame.size.height);
    [_infoImage addSubview:itemViewCopy];
    
    _infoView.tag = itemView.tag; //remember to which item belongs the infoview. TODO don't use tags for this
    
    [self showInfoView];
}

- (void)handleTap:(UITapGestureRecognizer *)sender {
    
    Item *item = items[sender.view.tag];
    
    if (!infoViewIsShowing) {
        [self showInInfoView:item itemView:sender.view];
        
    } else {
        
        if (sender.view.tag == _infoView.tag) { //hide ony if we tap the item for which infoView is showing
            [self hideInfoView];
            
        } else { //tap a different item, update infoView with this one
            
            [self showInInfoView:item itemView:sender.view];
        }
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)sender {

    CGPoint location = [sender locationInView:sender.view.superview.superview]; //location in view controller's root view
    
    if (sender.state == UIGestureRecognizerStateBegan) {
        
        if (!draggingItemsViewBlocked) {
            draggingItemsViewBlocked = true;
            draggingItemsViewBeganProcessed = true;
            
            //this doesn't work correctly - same reason as FIXME in showInfoView
            //[self hideInfoView];
            
            itemStartPanPoint = [self.view convertPoint:sender.view.center fromView:_itemsView];
            
            draggingView = [self copyView:sender.view];
            draggingView.tag = sender.view.tag;
            [draggingView.layer setCornerRadius:buttonRadius];
            
            [self.view addSubview:draggingView];
            
            draggingView.center = location;
        }
        
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        
        if (draggingItemsViewBlocked && draggingItemsViewBeganProcessed) {
            
            draggingItemsViewBeganProcessed = false;
            
            if (CGRectContainsPoint(_scrollView.frame, location)) {
                [draggingView removeFromSuperview];
                [_scrollView addSubview: draggingView];
                
                UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
                [draggingView addGestureRecognizer:tapRecognizer];
                
                
                UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanPlacedItem:)];
                panRecognizer.minimumNumberOfTouches = 1;
                panRecognizer.maximumNumberOfTouches = 1;
                [draggingView addGestureRecognizer:panRecognizer];
                
                draggingItemsViewBlocked = false;
                draggingView = NULL;
                
            } else {
                [self snapView:draggingView toPoint:itemStartPanPoint];
            }
        }
        
    } else if (sender.state != UIGestureRecognizerStateFailed) {
        
        if (draggingItemsViewBeganProcessed) {
            draggingView.center = location;
        }
    }
}


- (void)setDeleteViewVisible:(BOOL)visible {
    if (visible) {
        [UIView animateWithDuration:.4 animations:^{
            _deleteView.alpha = 1;
        }];
    } else {
        [UIView animateWithDuration:.4 animations:^{
            _deleteView.alpha = 0;
        }];
    }
}


- (void)handlePanPlacedItem:(UIPanGestureRecognizer *)sender {
    
    CGPoint location = [sender locationInView:self.view]; //location in view controller's root view

    if (sender.state == UIGestureRecognizerStateBegan) {
        
        [self.view addSubview:sender.view];

        placedStartPanPoint = location;
    
    } else if (sender.state == UIGestureRecognizerStateEnded) {
        if (CGRectContainsPoint(_scrollView.frame, location)) {
            [sender.view removeFromSuperview];
            [_scrollView addSubview:sender.view];
        } else if (CGRectContainsPoint(_itemsView.frame, location)) {
            [sender.view removeFromSuperview];
            [self setDeleteViewVisible:false];

        } else {
            [self snapView:sender.view toPoint:placedStartPanPoint];
        }
    
    } else if (sender.state != UIGestureRecognizerStateFailed) {
        sender.view.center = location;
        
        BOOL wasInItemsViewLastTime = CGRectContainsPoint(_itemsView.frame, lastPlacedLocation);
        
        if (!wasInItemsViewLastTime && CGRectContainsPoint(_itemsView.frame, location)) { //moved from outside to items view
            [self setDeleteViewVisible:true];
            
        } else if (wasInItemsViewLastTime && !CGRectContainsPoint(_itemsView.frame, location)) { //moved from items view to outside
            [self setDeleteViewVisible:false];
            
        }
    }
    
    lastPlacedLocation = location;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [items count];
}


- (IBAction) imageMoved:(id) sender withEvent:(UIEvent *) event {
    CGPoint point = [[[event allTouches] anyObject] locationInView:self.view];
    UIControl *control = sender;
    control.center = point;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    ItemCell *cell = (ItemCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    
    Item *item = (Item *)[items objectAtIndex:indexPath.row];
    
    cell.label.text = item.letter;
    cell.backgroundColor = item.bgColor;
    cell.tag = indexPath.row; //to get the item, in gesture recognizer
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    [cell addGestureRecognizer:tapRecognizer];
    
    
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panRecognizer.minimumNumberOfTouches = 1;
    panRecognizer.maximumNumberOfTouches = 1;
    [cell addGestureRecognizer:panRecognizer];

    [cell.layer setCornerRadius:buttonRadius];
    
    return cell;
}

//TODO extension of view?
- (UIView *)copyView:(UIView *)view {
    NSData *tempArchive = [NSKeyedArchiver archivedDataWithRootObject:view];
    return [NSKeyedUnarchiver unarchiveObjectWithData:tempArchive];
}

@end
