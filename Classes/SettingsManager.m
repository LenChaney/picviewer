//
//  SettingsManager.m
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

#import "SettingsManager.h"

static NSInteger imageSizes[3] = {640, 1280, 1600};

#define kRegexEmail @"^[0-9a-zA-Z][0-9a-zA-Z_+-.]+@[0-9a-zA-Z][0-9a-zA-Z_.-]+.[a-zA-Z]+$"

@interface SettingsManager (Private) 

/*!
 @method stringForKey:withDefault
 @discussion 指定したKeyの文字列値を返す
 */
- (NSString *)stringForKey:(NSString *)key withDefault:(NSString *)defaultValue;

/*!
 @method objectForKey:withDefault
 @discussion 指定したKeyの値を返す
 */
- (NSObject *)objectForKey:(NSString *)key withDefault:(NSObject *)defaultValue;



/*!
 @method setObject:forKey
 @discussion 指定したKeyの値を設定する
 */
- (void)setObject:(id)object forKey:(NSString *)key;

@end

@implementation SettingsManager

#pragma mark Public

- (void) setUserId:(NSString *)userId {
  [self setObject:userId forKey:@"userId"];
}

- (NSString *) userId {
  return [self stringForKey:@"userId" withDefault:@""];
}
- (void) setUsername:(NSString *)username {
  [self setObject:username forKey:@"username"];
}

- (NSString *) username {
  return [self stringForKey:@"username" withDefault:@""];
}

- (void) setUserLastModifiedAt:(NSDate *)userLastModifiedAt {
  [self setObject:userLastModifiedAt forKey:@"userLastModifiedAt"];
}

- (NSDate *)userLastModifiedAt {
  return (NSDate *)[self objectForKey:@"userLastModifiedAt" withDefault:nil];
}


- (void) setPassword:(NSString *)password {
  [self setObject:password forKey:@"password"];
}

- (NSString *) password {
  return [self stringForKey:@"password" withDefault:@""];
}


- (void) setCurrentUser:(NSString *)user {
  [self setObject:user forKey:@"currentUser"];
}

- (NSString *)currentUser {
 return [self stringForKey:@"currentUser" withDefault:nil];
}

- (void) setCurrentAlbum:(NSString *)albumId {
  [self setObject:albumId forKey:@"currentAlbum"];
}

- (NSString *)currentAlbum {
 return  [self stringForKey:@"currentAlbum" withDefault:nil];
}


- (void) setImageSize:(NSInteger)size {
  [self setObject:[NSNumber numberWithInt:size] forKey:@"imageSize"];
}

- (NSInteger) imageSize {
  NSNumber *n = (NSNumber *)[self objectForKey:@"imageSize" 
                       withDefault:[NSNumber numberWithInt:1280]];
  return [n intValue];
}

- (BOOL) isEqualUserId:(NSString *)userId {
  NSString *myUserId = [self username];
  if(myUserId) {
    return [myUserId isEqualToString:userId];
  }
  return NO;
}


#pragma mark -

#pragma mark Static

+ (NSInteger)imageSizeToIndex:(NSInteger)size {
  int c = sizeof(imageSizes)  / sizeof(imageSizes[0]);
  NSInteger index = 1;
  for(int i = 0; i < c; ++i) {
    if(size == imageSizes[i]) {
      index = i;
      break;
    }
  }
  return index;
}


+ (NSInteger)indexToImageSize:(NSInteger)index {
  int c = sizeof(imageSizes)  / sizeof(imageSizes[0]);
  if(index >= c)
    return 1280;
  return imageSizes[index];
}

#pragma mark -

#pragma mark Private

- (NSString *)stringForKey:(NSString *)key withDefault:(NSString *)defaultValue {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSString *value = [userDefaults stringForKey:key];
  if(!value)
    value = defaultValue;
  
  [pool drain];
	return value;
}

- (NSObject *)objectForKey:(NSString *)key withDefault:(NSString *)defaultValue {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSObject *value = [userDefaults objectForKey:key];
  if(!value)
    value = defaultValue;
  
  [pool drain];
	return value;
}


- (void)setObject:(id)object forKey:(NSString *)key {
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:object forKey:key];
  [userDefaults synchronize];
  
  [pool drain];
}

- (BOOL) validEmail:(NSString *)email {
  NSError* error = nil;
  NSRegularExpression *regex =
  [NSRegularExpression regularExpressionWithPattern:kRegexEmail
                                            options:NSRegularExpressionCaseInsensitive
                                              error:&error];
  NSTextCheckingResult *match = [regex firstMatchInString:email
                                                  options:0
                                                    range:NSMakeRange(0, email.length)];
  return !(match == nil);
  
}


#pragma mark -

@end
