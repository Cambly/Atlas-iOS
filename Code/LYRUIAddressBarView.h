//
//  LYRUIAddressBarView.h
//  Pods
//
//  Created by Kevin Coleman on 10/30/14.
//
//

#import <UIKit/UIKit.h>
#import "LYRUIAddressBarTextView.h"

/**
 @abstract The `LYRUIAddressBarView handles displaying the contents of the `LYRUIAddressBarController`.
 */
@interface LYRUIAddressBarView : UIView

@property (nonatomic) LYRUIAddressBarTextView *addressBarTextView;

@property (nonatomic) UIButton *addContactsButton;

@end