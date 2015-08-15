//
//  ATLAttachmentView.m
//  Atlas
//
//  Created by Gar Higgins on 8/12/15.
//
//

#import "ATLAttachmentView.h"
#import "ATLProgressView.h"

CGFloat const ATLMessageBubbleAttachmentVerticalMargin = 4.0f;

@interface ATLAttachmentView () <LYRProgressDelegate, UIGestureRecognizerDelegate>

@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;

@property (nonatomic) NSString *filename;
@property (nonatomic) LYRMessagePart *attachment;
@property (nonatomic) ATLProgressView *progressView;

@end

@implementation ATLAttachmentView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _attachmentLabel = [[UILabel alloc] init];
        _attachmentLabel.numberOfLines = 1;
        _attachmentLabel.userInteractionEnabled = YES;
        _attachmentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_attachmentLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh + 1 forAxis:UILayoutConstraintAxisHorizontal];
        [self addSubview:_attachmentLabel];
        
        _progressView = [[ATLProgressView alloc] initWithFrame:CGRectMake(0, 0, 128.0f, 128.0f)];
        _progressView.translatesAutoresizingMaskIntoConstraints = NO;
        _progressView.alpha = 1.0f;
        [self addSubview:_progressView];
        
        [self configureAttachmentLabelConstraints];
        [self configureProgressViewConstraints];
        
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleLabelTap:)];
        _tapGestureRecognizer.delegate = self;
        [self.attachmentLabel addGestureRecognizer:_tapGestureRecognizer];
    }
    return self;
}

- (void)updateWithAttachment:(LYRMessagePart *)attachment withName:(NSString *)filename
{
    // TODO(gar): cleaner formatting?
    self.filename = filename;
    self.attachmentLabel.text = filename;
    self.attachment = attachment;
}

- (void)handleLabelTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.attachment && (self.attachment.transferStatus == LYRContentTransferReadyForDownload)) {
        NSError *error;
        LYRProgress *progress = [self.attachment downloadContent:&error];
        if (!progress) {
            NSLog(@"failed to request for a content download from the UI with error=%@", error);
        }
        [self updateProgressIndicatorWithProgress:0.0 visible:NO animated:NO];
    } else if (self.attachment && (self.attachment.transferStatus == LYRContentTransferDownloading)) {
        // Set self for delegation, if single image message part message
        // hasn't been downloaded yet, or is still downloading.
        LYRProgress *progress = self.attachment.progress;
        [progress setDelegate:self];
        [self updateProgressIndicatorWithProgress:progress.fractionCompleted visible:YES animated:NO];
    } else {
        [self updateProgressIndicatorWithProgress:1.0 visible:NO animated:YES];
        [self.delegate openAttachment:self.attachment filename:self.filename];
    }
}

#pragma mark - LYRProgress Delegate Implementation

- (void)progressDidChange:(LYRProgress *)progress
{
    // Queue UI updates onto the main thread, since LYRProgress performs
    // delegate callbacks from a background thread.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (progress.delegate == nil) {
            // Do not do any UI changes, if receiver has been removed.
            return;
        }
        BOOL progressCompleted = progress.fractionCompleted == 1.0f;
        [self updateProgressIndicatorWithProgress:progress.fractionCompleted visible:progressCompleted ? NO : YES animated:YES];
        // After transfer completes, remove self for delegation.
        if (progressCompleted) {
            progress.delegate = nil;
            [self.delegate openAttachment:self.attachment filename:self.filename];
        }
    });
}

- (void)updateProgressIndicatorWithProgress:(float)progress visible:(BOOL)visible animated:(BOOL)animated
{
    [self.progressView setProgress:progress animated:animated];
    [UIView animateWithDuration:animated ? 0.25f : 0.0f animations:^{
        self.progressView.alpha = visible ? 1.0f : 0.0f;
    }];
}

- (void)configureAttachmentLabelConstraints
{
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_attachmentLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_attachmentLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_attachmentLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_attachmentLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
}

- (void)configureProgressViewConstraints
{
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:64.0f]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:64.0f]];
}

@end
