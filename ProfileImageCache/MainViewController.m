//
//  MainViewController.m
//  ProfileImageCache
//
//  Created by Noto Kaname on 12/06/13.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "MainViewController.h"
#import "AppDelegate.h"
#import "ProfileImageStore.h"

static NSInteger s_accountCellID = 0;

@interface MainViewController ()
{
    NSMutableArray* _identifiers;
}
@property (weak, nonatomic) IBOutlet UITableView *tableView;
- (void) getTwitterAccounts;
@end

@implementation MainViewController
@synthesize tableView = _tableView;

@synthesize managedObjectContext = _managedObjectContext;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self getTwitterAccounts];
}

- (void)viewDidUnload
{
    [self setTableView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

#pragma mark - Flipside View

- (void)flipsideViewControllerDidFinish:(FlipsideViewController *)controller
{
    [self dismissModalViewControllerAnimated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showAlternate"]) {
        [[segue destinationViewController] setDelegate:self];
    }
}

- (void) getTwitterAccounts {
    AppDelegate* appDelegate = (AppDelegate*)([UIApplication sharedApplication].delegate);
    
	// Create an account store object.
	ACAccountStore *accountStore = appDelegate.accountStore;
	
	// Create an account type that ensures Twitter accounts are retrieved.
	ACAccountType *accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
	
    _identifiers = [NSMutableArray array];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(queue, ^{
        // Request access from the user to use their Twitter accounts.
        [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
            if(granted) {
                // Get the list of Twitter accounts.
                __weak NSArray* accountsArray = [accountStore accountsWithAccountType:accountType];
                
                for (ACAccount* account in accountsArray ) {
                    NSMutableDictionary* dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                                [account.identifier copy],@"identifier"
                                                ,[account.username copy],@"username"
                                                ,[account.accountDescription copy],@"accountDescription"
                                                ,nil];
                    
                    NSLog(@"dic=%@",dic);
                    [_identifiers addObject:dic];
                }

                /*
                 for (NSObject* account in accountsArray ) {
                 NSLog(@"account=%@", account );
                 }
                 _userID =  ((ACAccount*)[accountsArray objectAtIndex:0]).identifier;
                 */
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.tableView reloadData];
                });
            }else {
                UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"認証が却下されました。" message:@"アプリの認証が却下されました設定画面から確認してください。" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                
                [alertView show];
            }
        }];       
    });
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_identifiers count];
}

- (void) configureCell:(UITableViewCell*)cell withIndexPath:(NSIndexPath*)indexPath
{
    NSString* twitter_username = [[_identifiers objectAtIndex:indexPath.row] objectForKey:@"username"];
    
    cell.textLabel.text = twitter_username;
    s_accountCellID+=2;
    NSInteger currentID = cell.tag = s_accountCellID;
    
    cell.imageView.image = [UIImage imageNamed:@"profileImageDummy.png"];
    
    ProfileImageStore* profileImageStore = [[ProfileImageStore alloc] init];
    profileImageStore.updateInterval = 30.0f;
    
    [profileImageStore requestProfileImageWithUsername:twitter_username block:^(UIImage *profileImage,ProfileImageUpdateState profileImageUpdateState) {
//    [profileImageStore requestProfileImageWithUsername:twitter_username block:^(UIImage *profileImage,ProfileImageUpdateState profileImageUpdateState) {
        switch (profileImageUpdateState) {
            case ProfileImageUpdateStateExistImage:
                if( /*self.navigationController.topViewController == self &&*/ currentID == cell.tag ){
                    cell.imageView.image = profileImage;
#define CELL_ID_EXIST_IMAGE_LOADED 1
                    cell.tag = cell.tag + CELL_ID_EXIST_IMAGE_LOADED;
                }
                break;
            case ProfileImageUpdateStateNewImage:
                if( /*self.navigationController.topViewController == self &&*/ currentID == cell.tag || currentID + CELL_ID_EXIST_IMAGE_LOADED == cell.tag){
                    cell.imageView.image = profileImage;
                }
                break;
            default:
                break;
        }
        
    }];
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [self configureCell:cell withIndexPath:indexPath];
    
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
