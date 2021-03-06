/*****
 * Tencent is pleased to support the open source community by making QMUI_iOS available.
 * Copyright (C) 2016-2019 THL A29 Limited, a Tencent company. All rights reserved.
 * Licensed under the MIT License (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 * http://opensource.org/licenses/MIT
 * Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
 *****/

//
//  UIButton+QMUI.m
//  qmui
//
//  Created by QMUI Team on 15/7/20.
//

#import "UIButton+QMUI.h"
#import "QMUICore.h"

@interface UIButton ()

@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSDictionary<NSAttributedStringKey, id> *> *qbt_titleAttributes;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, NSMutableDictionary<NSNumber *, NSNumber *> *> * qbt_customizeButtonPropDict;

@end

@implementation UIButton (QMUI)

QMUISynthesizeIdStrongProperty(qbt_titleAttributes, setQbt_titleAttributes)
QMUISynthesizeIdStrongProperty(qbt_customizeButtonPropDict, setQbt_customizeButtonPropDict)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL selectors[] = {
            @selector(setTitle:forState:),
            @selector(setTitleColor:forState:),
            @selector(setTitleShadowColor:forState:),
            @selector(setImage:forState:),
            @selector(setBackgroundImage:forState:),
            @selector(setAttributedTitle:forState:)
        };
        for (NSUInteger index = 0; index < sizeof(selectors) / sizeof(SEL); index++) {
            SEL originalSelector = selectors[index];
            SEL swizzledSelector = NSSelectorFromString([@"qbt_" stringByAppendingString:NSStringFromSelector(originalSelector)]);
            ExchangeImplementations([self class], originalSelector, swizzledSelector);
        }
    });
}

- (instancetype)qmui_initWithImage:(UIImage *)image title:(NSString *)title {
    BeginIgnoreClangWarning(-Wunused-value)
    [self init];
    EndIgnoreClangWarning
    [self setImage:image forState:UIControlStateNormal];
    [self setTitle:title forState:UIControlStateNormal];
    return self;
}

- (void)qmui_calculateHeightAfterSetAppearance {
    [self setTitle:@"测" forState:UIControlStateNormal];
    [self sizeToFit];
    [self setTitle:nil forState:UIControlStateNormal];
}

- (BOOL)qmui_hasCustomizedButtonPropForState:(UIControlState)state {
    if (self.qbt_customizeButtonPropDict) {
        return self.qbt_customizeButtonPropDict[@(state)].count > 0;
    }
    
    return NO;
}

- (BOOL)qmui_hasCustomizedButtonPropWithType:(QMUICustomizeButtonPropType)type forState:(UIControlState)state {
    if (self.qbt_customizeButtonPropDict && self.qbt_customizeButtonPropDict[@(state)]) {
        return [self.qbt_customizeButtonPropDict[@(state)][@(type)] boolValue];
    }
    
    return NO;
}

#pragma mark - Hook methods

- (void)qbt_setTitle:(NSString *)title forState:(UIControlState)state {
    [self qbt_setTitle:title forState:state];
    
    [self _markQMUICustomizeType:QMUICustomizeButtonPropTypeTitle forState:state value:title];
    
    if (!title || !self.qbt_titleAttributes.count) {
        return;
    }
    
    if (state == UIControlStateNormal) {
        [self.qbt_titleAttributes enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSDictionary * _Nonnull obj, BOOL * _Nonnull stop) {
            UIControlState state = [key unsignedIntegerValue];
            NSString *titleForState = [self titleForState:state];
            NSAttributedString *string = [[NSAttributedString alloc] initWithString:titleForState attributes:obj];
            [self setAttributedTitle:[self attributedStringWithEndKernRemoved:string] forState:state];
        }];
        return;
    }
    
    if ([self.qbt_titleAttributes objectForKey:@(state)]) {
        NSAttributedString *string = [[NSAttributedString alloc] initWithString:title attributes:self.qbt_titleAttributes[@(state)]];
        [self setAttributedTitle:[self attributedStringWithEndKernRemoved:string] forState:state];
        return;
    }
}

// 如果之前已经设置了此 state 下的文字颜色，则覆盖掉之前的颜色
- (void)qbt_setTitleColor:(UIColor *)color forState:(UIControlState)state {
    [self qbt_setTitleColor:color forState:state];
    
    [self _markQMUICustomizeType:QMUICustomizeButtonPropTypeTitleColor forState:state value:color];
    
    NSDictionary *attributes = self.qbt_titleAttributes[@(state)];
    if (attributes) {
        NSMutableDictionary *newAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
        newAttributes[NSForegroundColorAttributeName] = color;
        [self qmui_setTitleAttributes:[NSDictionary dictionaryWithDictionary:newAttributes] forState:state];
    }
}

