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
- (void) requestProfileImageWithIdentifier:(NSString*)identifier block:(profileimagestore_block_t)block accountStore:(ACAccountStore*)accountStore;

// Profile Image Management by CoreData base.
- (void) requestProfileImageWithIdentifier:(NSString*)identifier block:(profileimagestore_block_t)block managedObjectContext:(NSManagedObjectContext*)managedObjectContext accountStore:(ACAccountStore*)accountStore;
+ (void) sweepProfileImageWithTimeInterval:(NSTimeInterval)timeInterval managedObjectContext:(NSManagedObjectContext*)managedObjectContext;


@end
