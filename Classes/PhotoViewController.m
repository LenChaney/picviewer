//
//  PhotoViewController.m
//  PicasaViewer
//
//--
// Copyright (c) 2012 nyaago
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//++

#import "PhotoViewController.h"
#import "Photo.h"
#import "PhotoImage.h"
#import "PhotoInfoViewController.h"
#import "PhotoActionDelegate.h"
#import "SettingsManager.h"
#import "NetworkReachability.h"

@interface PhotoViewController(Private)

/*!
 @method canUpdatePhoto
 @return 写真情報の更新が可能か?
 */
- (BOOL) canUpdatePhoto:(NSInteger)index;

/*!
 @method frameForPhoro:
 @discussion PhotoのFrameのRectを返す
 */
-(CGRect) viewFrameForImage:(UIImage *)image;

/*!
 @method showImage
 @discussion 写真を表示する。未ダウンロードであれば、thumbnailを表示して、ダウンロード処理を起動
 */
-(void) showImage;

/*!
 @method downloadPhoto:
 @discussion 写真のダウンロードを開始する
 */
- (void) downloadPhoto:(Photo *)photo;

/*!
 @method viewFrame:
 @discussion viewのframeのRectを返す
 */
- (CGRect) viewFrame:(UIDeviceOrientation)orientation;

/*!
 @method tapAction:
 @discussion tap発生時に起動されるAction.
 2tapでなければ、statusbar,navigationbarの表示/非表示切り替えを行う。
 */
- (void) tapAction:(id)arg;


@end

@interface PhotoScrollView : UIScrollView   
{
}

@end

@implementation PhotoScrollView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  [[self nextResponder] touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesCancelled:touches withEvent:event];
  [[self nextResponder] touchesCancelled:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  [[self nextResponder] touchesEnded:touches withEvent:event];
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  [[self nextResponder] touchesMoved:touches withEvent:event];
}

@end

static NSLock *lockFetchedResultsController;

@implementation PhotoViewController

@synthesize fetchedPhotosController, managedObjectContext;
@synthesize prevButton,nextButton;
@synthesize scrollView;
@synthesize imageView;
@synthesize indexForPhoto;
@synthesize toolbar;
@synthesize pageController;

#pragma mark View lifecycle

/*
 // The designated initializer.  Override if you create the controller programmatically 
 // and want to perform customization that is not appropriate for viewDidLoad.
 - (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
 if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
 // Custom initialization
 }
 return self;
 }
 */

// Implement viewDidLoad to do additional setup after loading the view, 
// typically from a nib.
// Viewロードの通知 - scrollViewの設定、デバイス回転管理の開始、Downloader初期化
- (void)viewDidLoad {
  NSLog(@"photo view contoller viewDidLoad");
  [super viewDidLoad];
  //
  if(!lockFetchedResultsController)
    lockFetchedResultsController = [[NSLock alloc] init];
  
  // scrollViewの設定
  NSInteger statusBarHeight;
  statusBarHeight = [UIApplication sharedApplication].statusBarFrame.size.height;
  CGRect rect = self.view.bounds;
  rect.size.height += statusBarHeight;
  scrollView = [[PhotoScrollView alloc] initWithFrame:rect];
  
  scrollView.maximumZoomScale = 3.0;
  scrollView.minimumZoomScale = 1.0;
  scrollView.delegate = self;
  scrollView.scrollEnabled = YES;
  scrollView.userInteractionEnabled = YES;
  scrollView.bounces = NO;
  scrollView.backgroundColor = [UIColor blackColor];
  scrollView.multipleTouchEnabled = YES;
  self.view.backgroundColor = [UIColor blackColor];
  [self.view addSubview:scrollView];
  self.wantsFullScreenLayout = YES;
  self.navigationItem.rightBarButtonItem = [PhotoViewController backButton];
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  NSLog(@"photo view controller view will apear");
}

// View表示時の通知
// Viewのサイズ、toolbarの配置の調整をしてい写真を表示
- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  NSLog(@"photo view controller view will apear");
  
  
}

- (void)viewDidDisappear:(BOOL)animated {
  // Download実行中の場合,停止を要求、完了するまで待つ
  if(downloader) {
  }
}

#pragma mark -

