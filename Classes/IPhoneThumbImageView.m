//
//  IPhoneThumbImageView.m
//  PicasaViewer
//
//  Created by nyaago on 2012/10/31.
//
//

#import "IPhoneThumbImageView.h"

@implementation IPhoneThumbImageView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

+ (NSUInteger) thumbWidthForContainer:(UIView *)containerView {
  NSInteger w = containerView.frame.size.width;
  return w / 4;
  
}

+ (NSUInteger) thumbHeightForContainer:(UIView *)containerView {
  NSInteger w = containerView.frame.size.width;
  return w / 4;
}


- (id) initWithImage:(UIImage *)image withIndex:(NSNumber *)i withContainer:(UIView *)container;
{
  self = [super initWithImage:image withIndex:i withContainer:container];
  return self;
}



- (CGPoint) pointForThumb:(NSUInteger)n {
  NSLog(@"width = %f, height = %f", self.containerView.bounds.size.width,
          self.containerView.bounds.size.height);
  NSUInteger w = [self thumbWidth];
  NSUInteger h = [self thumbHeight];
  NSUInteger padding = 2.0f;
  NSUInteger cols = self.containerView.bounds.size.width / w;
  NSUInteger row = n / cols;	// base - 0
  NSUInteger col = n % cols;	// base - 0
  return CGPointMake(col * h + padding, row * w + padding);
}

- (CGRect) frameForThumb:(NSUInteger)n {
  NSUInteger w = [self thumbWidth];
  NSUInteger h = [self thumbHeight];
  NSUInteger padding = 2.0f;
  CGPoint point = [self pointForThumb:n];
  return CGRectMake(point.x, point.y, w - padding * 2, h - padding *2);
}

- (NSUInteger) thumbWidth {
  return [[self class] thumbWidthForContainer:self.containerView];
}

- (NSUInteger) thumbHeight {
  return [[self class] thumbHeightForContainer:self.containerView];
}


@end