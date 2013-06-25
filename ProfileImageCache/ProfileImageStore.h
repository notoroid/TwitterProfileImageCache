//
//  ProfileImageStore.h
//  ProfileImageCache
//
//  Created by Noto Kaname on 12/06/22.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,ProfileImageUpdateState)
{
    ProfileImageUpdateStateFailure
    ,ProfileImageUpdateStateExistImage
    ,ProfileImageUpdateStateNewImage
};

@class ACAccount;

typedef void (^profileimagestore_block_t)(UIImage* profileImage,ProfileImageUpdateState profileImageUpdateState);

@interface ProfileImageStore : NSObject
@property (nonatomic) NSTimeInterval updateInterval;
@property (nonatomic) BOOL reachableNetwork;

// Profile Image Management by File base.
- (void) requestProfileImageWithAccount:(ACAccount*)account block:(profileimagestore_block_t)block;

// Profile Image Management by CoreData base.
- (void) requestProfileImageWithAccount:(ACAccount*)account managedObjectContext:(NSManagedObjectContext*)managedObjectContext block:(profileimagestore_block_t)block;
+ (void) sweepProfileImageWithTimeInterval:(NSTimeInterval)timeInterval managedObjectContext:(NSManagedObjectContext*)managedObjectContext;

// deprecated methods 

- (void) requestProfileImageWithAccount:(ACAccount*)account block:(profileimagestore_block_t)block managedObjectContext:(NSManagedObjectContext*)managedObjectContext __attribute__((deprecated));

@end