#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
  // Releases the view if it doesn't have a superview.
  [super didReceiveMemoryWarning];
  
  // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
  // Download実行中の場合,停止を要求、完了するまで待つ
  if(downloader) {
    [downloader requireStopping];
    [downloader waitCompleted];
    [downloader release];
  }
  
  if(managedObjectContext)
    [managedObjectContext release];
  [prevButton release];
  [nextButton release];
  [scrollView release];
  if(imageView)
    [imageView release];
  [toolbar release];
  if(fetchedPhotosController) {
    [fetchedPhotosController release];
    fetchedPhotosController = nil;
  }
  if(pageController)
    [pageController release];
  [super dealloc];
}

#pragma mark -

#pragma mark PhotoViewController


- (Photo *)photoAt:(NSUInteger)index {
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSUInteger indexes[2];
  indexes[0] = 0;
  indexes[1] = index;
  Photo *photoObject = [fetchedPhotosController 
                        objectAtIndexPath:[NSIndexPath 
                                           indexPathWithIndexes:indexes length:2]];
  [pool drain];
  return photoObject;
}  

- (UIView *)thumbnailAt:(NSUInteger)index {
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  UIView *imgView = nil;
  NSUInteger indexes[2];
  indexes[0] = 0;
  indexes[1] = index;
  [lockFetchedResultsController lock];
  Photo *photoObject = [fetchedPhotosController
                        objectAtIndexPath:[NSIndexPath 
                                           indexPathWithIndexes:indexes length:2]];
  [lockFetchedResultsController unlock];
  UIImage *image = nil;
  if(photoObject.thumbnail) {
    image  = [UIImage imageWithData:photoObject.thumbnail];
    if(image) {
      imgView = [[UIImageView alloc] initWithImage:image];
      imgView.frame = [self viewFrameForImage:image];
    }
  }
  else {
  }
  [pool drain];
  return imgView;
}

- (UIImageView *)photoImageAt:(NSUInteger)index {
  
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  NSLog(@"Photo view controller photoImageAt");
  UIImageView *imgView = nil;
  NSUInteger indexes[2];
  indexes[0] = 0;
  indexes[1] = index;
  Photo *photoObject = [fetchedPhotosController
                        objectAtIndexPath:[NSIndexPath 
                                           indexPathWithIndexes:indexes length:2]];
  UIImage *image = nil;
  if(photoObject.photoImage) {
    PhotoImage *photoImage = (PhotoImage *)photoObject.photoImage;
    if(photoImage.image && [photoImage.image length] > 0) {
      NSLog(@"image length = %d", [photoImage.image length] );
      image  = [UIImage imageWithData:photoImage.image];
      if(image) {
        imgView = [[UIImageView alloc] initWithImage:image];
        imgView.frame = [self viewFrameForImage:image];
      }
    }
  }
  else {
    imgView = nil;
  }
  [pool drain];
  return imgView;
}

- (NSUInteger)photoCount {
  id <NSFetchedResultsSectionInfo> sectionInfo = [[fetchedPhotosController sections]
                                                  objectAtIndex:0];
  return [sectionInfo numberOfObjects];
}



- (void) setIndexForPhoto:(NSUInteger)index {
  
  indexForPhoto = index;
}

#pragma mark -


#pragma mark QueuedURLDownloaderDelegate

/*!
 ダウンロードエラー時の通知
 */
