//
//  ProfileImageStore.h
//  ProfileImageCache
//
//  Created by Noto Kaname on 12/06/22.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum tagProfileImageUpdateState
{
    ProfileImageUpdateStateFailure
    ,ProfileImageUpdateStateExistImage
    ,ProfileImageUpdateStateNewImage
}ProfileImageUpdateState;

typedef void (^profileimagestore_block_t)(UIImage* profileImage,ProfileImageUpdateState profileImageUpdateState);

@interface ProfileImageStore : NSObject
@property (nonatomic) NSTimeInterval updateInterval;
@property (nonatomic) BOOL reachableNetwork;

// Profile Image Management by File base.
- (void) requestProfileImageWithUsername:(NSString*)username block:(profileimagestore_block_t)block;

// Profile Image Management by CoreData base.
- (void) requestProfileImageWithUsername:(NSString*)username block:(profileimagestore_block_t)block managedObjectContext:(NSManagedObjectContext*)managedObjectContext;
+ (void) sweepProfileImageWithTimeInterval:(NSTimeInterval)timeInterval managedObjectContext:(NSManagedObjectContext*)managedObjectContext;


@end
