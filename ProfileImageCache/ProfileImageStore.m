//
//  ProfileImageStore.m
//  ProfileImageCache
//
//  Created by Noto Kaname on 12/06/22.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ProfileImageStore.h"


@implementation ProfileImageStore
@synthesize updateInterval=_updateInterval;
@synthesize reachableNetwork=_reachableNetwork;

- (id)init
{
    if( (self = [super init]) != nil ){
        _updateInterval = 30.0f * 60.0f;
        _reachableNetwork = YES;
    }
    return self;
}

- (void) requestProfileImageWithAccount:(ACAccount*)account block:(profileimagestore_block_t)block
{
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSString *tempDir = NSTemporaryDirectory();
        NSString *abstProfileImagePath = [tempDir stringByAppendingPathComponent:[NSString stringWithFormat:@"profile_%@.png",account.username] ];
        
        NSFileManager* fileManager = [[NSFileManager alloc] init];
        
        if( [fileManager fileExistsAtPath:abstProfileImagePath] ){
            NSData* data = [NSData dataWithContentsOfFile:abstProfileImagePath];
            UIImage* imageProfileImage = [UIImage imageWithData:data];
            dispatch_async(dispatch_get_main_queue(), ^{
                block(imageProfileImage,ProfileImageUpdateStateExistImage);
            });
        }
        
        BOOL mustLoadImage = YES;
        if( [fileManager fileExistsAtPath:abstProfileImagePath] ){
            NSError* error = nil;
            NSDictionary* dicFileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:abstProfileImagePath error:&error];
            
            NSTimeInterval timeInterval = [dicFileAttributes.fileModificationDate timeIntervalSinceNow];
            if( timeInterval < - _updateInterval ){
                mustLoadImage = YES;
            }
        }else{
            mustLoadImage = YES;
        }
        
        
        if( mustLoadImage )
        {
            NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/users/show.json?screen_name=%@",account.username] ];
            SLRequest* request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:URL
                parameters:@{
                }
            ];
            request.account = account;

            // リクエストの呼び出し
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                if( error == nil )
                {
                    NSError* error = nil;
                    NSObject* obj = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                    NSDictionary* root = [obj isKindOfClass:[NSDictionary class]] ? (NSDictionary*)obj : nil;
                    
                    NSString* imagePath = root[@"profile_image_url"];
                    imagePath = [imagePath stringByReplacingOccurrencesOfString:@"_normal.png" withString:@"_bigger.png"];
                    imagePath = [imagePath stringByReplacingOccurrencesOfString:@"_normal.png" withString:@"_bigger.jpg"];
                    imagePath = [imagePath stringByReplacingOccurrencesOfString:@"_normal.png" withString:@"_bigger.jpeg"];
                    
                    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:imagePath]];
                    @autoreleasepool {
                        NSError* error = nil;
                        NSURLResponse* response = nil;

                        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                        if( data != nil ){
                            // 標準サイズを作成する
                            UIImage* imageProfileImage = [UIImage imageWithData:data];

                            if( [UIScreen mainScreen].scale == 1.0f ){
                                CGColorSpaceRef  imageColorSpace = CGColorSpaceCreateDeviceRGB();

                                CGAffineTransform transform = CGAffineTransformIdentity;

                                const double width = CGImageGetWidth([imageProfileImage CGImage]);
                                const double height = CGImageGetHeight([imageProfileImage CGImage]);
                                CGRect bounds = CGRectMake(0, 0, ceil(width *.5f), ceil(height *.5f) );
                                CGContextRef context = CGBitmapContextCreate (NULL,bounds.size.width,bounds.size.height,8, bounds.size.width * 4, imageColorSpace, kCGImageAlphaPremultipliedFirst );
                                transform = CGAffineTransformScale(transform, .5f, .5f);

                                CGContextConcatCTM(context, transform);
                                CGContextDrawImage(context, CGRectMake(0, 0, width, height), [imageProfileImage CGImage] );
                                CGImageRef cgImage = CGBitmapContextCreateImage(context);

                                UIImage* imageNormalScale = [UIImage imageWithCGImage:cgImage];
                                NSData* dataNormalScale = UIImagePNGRepresentation(imageNormalScale);

                                if( [fileManager fileExistsAtPath:abstProfileImagePath] ){
                                    NSError* error = nil;
                                    [fileManager removeItemAtPath:abstProfileImagePath error:&error];
                                }
                                CGImageRelease(cgImage);
                                CGContextRelease(context);
                                CGColorSpaceRelease(imageColorSpace);

                                dispatch_async(dispatch_get_main_queue(), ^{
                                    block(imageNormalScale,ProfileImageUpdateStateNewImage);
                                });

                                [dataNormalScale writeToFile:abstProfileImagePath atomically:YES];
                            }else{
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    block(imageProfileImage,ProfileImageUpdateStateNewImage);
                                });
                                
                                if( [fileManager fileExistsAtPath:abstProfileImagePath] ){
                                    NSError* error = nil;
                                    [fileManager removeItemAtPath:abstProfileImagePath error:&error];
                                }
                                [data writeToFile:abstProfileImagePath atomically:YES];
                            }
                        }else{
                            NSLog(@"ここでタイムアウト処理を行う");
                        }
                    }
                    
                }else{
                    NSLog(@"error %@, %@", error, [error userInfo]);
                }
            }];
        }
    });
}