- (void)downloadDidFailWithError:(NSError *)error withUserInfo:(NSDictionary *)info {
  NSLog(@"downloadDidFailWithError");
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


/*!
 ダウンロード完了時の通知
 */
- (void)didFinishLoading:(NSData *)data withUserInfo:(NSDictionary *)info {
  if(indexForPhoto >= [self photoCount])
    return;
  if(imageView) {
    if([imageView subviews])
      [imageView removeFromSuperview];
    [imageView release];
    imageView = nil;
  }
  Photo *photo = [self photoAt:indexForPhoto];
  //新しいPhotoImageオブジェクトを作って
  [lockFetchedResultsController lock];
  NSManagedObject *photoImageObject 
  = [NSEntityDescription insertNewObjectForEntityForName:@"PhotoImage"
                                  inManagedObjectContext:managedObjectContext];
  
  [photoImageObject setValue:data forKey:@"image"];
  
  [photo setPhotoImage:photoImageObject];
  NSError *error;
  //  photo.content = data;
  [managedObjectContext lock];
  if(![managedObjectContext save:&error] ) {
    NSLog(@"Unresolved error %@", error);
  }
  [managedObjectContext unlock];
  [lockFetchedResultsController unlock];
  imageView = [self photoImageAt:indexForPhoto];
  
  // 最大ズームスケールの設定
  if(imageView) {
    if(imageView.image.size.width > self.scrollView.frame.size.width) {
      self.scrollView.maximumZoomScale = 
      imageView.image.size.width / self.scrollView.frame.size.width;
    }
    else {
      self.scrollView.maximumZoomScale = 1.0f;
    }
    [self.scrollView addSubview:imageView];
  }
  //
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

/*!
 ダウンロードがキャンセルされたときの通知
 */
- (void)dowloadCanceled:(QueuedURLDownloader *)downloader {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


#pragma mark -

#pragma mark Private

- (BOOL) canUpdatePhoto:(NSInteger ) index {
  
  Photo *photo = [self photoAt:index];
  Album *album = (Album *)photo.album;
  User *user = (User *)album.user;
  if(user) {
    SettingsManager *settings = [[SettingsManager alloc] init];
    BOOL ret = [settings isEqualUserId:user.userId] ? YES : NO;
    [settings release];
    return ret;
  }
  return NO;
}


-(CGRect) viewFrameForImage:(UIImage *)image {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  CGSize size = image.size;
  CGRect viewRect = self.scrollView.bounds;
  CGRect rect;
  if(size.height / size.width > viewRect.size.height / viewRect.size.width ) { 
    // 画像が縦長
    float rate = viewRect.size.height / image.size.height;
    float width = size.width * rate;
    
    rect = CGRectMake((viewRect.size.width -  width) / 2, 
                      0.0f, 
                      width, 
                      viewRect.size.height);
  }
  else { // 画像が横長
    float rate = viewRect.size.width / image.size.width;
    float height = size.height * rate;
    rect = CGRectMake(0.0f, 
                      (viewRect.size.height - height) / 2, 
//                      0.0f,
                      viewRect.size.width, 
                      height);
  }
	[pool drain];
  return rect;
}

- (CGRect)viewFrame:(UIDeviceOrientation)orientation {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  
  // View階層Debug
  /*
  UIView *v = self.view.superview;
  CGRect rect = v.frame;
  v = self.view;
  for(int i = 0; i < 4; ++i) {
    NSLog(@"Class = %@,Page view,x ==> %f, y => %f, width => %f, height => %f ",
          [v class],
          rect.origin.x , rect.origin.y,
          rect.size.width, rect.size.height
          );
    v = v.superview;
  }
   */
  
  CGRect bounds = self.view.frame;
  [pool drain];
  return bounds;
}

-(void) showImage {
  NSLog(@"showImage");
  
  if(indexForPhoto >= [self photoCount])
    return;

  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

  BOOL mustDownload = NO;
  if(imageView) {
    if([imageView subviews])
      [imageView removeFromSuperview];
    [imageView release];
    imageView = nil;
  }
  
  // Photo Viewを生成.PhotoがなければThumbnailのView
  imageView = [self photoImageAt:indexForPhoto];
  if(!imageView) {
    imageView = [self thumbnailAt:indexForPhoto];
    mustDownload = YES;
  }
  
  // 最大ズームスケールの設定
  if(imageView.image.size.width > self.scrollView.frame.size.width) {
	  self.scrollView.maximumZoomScale = 
  	imageView.image.size.width / self.scrollView.frame.size.width;
  }
  else {
    self.scrollView.maximumZoomScale = 1.0f;
  }

  scrollView.contentSize = self.view.frame.size;
  [self.scrollView addSubview:imageView];

  //  Photoがnilだった場合、ダウンロード処理の起動
  if(mustDownload) {
    NSLog(@"down load photo");
    [self downloadPhoto:[self photoAt:indexForPhoto]];
  }
  [pool drain];
}


- (void) downloadPhoto:(Photo *)photo  {
  if(downloader) {
    return;
  }
  // Network接続確認
  if(![NetworkReachability reachable]) {
    if(!alertedNetworkError) {
      if(indexForPhoto == self.pageController.curPageNumber) {
        NSString *title = NSLocalizedString(@"Notice","Notice");
        NSString *message = NSLocalizedString(@"Warn.NetworkNotReachable",
                                              "not reacable");
        UIAlertView *alertView = [[UIAlertView alloc] 
                                  initWithTitle:title
                                  message:message
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        [alertView release];
        alertedNetworkError = YES;
      }
    }
    return;
  }
  downloading = YES;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  // downloader初期化
  downloader = [[QueuedURLDownloader alloc] initWithMaxAtSameTime:2];
  downloader.delegate = self;
  // download開始
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  [downloader addURL:[NSURL URLWithString:photo.urlForContent ]
        withUserInfo:nil];
  [downloader finishQueuing];
  [downloader start];
  [pool drain];
}

#pragma mark -

#pragma mark Action

- (void) tapAction:(id)arg {
  if(lastTapCount == 1) {
    [self.pageController changeNavigationAndStatusBar];
  }
}


#pragma mark -

#pragma mark UIResponder

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesBegan:touches withEvent:event];
  [[self nextResponder] touchesBegan:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesCancelled:touches withEvent:event];
  [[self nextResponder] touchesCancelled:touches withEvent:event];
}

/*!
 @method touchesEnded:withEvent:
 @discussion touch終了時の通知.
 2tapのときは、Photoを最大表示.1tapのときは、navigation/toolbar/statusbarの
 表示切り替えを起動する.
 */

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesEnded:touches withEvent:event];
  
  UITouch *touch = [touches anyObject];
  //NSLog(@"touch event - touches - %d, tap count = %d",
  //      [touches count], [touch tapCount]);
  if([touch tapCount] == 2) {
    if(self.scrollView.zoomScale == 1.0f) {
    	self.scrollView.zoomScale = self.scrollView.maximumZoomScale;
    }
    else {
    	self.scrollView.zoomScale = 1.0f;
    }
    lastTapCount = 2;
  }
  else {
    lastTapCount = 1;
    [self performSelector:@selector(tapAction:)
               withObject:nil
               afterDelay:0.5f];
  	[[self nextResponder] touchesEnded:touches withEvent:event];
  }
}


- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
  [super touchesMoved:touches withEvent:event];
  [[self nextResponder] touchesMoved:touches withEvent:event];
}

#pragma mark -

#pragma mark PageViewDelegate protocol

/*!
 @method pageDidAddWithPageViewController:withOrientation
 @discussion このViewがPagingScrollViewに追加されたときの通知
 */
- (void)pageDidAddWithPageViewController:(PageControlViewController *)controller 
                               withOrientation:(UIDeviceOrientation)orientation{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // Viewサイズ調整
  self.view.frame = [self viewFrame:orientation];
  CGRect bounds = self.view.frame;
  bounds.origin.x = 0;
  bounds.origin.y = 0;
  self.scrollView.frame = bounds;
  
  // toolBar配置
  CGRect toolbarFrame = toolbar.frame;
  toolbarFrame.origin.y 
  = self.view.frame.size.height - toolbarFrame.size.height ;
  toolbar.frame = toolbarFrame;
  toolbar.hidden = YES;
  [self showImage];
  [self.view bringSubviewToFront:toolbar];
  [pool drain];
}

- (void) pageView:(PageControlViewController *)controller 
                rotated:(UIDeviceOrientation)orientation {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  // Viewサイズ調整
  self.view.frame = [self viewFrame:orientation];
  CGRect bounds = self.view.frame;
  bounds.origin.x = 0;
  bounds.origin.y = 0;
  self.scrollView.frame = bounds;
  // toolBar配置
  CGRect toolbarFrame = toolbar.frame;
  toolbarFrame.origin.y 
  = self.view.frame.size.height - toolbarFrame.size.height ;
  toolbar.frame = toolbarFrame;
  toolbar.hidden = YES;
  [self showImage];
  [self.view bringSubviewToFront:toolbar];
  [pool drain];
}

- (void) setPageController:(PageControlViewController *)controller {
  if(pageController) {
    if(pageController == controller)
      return;
    [pageController release];
  }
  pageController = controller;
  [pageController retain];
}

- (void) movedToCurrentInPageView:(PageControlViewController *)controller {
  if(![self photoImageAt:indexForPhoto]) {
    // 表示されているのがoriginal 画像でない場合(=original画像未取得の場合）
    // downloadして表示させる.
    [self showImage];
  }
}


/*!
 @method viewInfoAction:
 @discssion 情報表示ボタンのアクション.写真情報表示Viewを表示する.
 */
