//
//  ViewController.m
//  PicPick
//
//  Created by apple on 2017/5/5.
//  Copyright © 2017年 Datang. All rights reserved.
//

#import "ViewController.h"
#import "DFImagesSendViewController.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)newActivities:(id)sender {
    DFImagesSendViewController *controller = [[DFImagesSendViewController alloc] initWithImages:nil];
//    controller.delegate = self;
    controller.title = @"添加班级动态";
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self presentViewController:navController animated:YES completion:nil];
    
}


@end
