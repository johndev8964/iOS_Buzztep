//
//  OpenStatusView.m
//  BuzzTepMeetUps
//
//  Created by Sanchit Thakur  on 05/05/15.
//  Copyright (c) 2015 ILLUMINZ. All rights reserved.
//

#import "OpenStatusView.h"

@implementation OpenStatusView

+ (OpenStatusView *)view
{
    return [[UINib nibWithNibName:@"OpenStatusView" bundle:nil] instantiateWithOwner:nil options:nil][0];
}

- (void)showOnView:(UIView *)view
{
    [view addSubview:self];
    
    CGRect rect = CGRectMake(0, 0, view.frame.size.width, 260);
    self.frame = CGRectOffset(rect, 0, - rect.size.height);
    
    [UIView animateWithDuration:1
                          delay:0
         usingSpringWithDamping:0.9
          initialSpringVelocity:10
                        options:0
                     animations:^{
                         self.frame = rect;
                     }
                     completion:nil];
}

- (void)hide
{
    [UIView animateWithDuration:1
                          delay:0
         usingSpringWithDamping:0.9
          initialSpringVelocity:10
                        options:0
                     animations:^{
                         self.frame = CGRectOffset(self.superview.bounds, 0, - self.superview.bounds.size.height);
                     }
                     completion:^(BOOL finished) {
                         [self removeFromSuperview];
                     }];
}

- (IBAction)getDirectionButtonTouch:(id)sender
{
    [self.delegate didGetDirection:self];
}

- (IBAction)addToCallButtonTouch:(id)sender
{
    [self.delegate didAddToCal:self];
}

- (IBAction)setReminderButtonTouch:(id)sender
{
    [self.delegate didSetReminder:self];
}

- (IBAction)changeStatusButtonTouch:(id)sender
{
    [self.delegate didChangeStatus:self];
}

- (IBAction)closeButtonTouch:(id)sender
{
    [self hide];
}

@end
