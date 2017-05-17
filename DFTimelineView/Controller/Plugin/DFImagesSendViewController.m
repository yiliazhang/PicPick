//
//  DFImagesSendViewController.m
//  DFTimelineView
//
//  Created by Allen Zhong on 16/2/15.
//  Copyright © 2016年 Datafans, Inc. All rights reserved.
//

#import "DFImagesSendViewController.h"
#import "DFPlainGridImageView.h"
#import "MJPhotoBrowser.h"
#import "MJPhoto.h"

#import "MMPopupItem.h"
#import "MMSheetView.h"
#import "MMPopupWindow.h"
#import <SVProgressHUD.h>
#import <AFNetworking.h>
#import "TZImagePickerController.h"
#import <UIView+Toast.h>
#import <Photos/Photos.h>

#define ImageGridWidth [UIScreen mainScreen].bounds.size.width
typedef void(^Result)(NSData *fileData, NSString *fileName);
typedef void(^ResultPath)(NSString *filePath, NSString *fileName);
@interface DFImagesSendViewController()<DFPlainGridImageViewDelegate,TZImagePickerControllerDelegate, UIImagePickerControllerDelegate,UINavigationControllerDelegate, UITextViewDelegate>

@property (nonatomic, strong) NSMutableArray *images;

@property (nonatomic, strong) UITextView *contentView;

@property (nonatomic, strong) UIView *mask;

@property (nonatomic, strong) UILabel *placeholder;

@property (nonatomic, strong) DFPlainGridImageView *gridView;

@property (nonatomic, strong) UIImagePickerController *pickerController;

@property (strong, nonatomic) UIPanGestureRecognizer *panGestureRecognizer;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
///
@property (strong, nonatomic, nonnull) NSMutableArray *items;
@property (assign, nonatomic) BOOL isVideo;

@end

@implementation DFImagesSendViewController

- (instancetype)initWithImages:(NSArray *) images
{
    self = [super init];
    if (self) {
        _images = [NSMutableArray array];
//        if (images != nil) {
            [_images addObjectsFromArray:images];
            [_images addObject:[UIImage imageNamed:@"AlbumAddBtn"]];
//        }
    }
    return self;
}

- (void)dealloc
{
    
    [_mask removeGestureRecognizer:_panGestureRecognizer];
    [_mask removeGestureRecognizer:_tapGestureRecognizer];
}


-(void)viewDidLoad
{
    [super viewDidLoad];
    [self initView];
}

-(void) initView
{
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    CGFloat x, y, width, heigh;
    x=10;
    y=74;
    width = self.view.frame.size.width -2*x;
    heigh = 100;
    _contentView = [[UITextView alloc] initWithFrame:CGRectMake(x, y, width, heigh)];
    _contentView.scrollEnabled = YES;
    _contentView.delegate = self;
    _contentView.font = [UIFont systemFontOfSize:17];
    //_contentView.layer.borderColor = [UIColor redColor].CGColor;
    //_contentView.layer.borderWidth =2;
    [self.view addSubview:_contentView];
    
    //placeholder
    _placeholder = [[UILabel alloc] initWithFrame:CGRectMake(x+5, y+5, 150, 25)];
    _placeholder.text = @"这一刻的想法...";
    _placeholder.font = [UIFont systemFontOfSize:14];
    _placeholder.textColor = [UIColor lightGrayColor];
    _placeholder.enabled = NO;
    [self.view addSubview:_placeholder];
    
    
    _gridView = [[DFPlainGridImageView alloc] initWithFrame:CGRectZero];
    _gridView.delegate = self;
    [self.view addSubview:_gridView];
    
    
    _mask = [[UIView alloc] initWithFrame:self.view.bounds];
    _mask.backgroundColor = [UIColor clearColor];
    _mask.hidden = YES;
    [self.view addSubview:_mask];
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onPanAndTap:)];
    [_mask addGestureRecognizer:_panGestureRecognizer];
    _panGestureRecognizer.maximumNumberOfTouches = 1;
    
    _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPanAndTap:)];
    [_mask addGestureRecognizer:_tapGestureRecognizer];
    
    [self refreshGridImageView];
}

