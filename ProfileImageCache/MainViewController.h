//
//  MainViewController.h
//  ProfileImageCache
//
//  Created by Noto Kaname on 12/06/13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "FlipsideViewController.h"

#import <CoreData/CoreData.h>

@interface MainViewController : UIViewController <FlipsideViewControllerDelegate,UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end
