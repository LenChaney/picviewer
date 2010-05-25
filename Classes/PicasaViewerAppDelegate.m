//
//  PicasaViewerAppDelegate.m
//  PicasaViewer
//
//  Created by nyaago on 10/04/21.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "PicasaViewerAppDelegate.h"
#import "RootViewController.h"


@implementation PicasaViewerAppDelegate

@synthesize window;
@synthesize navigationController;


#pragma mark -
#pragma mark Application lifecycle

- (void)applicationDidFinishLaunching:(UIApplication *)application {    
  
  // Override point for customization after app launch    
  // xibを使わない..
  window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds] ];
  
  //
  
  //
  CGRect bounds = [[UIScreen mainScreen] bounds];
  NSLog(@"window - x => %f,y => %f, width => %f, height => %f", 
        bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
  /*
  RootViewController *rootViewController = [[RootViewController alloc] 
                                            initWithNibName:@"RootViewController"
                                            bundle:nil];
   */
  RootViewController *rootViewController = [[RootViewController alloc] init];
  
  navigationController = [[UINavigationController alloc] 
                          initWithRootViewController:rootViewController];
  self.navigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
  self.navigationController.toolbar.barStyle = UIBarStyleBlack;
  self.navigationController.toolbar.translucent = YES;
  bounds =navigationController.view.frame;
  NSLog(@"navigation - x => %f,y => %f, width => %f, height => %f", 
        bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
  /* 
   // xibから読み込む場合
   RootViewController *rootViewController 
   = (RootViewController *)[navigationController topViewController];
   */
//	rootViewController.toolbarItems = [rootViewController toolbarButtons];
  rootViewController.navigationController.navigationBarHidden = NO;
  rootViewController.navigationController.toolbarHidden = NO;
  rootViewController.managedObjectContext = self.managedObjectContext;
                                     
                                
  
  [window addSubview:[navigationController view]];
  bounds =rootViewController.view.frame;
  NSLog(@"root view - x => %f,y => %f, width => %f, height => %f", 
        bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height);
  [window makeKeyAndVisible];
}

/**
 applicationWillTerminate: saves changes in the application's managed object context 
 before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
  NSLog(@"applicationWillTerminate:");
  NSError *error = nil;
  if (managedObjectContext != nil) {
    if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
      /*
       Replace this implementation with code to handle the error appropriately.
       
       abort() causes the application to generate a crash log and terminate. 
       You should not use this function in a shipping application, 
       although it may be useful during development. 
       If it is not possible to recover from the error, 
       display an alert panel that instructs the user to quit the application
       by pressing the Home button.
       */
      NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
      abort();
    } 
  }
}


#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, 
 it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
  
  if (managedObjectContext != nil) {
    return managedObjectContext;
  }
  
  NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
  if (coordinator != nil) {
    managedObjectContext = [[NSManagedObjectContext alloc] init];
    [managedObjectContext setPersistentStoreCoordinator: coordinator];
  }
  return managedObjectContext;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, 
 it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
  
  if (managedObjectModel != nil) {
    return managedObjectModel;
  }
  managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
  return managedObjectModel;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, 
 it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
  
  if (persistentStoreCoordinator != nil) {
    return persistentStoreCoordinator;
  }
  
  NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"PicasaViewer.sqlite"]];
  
  NSError *error = nil;
  persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] 
                                initWithManagedObjectModel:[self managedObjectModel]];
  if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
                                                configuration:nil 
                                                          URL:storeUrl 
                                                      options:nil 
                                                        error:&error]) {
    /*
     Replace this implementation with code to handle the error appropriately.
     
     abort() causes the application to generate a crash log and terminate. 
     You should not use this function in a shipping application, 
     although it may be useful during development. 
     If it is not possible to recover from the error, 
     display an alert panel that instructs the user 
     to quit the application by pressing the Home button.
     
     Typical reasons for an error here include:
     * The persistent store is not accessible
     * The schema for the persistent store is incompatible 
     with current managed object model
     Check the error message to determine what the actual problem was.
     */
    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    abort();
  }    
  
  return persistentStoreCoordinator;
}


#pragma mark -
#pragma mark Application's Documents directory

/**
 Returns the path to the application's Documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
  return [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
                                              NSUserDomainMask, YES) 
          lastObject];
}


#pragma mark -
#pragma mark Memory management

- (void)dealloc {
  NSLog(@"AppDelegate dealloc");
  NSLog(@"retain count = %d", [managedObjectContext retainCount] );
  [managedObjectContext release];
  [managedObjectModel release];
  [persistentStoreCoordinator release];
  
  [navigationController release];
  [window release];
  [super dealloc];
}


@end