-(void) refreshGridImageView
{
    CGFloat x, y, width, heigh;
    x=10;
    y = CGRectGetMaxY(_contentView.frame)+10;
    width  = ImageGridWidth;
    heigh = [DFPlainGridImageView getHeight:_images maxWidth:width];
    _gridView.frame = CGRectMake(x, y, width, heigh);
    [_gridView updateWithImages:_images];
}

-(UIBarButtonItem *)leftBarButtonItem
{
    return [UIBarButtonItem text:@"取消" selector:@selector(cancel) target:self];
}

-(UIBarButtonItem *)rightBarButtonItem
{
    return [UIBarButtonItem text:@"发送" selector:@selector(send) target:self];
}

-(void) cancel
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) send
{
    if (_delegate && [_delegate respondsToSelector:@selector(onSendTextImage:images:)]) {
        
        [_images removeLastObject];
        [_delegate onSendTextImage:_contentView.text images:_images];
    }
    if ([_contentView.text isEqualToString:@""]) {
        [self.view makeToast:@"说点什么吧~"];
        return;
    }
    
    [self startSendAssets:self.items message:_contentView.text isVideo:self.isVideo];
    [self dismissViewControllerAnimated:YES completion:nil];
    
}
- (void)startSendAssets:(NSMutableArray *)assets message:(NSString *)message isVideo:(BOOL)isVideo {
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    
    manager.requestSerializer = [AFHTTPRequestSerializer new];
    [manager.requestSerializer setQueryStringSerializationWithBlock:^NSString * _Nonnull(NSURLRequest * _Nonnull request, __kindof NSString *parameters, NSError * _Nullable __autoreleasing * _Nullable error) {
        return [NSString stringWithFormat:@"ak=xxx&sn=xxx&form=%@",parameters];
    }];
    
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
    [manager.responseSerializer setAcceptableContentTypes:[NSSet setWithObjects:@"application/x-www-form-urlencoded", @"application/json",@"encoding=utf-8",  @"text/html", nil]];
    manager.requestSerializer.timeoutInterval = 30.f;
    
    
    
    NSString *fileType = isVideo ? @"video" : @"image";
    
    NSDictionary *params = @{@"filetype": fileType,
                             @"teacherid":@33,
                               @"classid":@11,
                                 @"content":message
                             };
    
    [SVProgressHUD showProgress:0 status:@"0%"];
    
    [manager POST:@"http://101.200.228.98:8080/kindergarten/app/class/dynamic/add"
 parameters:params constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
     if (assets.count > 0) {
         if (_isVideo) {
             [DFImagesSendViewController getVideoPathFromPHAsset:assets[0] Complete:^(NSString *filePath, NSString *fileName) {
                 NSURL *url = [NSURL fileURLWithPath:filePath];
                 [formData appendPartWithFileURL:url name:@"file" error:nil];
             }];
         } else {
             for (int i = 0; i < assets.count; i++) {
                 [DFImagesSendViewController getImageFromPHAsset:assets[i] Complete:^(NSData *fileData, NSString *fileName) {
                     [formData appendPartWithFormData:fileData name:[NSString stringWithFormat:@"file%d",i]];
                 }];
             }
         }
     }
 } progress:^(NSProgress * _Nonnull uploadProgress) {
     [SVProgressHUD showProgress:uploadProgress.fractionCompleted status:uploadProgress.localizedDescription];
 } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
     [SVProgressHUD showSuccessWithStatus:@"上传成功"];
     [self dismissViewControllerAnimated:YES completion:nil];
 } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
     [SVProgressHUD showInfoWithStatus:@"上传失败"];
 }];
    
    