- (void)qbt_setTitleShadowColor:(nullable UIColor *)color forState:(UIControlState)state {
    [self qbt_setTitleShadowColor:color forState:state];
    [self _markQMUICustomizeType:QMUICustomizeButtonPropTypeTitleShadowColor forState:state value:color];
}

- (void)qbt_setImage:(nullable UIImage *)image forState:(UIControlState)state {
    [self qbt_setImage:image forState:state];
    [self _markQMUICustomizeType:QMUICustomizeButtonPropTypeImage forState:state value:image];
}

- (void)qbt_setBackgroundImage:(nullable UIImage *)image forState:(UIControlState)state {
    [self qbt_setBackgroundImage:image forState:state];
    [self _markQMUICustomizeType:QMUICustomizeButtonPropTypeBackgroundImage forState:state value:image];
}

- (void)qbt_setAttributedTitle:(nullable NSAttributedString *)title forState:(UIControlState)state {
    [self qbt_setAttributedTitle:title forState:state];
    [self _markQMUICustomizeType:QMUICustomizeButtonPropTypeAttributedTitle forState:state value:title];
}

#pragma mark - Title Attributes

- (void)qmui_setTitleAttributes:(NSDictionary<NSAttributedStringKey,id> *)attributes forState:(UIControlState)state {
    if (!attributes) {
        [self.qbt_titleAttributes removeObjectForKey:@(state)];
        [self setAttributedTitle:nil forState:state];
        return;
    }
    
    if (!self.qbt_titleAttributes) {
        self.qbt_titleAttributes = [NSMutableDictionary dictionary];
    }
    
    // 如果传入的 attributes 没有包含文字颜色，则使用用户之前通过 setTitleColor:forState: 方法设置的颜色
    if (![attributes objectForKey:NSForegroundColorAttributeName]) {
        NSMutableDictionary *newAttributes = [NSMutableDictionary dictionaryWithDictionary:attributes];
        newAttributes[NSForegroundColorAttributeName] = [self titleColorForState:state];
        attributes = [NSDictionary dictionaryWithDictionary:newAttributes];
    }
    self.qbt_titleAttributes[@(state)] = attributes;
    
    // 确保调用此方法设置 attributes 之前已经通过 setTitle:forState: 设置的文字也能应用上新的 attributes
    NSString *originalText = [self titleForState:state];
    [self setTitle:originalText forState:state];
    
    // 一个系统的不好的特性（bug?）：如果你给 UIControlStateHighlighted（或者 normal 之外的任何 state）设置了包含 NSFont/NSKern/NSUnderlineAttributeName 之类的 attributedString ，但又仅用 setTitle:forState: 给 UIControlStateNormal 设置了普通的 string ，则按钮从 highlighted 切换回 normal 状态时，font 之类的属性依然会停留在 highlighted 时的状态
    // 为了解决这个问题，我们要确保一旦有 normal 之外的 state 通过设置 qbt_titleAttributes 属性而导致使用了 attributedString，则 normal 也必须使用 attributedString
    if (self.qbt_titleAttributes.count && !self.qbt_titleAttributes[@(UIControlStateNormal)]) {
        [self qmui_setTitleAttributes:@{} forState:UIControlStateNormal];
    }
}

// 去除最后一个字的 kern 效果
- (NSAttributedString *)attributedStringWithEndKernRemoved:(NSAttributedString *)string {
    if (!string || !string.length) {
        return string;
    }
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithAttributedString:string];
    [attributedString removeAttribute:NSKernAttributeName range:NSMakeRange(string.length - 1, 1)];
    return [[NSAttributedString alloc] initWithAttributedString:attributedString];
}

#pragma mark - customize state

- (void)_markQMUICustomizeType:(QMUICustomizeButtonPropType)type forState:(UIControlState)state value:(id)value {
    if (value) {
        [self _setQMUICustomizeType:type forState:state];
    } else {
        [self _removeQMUICustomizeType:type forState:state];
    }
}

- (void)_setQMUICustomizeType:(QMUICustomizeButtonPropType)type forState:(UIControlState)state {
    if (!self.qbt_customizeButtonPropDict) {
        self.qbt_customizeButtonPropDict = [NSMutableDictionary dictionary];
    }
    
    if (!self.qbt_customizeButtonPropDict[@(state)]) {
        self.qbt_customizeButtonPropDict[@(state)] = [NSMutableDictionary dictionary];
    }
    
    self.qbt_customizeButtonPropDict[@(state)][@(type)] = @(YES);
}

- (void)_removeQMUICustomizeType:(QMUICustomizeButtonPropType)type forState:(UIControlState)state {
    if (!self.qbt_customizeButtonPropDict || !self.qbt_customizeButtonPropDict[@(state)]) {
        return;
    }
    
    [self.qbt_customizeButtonPropDict[@(state)] removeObjectForKey:@(type)];
}

@end
