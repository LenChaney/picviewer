//
//  QueuedURLDownloader.h
//  PicasaViewer
//
//  Created by nyaago on 10/04/26.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


/*!
 @class QueuedURLDownloader
 NSURLConnectionを利用して非同期にファイルのダウンロードを行う.
 初期化時に同時にダウンロードする最大を指定,
 addURL:withUserInfoでダウンロード対象のURLをQueueに登録してダウンロードを行っていく。
 この登録を行うことにより、非同期にダウンロードが行われる.
 QueuedURLDownloaderDelegateプロトコルを実装したDelegateクラスの
 メソッド(didFinishLoading:withUserInfo)によりダウンロードした内容を取得する。
 
 以下の手順で、ダウンロードの処理を起動、終了をさせる。
 ダウンロードの起動処理は、新規スレッドで非同期に行われる。
 
 1.このクラスインスタンスの初期化.
 2.delegateにQueuedURLDownloaderDelegateプロトコルを実装したインスタンスを設定.
 3.startメソッドでダウンロード開始(URLが追加されたらダウンロードがはじめる状態にする).
 4.ダウンロード対象のURLを追加していく(addURL:withUnserInfo メソッド).
 5.finishメソッドでこれ以上、ダウンロードするものがないことを通知.
 例.
 // 初期化
 QueuedURLDownloader *downloader = [[QueuedURLDownloader alloc] initWithMaxAtSameTime:3];
 downloader.delegate = self;  // QueuedURLDownloaderDelegateプロトコルを実装したもの
 // 開始
 [downloader start];
 //
 NSDictionary *dict;
 dict = [[NSDictionary alloc] 
		  initWithObjectsAndKeys:@"value1, @"key1", nil] ;
 [downloader addURL:[NSURL URLWithString:urlString1 ]
	withUserInfo:dict];
 dict = [[NSDictionary alloc] 
	initWithObjectsAndKeys:@"value2, @"key2", nil] ;
 [downloader addURL:[NSURL URLWithString:urlString2 ]
	withUserInfo:dict];
 dict = [[NSDictionary alloc] 
	initWithObjectsAndKeys:@"value3, @"key3", nil] ;
 [downloader addURL:[NSURL URLWithString:urlString3 ]
 withUserInfo:dict];
 ...
 // これ以上、ダウンロードするものがないことを通知
 [downloader finishQueuing];
 
 ========
 実装について
 新規スレッドにより、Queueに追加されたダウンロード対象URLの要素を監視して、順番に
 NSURLConnectionにより非同期ダウンロード処理の起動を行っていく.
 NSURLConnectionよるダウンロード完了などは、NSURLConnectionのDelegateである、
 各ダウンロード要素管理のクラス(QueuedURLDownloaderElem)のインスタンスに通知され、さらに
 このダウンローダー(QueuedURLDownloader)に設定されてるDelegate(
 QueuedURLDownloaderDelegateプロトコルの実装)のメソッドに転送することにより、ダウンロード
 された結果を得ることができる。
 
 */
@protocol QueuedURLDownloaderDelegate;

@interface QueuedURLDownloader : NSObject {
  NSInteger maxAtSameTime;
  NSObject<QueuedURLDownloaderDelegate>  *delegate;
@private
  NSMutableArray *waitingQueue;
  NSMutableDictionary *runningDict;
  BOOL queuingFinished;
  BOOL completed;
  // 処理が開始されている?
  BOOL started;
  // 停止が要求されている?
  BOOL stoppingRequired;
  NSInteger completedCount;
  NSLock *lock;
  NSTimeInterval timeoutInterval;
}

@property (nonatomic, retain) NSObject<QueuedURLDownloaderDelegate> *delegate;
@property (readonly) NSInteger completedCount;
/*!
 Timeout時間,単位:秒,Default 10.0秒
 */
@property (nonatomic) NSTimeInterval timeoutInterval;

/*!
 同時にダウンロードする最大数を指定しての初期化
 */
- (id) initWithMaxAtSameTime:(NSInteger)count;

/*!
 ダウンロードするURLを追加
 */
- (void) addURL:(NSURL *)URL withUserInfo:(NSDictionary *)info;

/*!
 ダウンロードを開始
 */
- (void) start;

/*!
 @method requireStopping
 @discussion ダウンロード処理を停止を要求,実際に停止されたかは、isCompletedで確認する必要がある
 */
- (void) requireStopping;

/*!
 @method isCompleted
 @discussion Download処理が完了しているかの判定
 */
- (BOOL) isCompleted;

/*!
 @method waitCompleted
 @discussion Download処理が完了するまで待つ,まだ開始されていない場合は、すぐに返る。
 */
- (void) waitCompleted;

/*!
 これ以上、ダウンロードURLするものがないことを通知.
 この通知後、ダウンロード要素の追加は受け付けられず、現在実行待ち、実行中のダウンロードの処理が完了すれば、
 ダウンロード処理のスレッドが終了する。
 */
- (void) finishQueuing;

/*!
 ダウンロード実行待ち要素数
 */
- (NSInteger)waitingCount;


/*!
 ダウンロード実行中の要素数
 */
- (NSInteger)runningCount;


/*!
 同時にダウンロード処理を行う最大数
 */
@property (nonatomic) NSInteger maxAtSameTime;

/*!
 現在のQueueの要素数
 */
//@property (readonly) NSInteger count;

@end


/*!
 ダウンローダー(QueuedURLDownloader)のDelegate
 didFinishLoading:withUserInfoメソッドにより、QueuedURLDownloaderのaddURL:withUserInfo
 で指定したURLからのダウンロード通知を受け、ファイルの内容を得る。
 */
@protocol QueuedURLDownloaderDelegate


/*!
 @method didFinishLoading:withUserInfo:
 @discussion Download完了の通知.
 @param data ダウンロードしたデータ
 @param info QueuedURLDownloaderのaddURL:withUserInfoで渡した userInfo
 */
- (void)didFinishLoading:(NSData *)data withUserInfo:(NSDictionary *)info;

/*!
 @method downloadDidFailWithError:withUserInfo:
 @discussion Download時のエラー発生通知.
 @param  error 
 @param info QueuedURLDownloaderのaddURL:withUserInfoで渡した userInfo
 */
- (void)downloadDidFailWithError:(NSError *)error withUserInfo:(NSDictionary *)info;

@optional 
/*!
 @method didReceiveResponse:withUserInfo:
 @discussin 指定URL先からのレスポンスの通知
 @param response
 @param info QueuedURLDownloaderのaddURL:withUserInfoで渡した userInfo
 */
- (void)didReceiveResponse:(NSURLResponse *)response withUserInfo:(NSDictionary *)info;

/*!
 @method didReceiveResponse:withUserInfo:
 @discussin 指定URL先からのデーターの通知(部分的にデータ受信した場合も通知されることがある)
 @param data
 @param info QueuedURLDownloaderのaddURL:withUserInfoで渡した userInfo
 */
- (void)didReceiveData:(NSData *)data withUserInfo:(NSDictionary *)info;


/*!
 @method didAllCompleted
 @discussion すべてのダウンロードが完了したときの通知
 */
- (void)didAllCompleted;

@end