//    [manager POST:@"http://101.200.228.98:8080/kindergarten/app/class/dynamic/add" parameters:params progress:^(NSProgress * _Nonnull uploadProgress) {
//        [SVProgressHUD showProgress:uploadProgress.fractionCompleted status:uploadProgress.localizedDescription];
//    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
//        [SVProgressHUD showSuccessWithStatus:@"上传成功"];
//        [self dismissViewControllerAnimated:YES completion:nil];
//
//    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
//        [SVProgressHUD showInfoWithStatus:@"上传失败"];
//    }];
}
+ (void)getImageFromPHAsset:(PHAsset *)asset Complete:(Result)result {
    __block NSData *data;
    PHAssetResource *resource = [[PHAssetResource assetResourcesForAsset:asset] firstObject];
    if (asset.mediaType == PHAssetMediaTypeImage) {
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.synchronous = YES;
        [[PHImageManager defaultManager] requestImageDataForAsset:asset
                                                          options:options
                                                    resultHandler:
         ^(NSData *imageData,
           NSString *dataUTI,
           UIImageOrientation orientation,
           NSDictionary *info) {
             data = [NSData dataWithData:imageData];
         }];
    }
    
    if (result) {
        if (data.length <= 0) {
            result(nil, nil);
        } else {
            result(data, resource.originalFilename);
        }
    }
}

+ (void)getVideoPathFromPHAsset:(PHAsset *)asset Complete:(ResultPath)result {
    NSArray *assetResources = [PHAssetResource assetResourcesForAsset:asset];
    PHAssetResource *resource;
    
    for (PHAssetResource *assetRes in assetResources) {
        if (assetRes.type == PHAssetResourceTypePairedVideo ||
            assetRes.type == PHAssetResourceTypeVideo) {
            resource = assetRes;
        }
    }
    NSString *fileName = @"tempAssetVideo.mov";
    if (resource.originalFilename) {
        fileName = resource.originalFilename;
    }
    
    if (asset.mediaType == PHAssetMediaTypeVideo || asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) {
        PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
        options.version = PHImageRequestOptionsVersionCurrent;
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        NSString *PATH_MOVIE_FILE = [NSTemporaryDirectory() stringByAppendingPathComponent:fileName];
        [[NSFileManager defaultManager] removeItemAtPath:PATH_MOVIE_FILE error:nil];
        [[PHAssetResourceManager defaultManager] writeDataForAssetResource:resource
                                                                    toFile:[NSURL fileURLWithPath:PATH_MOVIE_FILE]
                                                                   options:nil
                                                         completionHandler:^(NSError * _Nullable error) {
                                                             if (error) {
                                                                 result(nil, nil);
                                                             } else {
                                                                 result(PATH_MOVIE_FILE, fileName);
                                                             }
                                                         }];
    } else {
        result(nil, nil);
    }
}

-(void) onPanAndTap:(UIGestureRecognizer *) gesture
{
    _mask.hidden = YES;
    [_contentView resignFirstResponder];
}



#pragma mark - UITextViewDelegate

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (![text isEqualToString:@""])
    {
        _placeholder.hidden = YES;
    }else if ([text isEqualToString:@""] && range.location == 0 && range.length == 1)
    {
        _placeholder.hidden = NO;
        
    }
//    if ([text isEqualToString:@"\n"]){
//        _mask.hidden = YES;
//        [_contentView resignFirstResponder];
//        if (range.location == 0)
//        {
//            _placeholder.hidden = NO;
//        }
//        return NO;
//    }
    
    return YES;
}

-(void)textViewDidBeginEditing:(UITextView *)textView
{
    _mask.hidden = NO;
}

-(void)textViewDidEndEditing:(UITextView *)textView
{
    _mask.hidden = YES;
}

#pragma mark - DFPlainGridImageViewDelegate

-(void)onClick:(NSUInteger)index
{
    
    if (_images.count <= 9 && index == _images.count-1) {
        [self chooseImage];
    }else{
        MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
        
        NSMutableArray *photos = [NSMutableArray array];
        NSUInteger count;
        if (_images.count > 9)  {
            count = 9;
        }else{
            count = _images.count - 1;
        }
        for (int i=0; i<count; i++) {
            MJPhoto *photo = [[MJPhoto alloc] init];
            photo.image = [_images objectAtIndex:i];
            [photos addObject:photo];
        }
        browser.photos = photos;
        browser.currentPhotoIndex = index;
        
        [browser show];
        
    }
}


