//
//  RootViewController.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/21.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "NewUserViewController.h"
#import "PicasaFetchController.h"
#import "LabeledActivityIndicator.h"

/*!
 @class RootViewController
 RootのView. ユーザの一覧を表示するView
 */
@interface RootViewController : UITableViewController 
<NSFetchedResultsControllerDelegate,NewUserViewControllerDeleate, 
PicasaFetchControllerDelegate, LabeledActivityIndicatorDelegate> {
  NSFetchedResultsController *fetchedUsersController;
  
  NSManagedObjectContext *managedObjectContext;
  
  UIBarButtonItem *addButton;
  // toolbarに表示するButtonの配列
  NSMutableArray *toolbarButtons;
  // 削除処理中のindicator
  LabeledActivityIndicator *indicatorView;
}

/*!
 @prooerty fetchedUsersController
 @discussion User一覧のFetched Controller
 */
@property (nonatomic, retain) NSFetchedResultsController *fetchedUsersController;
/*!
 @prooerty NSManagedObjectContext
 @discussion CoreDataのObject管理Context,永続化Storeのデータの管理
 */
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;

/*
 @method toolBarButtons
 @discussion toolbarに表示するButtonのArrayを返す
 */
- (NSArray *) toolbarButtons;

/*!
 @method settingsAction:
 @discussion 設定ボタンのアクション、設定Viewの表示
 */
- (void) settingsAction:(id)sender;


@end