- (void) viewInfoAction:(PageControlViewController *)parentController  {
  PhotoInfoViewController *viewController = [[PhotoInfoViewController alloc]
                                             initWithNibName:@"PhotoInfoViewController" 
                                             bundle:nil];
  viewController.canUpdate = [self canUpdatePhoto:[self indexForPhoto]];
  viewController.managedObjectContext = self.managedObjectContext;
  Photo *photo = [self photoAt:indexForPhoto];
  UINavigationController *navigationController  = 
  [[UINavigationController alloc] initWithRootViewController:viewController];
  
  viewController.photo= photo;
  [navigationController setModalPresentationStyle:UIModalPresentationFormSheet];
  [[parentController parentViewController] presentModalViewController:navigationController 
                                                             animated:YES];
  [viewController release];
  [navigationController release];
}


/*!
 @method doAction:
 @discssion Actionボタンのアクション.写真情報表示Viewを表示する.
 */
- (void) doAction:(PageControlViewController *)parentController  {
//  UIActionSheet *actionSheet
  // 送信方法を選択するシートを表示. 選択時の処理は、Delegateに委譲
  Photo *photo = [self photoAt:indexForPhoto];
  PhotoActionDelegate *delegate = [[PhotoActionDelegate alloc] 
                                   initWithPhotoObject:photo 
                                   withParentViewController:pageController];
  UIActionSheet *sheet = [[UIActionSheet alloc] 
                          initWithTitle:NSLocalizedString(@"Photo.Action",@"Select!") 
                          delegate:delegate 
                          cancelButtonTitle:NSLocalizedString(@"Cancel",@"Cancel") 
                          destructiveButtonTitle:nil
                          otherButtonTitles:NSLocalizedString(@"Email",@"by email"),
                          NSLocalizedString(@"SaveToLibrary",@"to album"),
                          nil];
  [sheet showInView:parentController.view];                        
}


- (BOOL) isCompleted {
  if(self.imageView) {
    if(downloader) {
      return downloader.isCompleted;
    }
    return YES;
  }
  else {
    return NO;
  }
}

- (BOOL) canDiscard {
  if(downloader == nil || downloader.isCompleted) {
    return YES;
  }
  [downloader requireStopping];
  [downloader waitCompleted];
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  return YES;
}


- (void) requireToDiscard {
  if(downloader != nil ) {
    [downloader requireStopping];
  }
}

#pragma mark -

#pragma mark UIScrollViewDelegate


- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
  return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
  CGRect frame = imageView.frame;
  if( (self.scrollView.bounds.size.width - 
       self.scrollView.contentSize.width) / 2 > 0) {
	  frame.origin.x = (self.scrollView.bounds.size.width - 
                      self.scrollView.contentSize.width) / 2;
  }
  else {
    frame.origin.x = 0.0f;
  }
  if((self.scrollView.bounds.size.height - 
      self.scrollView.contentSize.height) / 2 > 0) {
  	frame.origin.y = (self.scrollView.bounds.size.height - 
                      self.scrollView.contentSize.height) / 2;
  }
  else {
    frame.origin.y = 0.0f;
  }
  
  imageView.frame = frame;
  
}

/*!
 @method scrollViewDidEndZooming:withView:atScale
 @discussion Zooming時の通知。
 imageViewの縦の配置調整を行う。
 */

- (void)scrollViewDidEndZooming:(UIScrollView *)zoomingScrollView 
                       withView:(UIView *)view 
                        atScale:(float)scale {
  CGRect frame = imageView.frame;
  if( (self.scrollView.bounds.size.width - 
       self.scrollView.contentSize.width) / 2 > 0) {
	  frame.origin.x = (self.scrollView.bounds.size.width - 
                      self.scrollView.contentSize.width) / 2;
  }
  else {
    frame.origin.x = 0.0f;
  }
  if((self.scrollView.bounds.size.height - 
      self.scrollView.contentSize.height) / 2 > 0) {
  	frame.origin.y = (self.scrollView.bounds.size.height - 
                      self.scrollView.contentSize.height) / 2;
  }
  else {
    frame.origin.y = 0.0f;
  }
  imageView.frame = frame;
}




#pragma mark statci Method

+ (UIBarButtonItem *)backButton {
  UIBarButtonItem *backButton = [[UIBarButtonItem alloc] 
                  initWithTitle:NSLocalizedString(@"Photos", @"Photos")
                  style:UIBarButtonItemStyleDone 
                  target:nil
                  action:nil ];
	[backButton  autorelease];
  return backButton;
}


@end
