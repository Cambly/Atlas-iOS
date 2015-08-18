//
//  ATLAttachmentView.h
//  Atlas
//
//  Created by Gar Higgins on 8/12/15.
//
//

#import <UIKit/UIKit.h>
#import <LayerKit/LayerKit.h>

extern CGFloat const ATLMessageBubbleAttachmentVerticalMargin;

/**
 @abstract The `ATLAttachmentViewDelegate` notifies its receiver when buttons have been
 tapped.
 */
@protocol ATLAttachmentViewDelegate <NSObject>

/**
 @abstract Notifies the receiver that the right accessory button was tapped.
 */
- (void)openAttachment:(LYRMessagePart *)attachment filename:(NSString *)filename;

@end

typedef NS_ENUM(NSUInteger, ATLDownloadIconColor) {
    ATLDownloadIconColorBlack,
    ATLDownloadIconColorWhite
};

/**
 @abstract The `ATLAttachmentView` is displayed inside of an ATLMessageBubbleView
 and when clicked, will download and open the attachment.
 */
@interface ATLAttachmentView : UIView

@property (nonatomic) ATLDownloadIconColor color;

@property (nonatomic) id<ATLAttachmentViewDelegate> delegate;

/**
 @abstract The label for the attachment
 */
@property (nonatomic) UILabel *attachmentLabel;

- (void)updateWithAttachment:(LYRMessagePart *)attachment withName:(NSString *)filename;

@end
