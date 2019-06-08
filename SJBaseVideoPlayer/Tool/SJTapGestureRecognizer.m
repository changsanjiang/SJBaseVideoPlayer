//
//  SJTapGestureRecognizer.m
//  Pods
//
//  Created by 畅三江 on 2019/6/8.
//

#import "SJTapGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

NS_ASSUME_NONNULL_BEGIN
@interface SJTapGestureRecognizer ()

@end

@implementation SJTapGestureRecognizer

- (void)reset {
    [super reset];
    self.state = UIGestureRecognizerStatePossible;
}

//- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
//    self.state = UIGestureRecognizerStateBegan;
//    _startPoint = [(UITouch *)[touches anyObject] locationInView:self.view];
//    _lastPoint = _currentPoint;
//    _currentPoint = _startPoint;
//    if (_action) _action(self, YYGestureRecognizerStateBegan);
//}
//
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    UITouch *touch = (UITouch *)[touches anyObject];
//    CGPoint currentPoint = [touch locationInView:self.view];
//    self.state = UIGestureRecognizerStateChanged;
//    _currentPoint = currentPoint;
//    if (_action) _action(self, YYGestureRecognizerStateMoved);
//    _lastPoint = _currentPoint;
//}
//
//- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    self.state = UIGestureRecognizerStateEnded;
//    if (_action) _action(self, YYGestureRecognizerStateEnded);
//}
//
//- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//    self.state = UIGestureRecognizerStateCancelled;
//    if (_action) _action(self, YYGestureRecognizerStateCancelled);
//}


// mirror of the touch-delivery methods on UIResponder
// UIGestureRecognizers aren't in the responder chain, but observe touches hit-tested to their view and their view's subviews
// UIGestureRecognizers receive touches before the view to which the touch was hit-tested
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}
- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}
- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}
- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    
}
//- (void)touchesEstimatedPropertiesUpdated:(NSSet<UITouch *> *)touches NS_AVAILABLE_IOS(9_1);

//- (void)pressesBegan:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event NS_AVAILABLE_IOS(9_0);
//- (void)pressesChanged:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event NS_AVAILABLE_IOS(9_0);
//- (void)pressesEnded:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event NS_AVAILABLE_IOS(9_0);
//- (void)pressesCancelled:(NSSet<UIPress *> *)presses withEvent:(UIPressesEvent *)event NS_AVAILABLE_IOS(9_0);

@end
NS_ASSUME_NONNULL_END