-(void)onLongPress:(NSUInteger)index
{
    
    if (_images.count <9 && index == _images.count-1) {
        return;
    }
    
    MMPopupItemHandler block = ^(NSInteger i){
        switch (i) {
            case 0:
                [_images removeObjectAtIndex:index];
                [self refreshGridImageView];
                break;
            default:
                break;
        }
    };
    
    NSArray *items = @[MMItemMake(@"删除", MMItemTypeNormal, block)];
    
    MMSheetView *sheetView = [[MMSheetView alloc] initWithTitle:@"" items:items];
    [sheetView show];
    
}

-(void) chooseImage
{
    MMPopupItemHandler block = ^(NSInteger index){
        switch (index) {
            case 0:
                [self pickVideoFromAlbum];
                break;
            case 1:
                [self pickPictureFromAlbum];
                break;
            default:
                break;
        }
    };
    
    NSArray *items = @[MMItemMake(@"视频", MMItemTypeNormal, block),
                       MMItemMake(@"相片", MMItemTypeNormal, block)];
    
    MMSheetView *sheetView = [[MMSheetView alloc] initWithTitle:@"" items:items];
    
    [sheetView show];
    
    
}


-(void) takePhoto
{
    _pickerController = [[UIImagePickerController alloc] init];
    _pickerController.delegate = self;
    _pickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
    [self presentViewController:_pickerController animated:YES completion:nil];
}

-(void) pickPictureFromAlbum
{
    self.isVideo = NO;
    [self.items removeAllObjects];
    if (self.images.count > 1) {
        [self.images removeObjectsInRange:NSMakeRange(0, self.images.count - 1)];
    }
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:(10-_images.count) delegate:self];
    imagePickerVc.allowPickingVideo = NO;
    imagePickerVc.allowPreview = NO;
    imagePickerVc.didFinishPickingPhotosHandle = ^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        [_pickerController dismissViewControllerAnimated:YES completion:nil];
        for (UIImage *image in photos) {
            [_images insertObject:image atIndex:(_images.count-1)];
        }
        [_items addObjectsFromArray:assets];
        [self refreshGridImageView];
    };
    
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}

-(void) pickVideoFromAlbum
{
    self.isVideo = YES;
    [self.items removeAllObjects];
    if (self.images.count > 1) {
        [self.images removeObjectsInRange:NSMakeRange(0, self.images.count - 1)];
    }
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:(10-_images.count) delegate:self];
    imagePickerVc.allowPickingImage = NO;
    imagePickerVc.allowPickingVideo = YES;
    imagePickerVc.allowPreview = NO;
    imagePickerVc.didFinishPickingVideoHandle = ^(UIImage *coverImage, id asset) {
        [_pickerController dismissViewControllerAnimated:YES completion:nil];
        [_images insertObject:coverImage atIndex:(_images.count-1)];
        [_items addObject:asset];
        [self refreshGridImageView];
    };
    
    [self presentViewController:imagePickerVc animated:YES completion:nil];
}
#pragma mark - TZImagePickerControllerDelegate
//- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
//    NSLog(@"%@", photos);
//    
//    for (UIImage *image in photos) {
//        [_images insertObject:image atIndex:(_images.count-1)];
//        
//        [_items addObject:image];
//    }
//    
//    [self refreshGridImageView];
//}
//
//- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos {
//    
//}

#pragma mark - UIImagePickerControllerDelegate

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [_pickerController dismissViewControllerAnimated:YES completion:nil];
    
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [_images insertObject:image atIndex:(_images.count-1)];
    
    [self refreshGridImageView];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [_pickerController dismissViewControllerAnimated:YES completion:nil];
}
- (NSMutableArray *)items {
    if (!_items) {
        _items = [[NSMutableArray alloc] initWithCapacity:10];
    }
    return _items;
}
- (BOOL )isVideo {
    if (!_isVideo) {
        _isVideo = NO;
    }
    return _isVideo;
}
@end
