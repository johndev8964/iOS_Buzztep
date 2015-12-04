

#define STROKE_ANIMATION @"stroke_animation"
#define ROTATE_ANIMATION @"rotate_animation"

#import "SwipeRefresh.h"

typedef NS_ENUM(NSUInteger, PullState) {
	PullStateReady = 0,
	PullStateDragging,
	PullStateRefreshing,
	PullStateFinished
};

@interface SwipeRefresh()
{
	dispatch_once_t initConstraits;
	
	NSLayoutConstraint *topConstrait;
	NSLayoutConstraint *centerXConstrait;
	
	UIScrollView *tableScrollView;
	
	CAShapeLayer *pathLayer;
	CAShapeLayer *arrowLayer;
	UIView *container;
	CGFloat marginTop;
	
	BOOL isDragging;
	BOOL isFullyPulled;
	PullState pullState;
	
	NSInteger colorIndex;
}
@end

@implementation SwipeRefresh

- (id)init {
	if (self = [super init]) {
		self.backgroundColor = [UIColor clearColor];
		
		self.layer.opacity = 0;
		
		self.colors = @[self.tintColor];
		
		UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
		container = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
		[view addSubview:container];
		
		view.layer.backgroundColor = [UIColor grayColor].CGColor;
		view.layer.cornerRadius = 20.0;
		
		view.layer.shadowOffset = CGSizeMake(0, 0.7);
		view.layer.shadowColor = [[UIColor blackColor] CGColor];
		view.layer.shadowRadius = 1.0;
		view.layer.shadowOpacity = 0.12;
		
		pathLayer = [CAShapeLayer layer];
		pathLayer.strokeStart = 0;
		pathLayer.strokeEnd = 10;
		pathLayer.fillColor = nil;
		pathLayer.lineWidth = 3;
		
		UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:CGPointMake(20, 20) radius:9 startAngle:0 endAngle:2 * M_PI clockwise:YES];
		pathLayer.path = path.CGPath;
		pathLayer.strokeStart = 1;
		pathLayer.strokeEnd = 1;
		pathLayer.lineCap = kCALineCapRound;
		
		arrowLayer = [CAShapeLayer layer];
		arrowLayer.strokeStart = 0;
		arrowLayer.strokeEnd = 1;
		arrowLayer.fillColor = nil;
		arrowLayer.lineWidth = 3;
		arrowLayer.strokeColor = [UIColor blueColor].CGColor;
		UIBezierPath *arrow = [SwipeRefresh bezierArrowFromPoint:CGPointMake(20, 20) toPoint:CGPointMake(20, 20.8) width:0.8];
		arrowLayer.path = arrow.CGPath;
		arrowLayer.transform = CATransform3DMakeTranslation(8.6, 0, 0);
		
		[container.layer addSublayer:pathLayer];
		[container.layer addSublayer:arrowLayer];
		
		[self setAnchorPoint:CGPointMake(0.5, 0.5) forView:container];
		
		[self addSubview:view];
		
		CGRect rect = CGRectMake((self.superview.frame.size.width-40)/2, -50 + marginTop, 40, 40);
		self.frame = rect;
	}
	return self;
}

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
}

- (void)didMoveToSuperview {
	dispatch_once(&initConstraits, ^{
		topConstrait = [NSLayoutConstraint constraintWithItem:self
													attribute:NSLayoutAttributeTop
													relatedBy:NSLayoutRelationEqual
													   toItem:self.superview
													attribute:NSLayoutAttributeTop
												   multiplier:1.0
													 constant:-50];
		centerXConstrait = [NSLayoutConstraint constraintWithItem:self
														attribute:NSLayoutAttributeCenterX
														relatedBy:NSLayoutRelationEqual
														   toItem:self.superview
														attribute:NSLayoutAttributeCenterX
													   multiplier:1.0
														 constant:-20];
		
		[self setTranslatesAutoresizingMaskIntoConstraints:NO];
		[self.superview addConstraint:topConstrait];
		[self.superview addConstraint:centerXConstrait];
	});
}