+ (void) sweepProfileImageWithTimeInterval:(NSTimeInterval)timeInterval managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    // ここでProfileImage の問い合わせ
    // 表示情報を取得する
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ProfileImage" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // 検索条件を指定
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"timeStamp < %@", [NSDate dateWithTimeIntervalSinceNow:-timeInterval] ];
    [fetchRequest setPredicate: predicate ];		
    
    NSError* error = nil;
    NSArray* profileImages = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
//    [fetchRequest release];
    
    for( NSManagedObject* profileImage in profileImages){
        NSString* path = [[profileImage valueForKey:@"path"] description];
        if( path != nil && [path length] > 0 ){
            NSString *tempDir = NSTemporaryDirectory();
            NSString *abstProfileImagePath = [tempDir stringByAppendingPathComponent:path ];
            if( [[NSFileManager defaultManager] fileExistsAtPath:abstProfileImagePath] ){
                NSError* error = nil;
                [[NSFileManager defaultManager] removeItemAtPath:abstProfileImagePath error:&error];
            }
        }
        [managedObjectContext deleteObject:profileImage];
    }
    
    // 保存を完了する
    if( [managedObjectContext hasChanges] ){
        NSError* error = nil;
        if( [managedObjectContext save:&error] != YES ){
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (void) requestProfileImageWithAccount:(ACAccount*)account block:(profileimagestore_block_t)block managedObjectContext:(NSManagedObjectContext*)managedObjectContext
{
    [self requestProfileImageWithAccount:account managedObjectContext:managedObjectContext block:block];
}

- (void) requestProfileImageWithAccount:(ACAccount*)account managedObjectContext:(NSManagedObjectContext*)managedObjectContext block:(profileimagestore_block_t)block 
{
    // ここでProfileImage の問い合わせ
    // 表示情報を取得する
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"ProfileImage" inManagedObjectContext:managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // 検索条件を指定
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"username = %@", account.username ];
    [fetchRequest setPredicate: predicate ];		
    
    // 最新の要素を取得する
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    NSError* error = nil;
    NSArray* profileImages = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    for( NSManagedObject* profileImage in profileImages ){
        NSLog(@"identifier=%@: timeStamp=%@", account.username,[profileImage valueForKey:@"timeStamp"] );
    }
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        NSManagedObject* profileImage = [profileImages count] > 0 ? [profileImages objectAtIndex:0] : nil;
        NSString* path = [[profileImage valueForKey:@"path"] description];
        NSDate* timeStamp = (NSDate*)([profileImage valueForKey:@"timeStamp"]);
        NSNumber* step = (NSNumber*)([profileImage valueForKey:@"step"]);
        // パスとタイムスタンプを取得する
        
        NSFileManager* fileManager = [[NSFileManager alloc] init];
        
        BOOL mustLoadImage = YES;
        if( path != nil ){
            NSString *tempDir = NSTemporaryDirectory();
            NSString *abstProfileImagePath = [tempDir stringByAppendingPathComponent:path ];
            
            if( [fileManager fileExistsAtPath:abstProfileImagePath] ){
                NSData* data = [NSData dataWithContentsOfFile:abstProfileImagePath];
                UIImage* profileImage = [UIImage imageWithData:data];
                dispatch_async(dispatch_get_main_queue(), ^{
                    block( profileImage , ProfileImageUpdateStateExistImage );
                    //                    if( /*self.navigationController.topViewController == self &&*/ currentID == cell.tag ){
                    //                        cell.imageView.image = profileImage;
                    //                    }
                });
                
                NSTimeInterval timeInterval = [timeStamp timeIntervalSinceNow];
                mustLoadImage = (timeStamp != nil && timeInterval < - _updateInterval ) ? YES :NO;
            }else{
                mustLoadImage = YES;
            }
        }
        
        if( mustLoadImage && _reachableNetwork )
        {
            NSInteger currentStep = [step intValue];
            currentStep++;
            
            NSURL* URL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1.1/users/show.json?screen_name=%@",account.username] ];
            SLRequest* request = [SLRequest requestForServiceType:SLServiceTypeTwitter requestMethod:SLRequestMethodGET URL:URL
                                                       parameters:@{
                                  }
                                  ];
            request.account = account;
            
            // リクエストの呼び出し
            [request performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                if( error == nil )
                {
                    // パスを新規作成
                    NSString *tempDir = NSTemporaryDirectory();
                    
                    NSString*profileImagePath = [NSString stringWithFormat:@"profile_%@(%d).png",account.username,currentStep];
                    NSString* abstProfileImagePath = [tempDir stringByAppendingPathComponent:profileImagePath ];

                    NSError* error = nil;
                    NSObject* obj = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&error];
                    NSDictionary* root = [obj isKindOfClass:[NSDictionary class]] ? (NSDictionary*)obj : nil;
                    
                    NSString* imagePath = root[@"profile_image_url"];
                    imagePath = [imagePath stringByReplacingOccurrencesOfString:@"_normal.png" withString:@"_bigger.png"];
                    imagePath = [imagePath stringByReplacingOccurrencesOfString:@"_normal.png" withString:@"_bigger.jpg"];
                    imagePath = [imagePath stringByReplacingOccurrencesOfString:@"_normal.png" withString:@"_bigger.jpeg"];
                    
                    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:imagePath]];

                    @autoreleasepool {
                        NSError* error = nil;
                        NSURLResponse* response = nil;
                        
                        NSData* data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
                        if( data != nil ){
                            // 標準サイズを作成する
                            UIImage* imageProfileImage = [UIImage imageWithData:data];            
                            
                            if( [UIScreen mainScreen].scale == 1.0f ){
                                
                                CGColorSpaceRef  imageColorSpace = CGColorSpaceCreateDeviceRGB();
                                
                                CGAffineTransform transform = CGAffineTransformIdentity;
                                
                                const double width = CGImageGetWidth([imageProfileImage CGImage]);
                                const double height = CGImageGetHeight([imageProfileImage CGImage]);
                                CGRect bounds = CGRectMake(0, 0, ceil(width *.5f), ceil(height *.5f) );
                                CGContextRef context = CGBitmapContextCreate (NULL,bounds.size.width,bounds.size.height,8, bounds.size.width * 4, imageColorSpace, kCGImageAlphaPremultipliedFirst );
                                transform = CGAffineTransformScale(transform, .5f, .5f);
                                
                                CGContextConcatCTM(context, transform);
                                CGContextDrawImage(context, CGRectMake(0, 0, width, height), [imageProfileImage CGImage] );
                                CGImageRef cgImage = CGBitmapContextCreateImage(context);
                                
                                UIImage* imageNormalScale = [UIImage imageWithCGImage:cgImage];
                                NSData* dataNormalScale = UIImagePNGRepresentation(imageNormalScale);
                                
                                CGImageRelease(cgImage);
                                CGContextRelease(context);
                                CGColorSpaceRelease(imageColorSpace);
                                
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    block( imageNormalScale , ProfileImageUpdateStateNewImage );
                                });
                                
                                [dataNormalScale writeToFile:abstProfileImagePath atomically:YES];
                            }else{
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    block( imageProfileImage , ProfileImageUpdateStateNewImage );
                                });
                                
                                [data writeToFile:abstProfileImagePath atomically:YES];
                            }
                            
                            dispatch_async(dispatch_get_main_queue(), ^{
                                // 値を追加
                                NSManagedObject* updateTarget = [NSEntityDescription insertNewObjectForEntityForName:@"ProfileImage" inManagedObjectContext:managedObjectContext];
                                [updateTarget setValue:account.username forKey:@"username"];
                                [updateTarget setValue:[NSNumber numberWithInt:currentStep] forKey:@"step"];
                                [updateTarget setValue:[NSDate date] forKey:@"timeStamp"];
                                [updateTarget setValue:profileImagePath forKey:@"path"];
                                
                                if( [managedObjectContext hasChanges] ){
                                    NSError* error = nil;
                                    if( [managedObjectContext save:&error] != YES ){
                                        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                                        abort();
                                    }
                                }
                                
                            });
                        }else{
                            NSLog(@"ここにタイムアウト処理");
                        }
                    }
                }else{
                    NSLog(@"error %@, %@", error, [error userInfo]);
                }
            }];
            
        }
    });
    
}


@end
