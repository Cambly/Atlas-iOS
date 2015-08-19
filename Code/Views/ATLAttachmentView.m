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
@property (nonatomic) UIImageView *downloadView;

@end

@implementation ATLAttachmentView

const float DOWNLOAD_ICON_SIZE = 16.0f;
const float DOWNLOAD_ICON_PADDING = 8.0f;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _attachmentLabel = [[UILabel alloc] init];
        _attachmentLabel.numberOfLines = 1;
        _attachmentLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
        _attachmentLabel.userInteractionEnabled = YES;
        _attachmentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [_attachmentLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultHigh + 1 forAxis:UILayoutConstraintAxisHorizontal];
        [self addSubview:_attachmentLabel];
        
        _progressView = [[ATLProgressView alloc] initWithFrame:CGRectMake(0, 0, DOWNLOAD_ICON_SIZE * 2, DOWNLOAD_ICON_SIZE * 2)];
        _progressView.translatesAutoresizingMaskIntoConstraints = NO;
        _progressView.alpha = 0.0f;
        [self addSubview:_progressView];
        
        _downloadView = [[UIImageView alloc] init];
        _downloadView.image = [UIImage imageNamed:@"download"];
        _downloadView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_downloadView];
        
        [self configureAttachmentLabelConstraints];
        [self configureProgressViewConstraints];
        [self configureDownloadViewConstraints];
        
        _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleLabelTap:)];
        _tapGestureRecognizer.delegate = self;
        [self addGestureRecognizer:_tapGestureRecognizer];
    }
    return self;
}

- (void)updateWithAttachment:(LYRMessagePart *)attachment withName:(NSString *)filename
{
    // TODO(gar): cleaner formatting?
    self.filename = filename;
    
    NSDictionary *attributes;
    if (self.color == ATLDownloadIconColorBlack) {
        self.downloadView.image = [UIImage imageNamed:@"download"];
        attributes = @{NSForegroundColorAttributeName : [UIColor blackColor]};
    } else {
        self.downloadView.image = [UIImage imageNamed:@"download_white"];
        attributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};
    }
    self.attachmentLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:filename attributes:attributes];
    self.attachment = attachment;
}

- (void)handleLabelTap:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (self.attachment && (self.attachment.transferStatus == LYRContentTransferReadyForDownload)) {
        NSError *error;
        LYRProgress *progress = [self.attachment downloadContent:&error];
        if (!progress) {
            NSLog(@"failed to request for a content download from the UI with error=%@", error);
        } else {
            [progress setDelegate:self];
        }
        [self updateProgressIndicatorWithProgress:progress animated:NO];
    } else if (self.attachment && (self.attachment.transferStatus == LYRContentTransferDownloading)) {
        // Set self for delegation, if single image message part message
        // hasn't been downloaded yet, or is still downloading.
        LYRProgress *progress = self.attachment.progress;
        [progress setDelegate:self];
        [self updateProgressIndicatorWithProgress:progress animated:NO];
    } else {
        [self updateProgressIndicatorWithProgress:nil animated:YES];
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
        [self updateProgressIndicatorWithProgress:progress animated:YES];
        // After transfer completes, remove self for delegation.
        if (progress.fractionCompleted == 1.0f) {
            progress.delegate = nil;
            [self.delegate openAttachment:self.attachment filename:self.filename];
        }
    });
}

- (void)updateProgressIndicatorWithProgress:(LYRProgress *)progress animated:(BOOL)animated
{
    if (progress != nil) {
        [self.progressView setProgress:progress.fractionCompleted animated:animated];
    }

    [UIView animateWithDuration:animated ? 0.25f : 0.0f animations:^{
        _progressView.alpha = 1.0f;
        _downloadView.alpha = 0.0f;
    }];
}

- (void)configureAttachmentLabelConstraints
{
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_attachmentLabel attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_attachmentLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_attachmentLabel attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_attachmentLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:self attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0]];
}

- (void)configureProgressViewConstraints
{
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_attachmentLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-DOWNLOAD_ICON_PADDING]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:DOWNLOAD_ICON_SIZE]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_progressView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:DOWNLOAD_ICON_SIZE]];
}

- (void)configureDownloadViewConstraints
{
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_downloadView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_downloadView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:_attachmentLabel attribute:NSLayoutAttributeLeft multiplier:1.0 constant:-DOWNLOAD_ICON_PADDING]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_downloadView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_downloadView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:DOWNLOAD_ICON_SIZE]];
    [self addConstraint:[NSLayoutConstraint constraintWithItem:_downloadView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:DOWNLOAD_ICON_SIZE]];
}

@end
