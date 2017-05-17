//
//  DFPlainGridImageView.m
//  DFTimelineView
//
//  Created by Allen Zhong on 16/2/15.
//  Copyright © 2016年 Datafans, Inc. All rights reserved.
//

#import "DFPlainGridImageView.h"
#import <AFNetworking.h>
#import "DFImageUnitView.h"
#import "MJPhotoBrowser.h"
#import "MJPhoto.h"

#define Padding 10
static int columnPics = 4;

@interface DFPlainGridImageView()

@property (nonatomic, strong) NSMutableArray *imageViews;

@end


@implementation DFPlainGridImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _imageViews = [NSMutableArray array];
        
        [self initView];
    }
    return self;
}

-(void) initView
{
    CGFloat x, y, width, height;
    
    width = (self.frame.size.width - 5*Padding)/columnPics;
    height = width;
    
    for (int row=0; row<columnPics; row++) {
        for (int column=0; column<columnPics; column++) {
            
            x = (width+Padding)*column;
            y = (height+Padding)*row;
            DFImageUnitView *imageUnitView = [[DFImageUnitView alloc] initWithFrame:CGRectMake(x, y, width, height)];
            [self addSubview:imageUnitView];
            
            UILongPressGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPress:)];
            [imageUnitView addGestureRecognizer:longPressRecognizer];
            
            imageUnitView.hidden = YES;
            imageUnitView.imageButton.tag = row*columnPics+column;
            //imageUnitView.imageView.backgroundColor =[UIColor darkGrayColor];
            [imageUnitView.imageButton addTarget:self action:@selector(onClickImage:) forControlEvents:UIControlEventTouchUpInside];
            [_imageViews addObject:imageUnitView];
        }
    }

}

-(void)layoutSubviews
{
    CGFloat x, y, width, height;
    
    width = (self.frame.size.width - 5*Padding)/columnPics;
    height = width;
    
    for (int row=0; row<columnPics; row++) {
        for (int column=0; column<columnPics; column++) {
            
            x = (width+Padding)*column;
            y = (height+Padding)*row;
            DFImageUnitView *imageUnitView = [_imageViews objectAtIndex:(row*columnPics+column)];
            imageUnitView.frame = CGRectMake(x, y, width, height);
            imageUnitView.imageButton.frame = imageUnitView.bounds;
            imageUnitView.imageView.frame = imageUnitView.bounds;
        }
    }

}


-(void)updateWithImages:(NSMutableArray *)images
{

    for (int i=0; i< _imageViews.count; i++) {
        DFImageUnitView *imageUnitView = [_imageViews objectAtIndex:i];
        
        if (i<images.count) {
            imageUnitView.hidden = NO;
            imageUnitView.imageView.image = [images objectAtIndex:i];
        }else{
            imageUnitView.hidden = YES;
        }
    }
}


-(void) onClickImage:(UIView *) sender
{
    if (_delegate && [_delegate respondsToSelector:@selector(onClick:)]) {
        [_delegate onClick:sender.tag];
    }
}

-(void) onLongPress:(UILongPressGestureRecognizer *) recognizer
{
    if (recognizer.state == UIGestureRecognizerStateBegan){
        DFImageUnitView *view = (DFImageUnitView *)recognizer.view;
        if (_delegate && [_delegate respondsToSelector:@selector(onLongPress:)]) {
            [_delegate onLongPress:view.imageButton.tag];
        }
    }
}


+(CGFloat)getHeight:(NSMutableArray *)images maxWidth:(CGFloat)maxWidth
{
    CGFloat height= (maxWidth - 5*Padding)/columnPics;
    
    if (images == nil || images.count == 0) {
        return 0.0;
    }
    
    if (images.count <=columnPics ) {
        return height;
    }
    
    if (images.count >columnPics && images.count <=columnPics * 2 ) {
        return height*2+Padding;
    }
    
    return height*columnPics+Padding*2;
    
}

@end
