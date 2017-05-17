//
//  UIViewController+YILBack.m
//  YILUtilKit
//
//  Created by apple on 16/8/12.
//  Copyright © 2016年 Datang. All rights reserved.
//

#import "UIViewController+YILBack.h"
#import <objc/objc.h>
#import <objc/runtime.h>
//#import "YILDefinitionHeader.h"

@implementation UIViewController (YILBack)
+(void)load{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        Class class = [self class];
//        swizzleBackMethod(class, @selector(viewDidLoad), @selector(app_viewDidLoad));
    });
}

void swizzleBackMethod(Class class,SEL originalSelector,SEL swizzledSelector){
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }else{
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (void)app_viewDidLoad {
    [self app_viewDidLoad];
    [self setAppearance];
}

- (void)setAppearance {
    UIImage *backButtonBackgroundImage = [UIImage imageNamed:@"back"];
    backButtonBackgroundImage = [backButtonBackgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(0, backButtonBackgroundImage.size.width - 1, 0, 0)];
    id appearance = [UIBarButtonItem appearanceWhenContainedIn:[UINavigationController class], nil];
    [appearance setBackButtonBackgroundImage:backButtonBackgroundImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//    [appearance setTitleTextAttributes:@{NSFontAttributeName: [UIFont systemFontOfSize: 16]}];
    UIBarButtonItem *backBarButton = [[UIBarButtonItem alloc] initWithTitle:self.title style:UIBarButtonItemStylePlain target:nil action:NULL];
    self.navigationItem.backBarButtonItem = backBarButton;
}

@end