- (id)initWithScrollView:(UIScrollView *)scrollView {
	self = [self init];
	
	tableScrollView = scrollView;
	
	marginTop =  scrollView.contentOffset.y;
	
	if (scrollView) {
		[scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
		[scrollView addObserver:self forKeyPath:@"pan.state" options:NSKeyValueObservingOptionNew context:nil];
	}
	
	return self;
}

- (void)dealloc {
	[tableScrollView removeObserver:self forKeyPath:@"contentOffset"];
	[tableScrollView removeObserver:self forKeyPath:@"pan.state"];
}

- (void)setMarginTop:(CGFloat)topMargin {
	marginTop = -topMargin;
	[self layoutIfNeeded];
}

- (void)setAnchorPoint:(CGPoint)anchorPoint forView:(UIView *)view{
	CGPoint oldOrigin = view.frame.origin;
	view.layer.anchorPoint = anchorPoint;
	CGPoint newOrigin = view.frame.origin;
	
	CGPoint transition;
	transition.x = newOrigin.x - oldOrigin.x;
	transition.y = newOrigin.y - oldOrigin.y;
	
	view.center = CGPointMake (view.center.x - transition.x, view.center.y - transition.y);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	
	if ([keyPath isEqualToString:@"contentOffset"]) {
		
		[self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
		
	} else if ([keyPath isEqualToString:@"pan.state"]) {
		
		if (pullState == PullStateRefreshing) return;
		
		NSInteger state = [[change valueForKey:NSKeyValueChangeNewKey] integerValue];
		
		if (state == 2) {
			if (pullState == PullStateFinished) {
				if (tableScrollView.contentOffset.y > -10 + marginTop) {
					isDragging = YES;
					pullState = PullStateDragging;
				}
			} else {
				isDragging = YES;
				pullState = PullStateDragging;
			}
			
		} else if (state == 3) {
			
			if (pullState != PullStateDragging) return;
			
			isDragging = NO;
			if (isFullyPulled) {
				pullState = PullStateRefreshing;
				[UIView animateWithDuration:.2f
						 animations:^{
							 topConstrait.constant = 10 - marginTop;
							 [self layoutIfNeeded];
						 }
				 ];
				[self startAnimating];
				[self sendActionsForControlEvents:UIControlEventValueChanged];
			} else {
				[UIView animateWithDuration:0.2 animations:^{
					topConstrait.constant = -50 - marginTop;
					[self layoutIfNeeded];
				} completion:^(BOOL finished) {
					pathLayer.strokeColor = ((UIColor*)self.colors[colorIndex]).CGColor;
				}];
			}
		}
	}
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
	
	if (pullState == PullStateRefreshing) return;
	
	float newY = -contentOffset.y - 50;
	
	if (contentOffset.y - marginTop > -100) {
		isFullyPulled = NO;
		
		pathLayer.strokeColor = ((UIColor*)self.colors[colorIndex]).CGColor;
		arrowLayer.strokeColor = ((UIColor*)self.colors[colorIndex]).CGColor;
		
		[self updateWithPoint:contentOffset outside:NO];
		
		if (isDragging) {
			topConstrait.constant = newY;
			[self layoutIfNeeded];
		}
		
	} else {
		isFullyPulled = YES;
		
		[self updateWithPoint:contentOffset outside:YES];
	}
}

- (void)updateWithPoint:(CGPoint)point outside:(BOOL)flag {
	
	CGFloat angle = -(point.y - marginTop) / 130;
	
	container.layer.transform = CATransform3DMakeRotation(angle * 10, 0, 0, 1);
	
	if (!flag && pullState == PullStateDragging) {
		[self showView];
		
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		pathLayer.strokeStart = 1 - angle;
		self.layer.opacity = angle * 2;
		[CATransaction commit];
	}
}

- (void)startAnimating {
	float currentAngle = [(NSNumber*)[container.layer valueForKeyPath:@"transform.rotation.z"] floatValue];
	CABasicAnimation *animation = [CABasicAnimation animation];
	animation.keyPath = @"transform.rotation";
	animation.duration = 4.0;
	animation.fromValue = @(currentAngle);
	animation.toValue = @(2 * M_PI + currentAngle);
	animation.repeatCount = INFINITY;
	[container.layer addAnimation:animation forKey:ROTATE_ANIMATION];
	
	CABasicAnimation *beginHeadAnimation = [CABasicAnimation animation];
	beginHeadAnimation.keyPath = @"strokeStart";
	beginHeadAnimation.duration = .5f;
	beginHeadAnimation.fromValue = @(0.25);
	beginHeadAnimation.toValue = @(1.f);
	beginHeadAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	CABasicAnimation *beginTailAnimation = [CABasicAnimation animation];
	beginTailAnimation.keyPath = @"strokeEnd";
	beginTailAnimation.duration = .5f;
	beginTailAnimation.fromValue = @(1.0);
	beginTailAnimation.toValue = @(1.0);
	beginTailAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	CABasicAnimation *endHeadAnimation = [CABasicAnimation animation];
	endHeadAnimation.keyPath = @"strokeStart";
	endHeadAnimation.beginTime = 0.5;
	endHeadAnimation.duration = 1.0;
	endHeadAnimation.fromValue = @(0.0);
	endHeadAnimation.toValue = @(0.25);
	endHeadAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	CABasicAnimation *endTailAnimation = [CABasicAnimation animation];
	endTailAnimation.keyPath = @"strokeEnd";
	endTailAnimation.beginTime = 0.5;
	endTailAnimation.duration = 1.0;
	endTailAnimation.fromValue = @(0);
	endTailAnimation.toValue = @(1.0);
	endTailAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	CAAnimationGroup *animations = [CAAnimationGroup animation];
	[animations setDuration:1.5];
	[animations setRemovedOnCompletion:NO];
	[animations setAnimations:@[beginHeadAnimation, beginTailAnimation, endHeadAnimation, endTailAnimation]];
	animations.repeatCount = INFINITY;
	[pathLayer addAnimation:animations forKey:STROKE_ANIMATION];
	
	NSTimer *timer = [NSTimer timerWithTimeInterval:.5 target:self selector:@selector(changeColor) userInfo:nil repeats:NO];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)changeColor {

	[self hideArrow];
	
	if (pullState == PullStateRefreshing) {
		
		colorIndex++;
		if (colorIndex > self.colors.count - 1) {
			colorIndex = 0;
		}
		
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		pathLayer.strokeColor = ((UIColor*)self.colors[colorIndex]).CGColor;
		[CATransaction commit];
		
		NSTimer *timer = [NSTimer timerWithTimeInterval:1.5 target:self selector:@selector(changeColor) userInfo:nil repeats:NO];
		[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
	}
}

- (void)hideArrow {
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	arrowLayer.opacity = 0;
	[CATransaction commit];
}

- (void)showArrow {
	arrowLayer.opacity = 1;
}

- (void)endAnimating {
	[container.layer removeAnimationForKey:ROTATE_ANIMATION];
	[pathLayer removeAnimationForKey:STROKE_ANIMATION];
}

- (void)showView {
	self.layer.transform = CATransform3DMakeScale(1, 1, 1);
	[self showArrow];
}

- (void)hideView {
	
	[UIView animateWithDuration:0.3 animations:^{
		self.layer.opacity = 0;
		self.layer.transform = CATransform3DMakeScale(0.5, 0.5, 1);
		
		// hide on center
		centerXConstrait.constant = -10;
		topConstrait.constant += 10;
		[self layoutIfNeeded];

		
	} completion:^(BOOL finished) {
		[self endAnimating];
		
		// update center
		centerXConstrait.constant = -20;
		
		pullState = PullStateFinished;
		colorIndex = 0;
		pathLayer.strokeColor = ((UIColor*)self.colors[colorIndex]).CGColor;
		
		topConstrait.constant = -50 + marginTop;
	}];
}

- (void)endRefreshing {
	[self hideView];
}

+ (UIBezierPath *)bezierArrowFromPoint:(CGPoint)startPoint toPoint:(CGPoint)endPoint width:(CGFloat)width {
	CGFloat length = hypotf(endPoint.x - startPoint.x, endPoint.y - startPoint.y);
	
	CGPoint points[3];
	[self getAxisAlignedArrowPoints:points width:width length:length];
	
	CGAffineTransform transform = [self transformForStartPoint:startPoint endPoint:endPoint length:length];
	
	CGMutablePathRef cgPath = CGPathCreateMutable();
	CGPathAddLines(cgPath, &transform, points, sizeof points / sizeof *points);
	CGPathCloseSubpath(cgPath);
	
	UIBezierPath * bezierPath = [UIBezierPath bezierPathWithCGPath:cgPath];
	CGPathRelease(cgPath);
	
	return bezierPath;
}

+ (void)getAxisAlignedArrowPoints:(CGPoint[3])points width:(CGFloat)width length:(CGFloat)length {
	points[0] = CGPointMake(0, width);
	points[1] = CGPointMake(length, 0);
	points[2] = CGPointMake(0, -width);
}

+ (CGAffineTransform)transformForStartPoint:(CGPoint)startPoint endPoint:(CGPoint)endPoint length:(CGFloat)length {
	CGFloat cosine = (endPoint.x - startPoint.x) / length;
	CGFloat sine = (endPoint.y - startPoint.y) / length;
	
	return (CGAffineTransform){ cosine, sine, -sine, cosine, startPoint.x, startPoint.y };
}

@end
