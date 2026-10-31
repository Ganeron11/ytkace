#import "../../YTKACE.h"
#import "../../Runtime/Hooking.h"
#import "../../Runtime/Preferences.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>
#include <stdint.h>
#include <string.h>

static IMP OriginalShouldBlockUpgradeDialog;
static IMP OriginalAdShieldSignals;
static IMP OriginalAdShieldSignalsWithoutIDFA;
static IMP OriginalDataSignals;
static IMP OriginalDataSignalsWithoutIDFA;
static IMP OriginalAdsDecorateContext;
static IMP OriginalAccountAdsDecorateContext;
static IMP OriginalPlayerAdsArray;
static IMP OriginalAdSlotsArray;
static IMP OriginalAdPlacementsArray;
static IMP OriginalAdBreakParams;
static IMP OriginalAdNextParams;
static IMP OriginalAdParams;
static IMP OriginalEnableSkippableAd;
static IMP OriginalMDXSessionImplAdPlaying;
static IMP OriginalMDXSessionAdPlaying;
static IMP OriginalIsPlayingAd;
static IMP OriginalIsPlayingAdSurvey;
static IMP OriginalIsPlayingAdIntro;
static IMP OriginalCreateAdsPlaybackCoordinator;
static IMP OriginalReelContentModel;
static IMP OriginalInfiniteReelContentModel;
static IMP OriginalReelShouldDisplay;
static IMP OriginalCompanionAd;
static IMP OriginalHasCompanionAdRenderer;
static IMP OriginalHasAppPromoCompanionAdRenderer;
static IMP OriginalHasShoppingCompanionAdRenderer;
static IMP OriginalCellLayout;
static IMP OriginalCellReuse;
static const void *YTKACECollapsedCellAssociation =
    &YTKACECollapsedCellAssociation;

static id YTKACECallObjectGetter(IMP implementation, id receiver, SEL selector) {
    return implementation == NULL
        ? nil
        : ((id (*)(id, SEL))implementation)(receiver, selector);
}

static BOOL YTKACECallBooleanGetter(IMP implementation, id receiver, SEL selector) {
    return implementation != NULL &&
        ((BOOL (*)(id, SEL))implementation)(receiver, selector);
}

static BOOL YTKACEShouldBlockUpgradeDialog(id receiver, SEL selector) {
    return YTKACEFeatureEnabled(YTKACENoAdsKey)
        ? YES
        : YTKACECallBooleanGetter(OriginalShouldBlockUpgradeDialog, receiver, selector);
}

static id YTKACEEmptyDictionary(IMP original, id receiver, SEL selector) {
    return YTKACEFeatureEnabled(YTKACENoAdsKey)
        ? @{}
        : YTKACECallObjectGetter(original, receiver, selector);
}

static id YTKACEAdShieldSignals(id receiver, SEL selector) {
    return YTKACEEmptyDictionary(OriginalAdShieldSignals, receiver, selector);
}

static id YTKACEAdShieldSignalsWithoutIDFA(id receiver, SEL selector) {
    return YTKACEEmptyDictionary(OriginalAdShieldSignalsWithoutIDFA, receiver, selector);
}

static id YTKACEDataSignals(id receiver, SEL selector) {
    return YTKACEEmptyDictionary(OriginalDataSignals, receiver, selector);
}

static id YTKACEDataSignalsWithoutIDFA(id receiver, SEL selector) {
    return YTKACEEmptyDictionary(OriginalDataSignalsWithoutIDFA, receiver, selector);
}

static void YTKACEAdsDecorateContext(id receiver, SEL selector, id context) {
    if (!YTKACEFeatureEnabled(YTKACENoAdsKey) && OriginalAdsDecorateContext != NULL) {
        ((void (*)(id, SEL, id))OriginalAdsDecorateContext)(receiver, selector, context);
    }
}

static void YTKACEAccountAdsDecorateContext(id receiver, SEL selector, id context) {
    if (!YTKACEFeatureEnabled(YTKACENoAdsKey) &&
        OriginalAccountAdsDecorateContext != NULL) {
        ((void (*)(id, SEL, id))OriginalAccountAdsDecorateContext)(
            receiver,
            selector,
            context
        );
    }
}

static id YTKACEPlayerAdsArray(id receiver, SEL selector) {
    return YTKACEFeatureEnabled(YTKACENoAdsKey)
        ? [NSMutableArray array]
        : YTKACECallObjectGetter(OriginalPlayerAdsArray, receiver, selector);
}

static id YTKACEAdSlotsArray(id receiver, SEL selector) {
    return YTKACEFeatureEnabled(YTKACENoAdsKey)
        ? [NSMutableArray array]
        : YTKACECallObjectGetter(OriginalAdSlotsArray, receiver, selector);
}

static id YTKACEAdPlacementsArray(id receiver, SEL selector) {
    return YTKACEFeatureEnabled(YTKACENoAdsKey)
        ? [NSMutableArray array]
        : YTKACECallObjectGetter(OriginalAdPlacementsArray, receiver, selector);
}

static id YTKACENilParameter(IMP original, id receiver, SEL selector) {
    return YTKACEFeatureEnabled(YTKACENoAdsKey)
        ? nil
        : YTKACECallObjectGetter(original, receiver, selector);
}

static id YTKACEAdBreakParams(id receiver, SEL selector) {
    return YTKACENilParameter(OriginalAdBreakParams, receiver, selector);
}

static id YTKACEAdNextParams(id receiver, SEL selector) {
    return YTKACENilParameter(OriginalAdNextParams, receiver, selector);
}

static id YTKACEAdParams(id receiver, SEL selector) {
    return YTKACENilParameter(OriginalAdParams, receiver, selector);
}

static BOOL YTKACEEnableSkippableAd(id receiver, SEL selector) {
    return YTKACEFeatureEnabled(YTKACENoAdsKey)
        ? YES
        : YTKACECallBooleanGetter(OriginalEnableSkippableAd, receiver, selector);
}

static void YTKACEMDXSessionImplAdPlaying(id receiver,
                                          SEL selector,
                                          uintptr_t value) {
    if (!YTKACEFeatureEnabled(YTKACENoAdsKey) &&
        OriginalMDXSessionImplAdPlaying != NULL) {
        ((void (*)(id, SEL, uintptr_t))OriginalMDXSessionImplAdPlaying)(
            receiver,
            selector,
            value
        );
    }
}

static void YTKACEMDXSessionAdPlaying(id receiver,
                                      SEL selector,
                                      uintptr_t value) {
    if (!YTKACEFeatureEnabled(YTKACENoAdsKey) && OriginalMDXSessionAdPlaying != NULL) {
        ((void (*)(id, SEL, uintptr_t))OriginalMDXSessionAdPlaying)(
            receiver,
            selector,
            value
        );
    }
}

static BOOL YTKACENotPlayingAd(IMP original, id receiver, SEL selector) {
    return YTKACEFeatureEnabled(YTKACENoAdsKey)
        ? NO
        : YTKACECallBooleanGetter(original, receiver, selector);
}

static BOOL YTKACEIsPlayingAd(id receiver, SEL selector) {
    return YTKACENotPlayingAd(OriginalIsPlayingAd, receiver, selector);
}

static BOOL YTKACEIsPlayingAdSurvey(id receiver, SEL selector) {
    return YTKACENotPlayingAd(OriginalIsPlayingAdSurvey, receiver, selector);
}

static BOOL YTKACEIsPlayingAdIntro(id receiver, SEL selector) {
    return YTKACENotPlayingAd(OriginalIsPlayingAdIntro, receiver, selector);
}

static id YTKACENoAdsPlaybackCoordinator(id receiver, SEL selector) {
    id coordinator = YTKACECallObjectGetter(
        OriginalCreateAdsPlaybackCoordinator,
        receiver,
        selector
    );
    return YTKACEFeatureEnabled(YTKACENoAdsKey) ? nil : coordinator;
}

static id YTKACEFilterReelModel(IMP original,
                                id receiver,
                                SEL selector,
                                id entry) {
    if (original == NULL) {
        return nil;
    }
    id model = ((id (*)(id, SEL, id))original)(receiver, selector, entry);
    if (!YTKACEFeatureEnabled(YTKACENoAdsKey) || model == nil) {
        return model;
    }
    SEL videoTypeSelector = NSSelectorFromString(@"videoType");
    if (![model respondsToSelector:videoTypeSelector]) {
        return model;
    }
    NSInteger videoType = ((NSInteger (*)(id, SEL))objc_msgSend)(
        model,
        videoTypeSelector
    );
    return videoType == 3 ? nil : model;
}

static id YTKACEReelContentModel(id receiver, SEL selector, id entry) {
    return YTKACEFilterReelModel(
        OriginalReelContentModel,
        receiver,
        selector,
        entry
    );
}

static id YTKACEInfiniteReelContentModel(id receiver, SEL selector, id entry) {
    return YTKACEFilterReelModel(
        OriginalInfiniteReelContentModel,
        receiver,
        selector,
        entry
    );
}

static id YTKACEObjectValue(id object, NSString *selectorName) {
    if (object == nil) return nil;
    SEL selector = NSSelectorFromString(selectorName);
    if (![object respondsToSelector:selector]) return nil;
    @try {
        return ((id (*)(id, SEL))objc_msgSend)(object, selector);
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static BOOL YTKACEObjectBool(id object, NSString *selectorName) {
    if (object == nil) return NO;
    SEL selector = NSSelectorFromString(selectorName);
    if (![object respondsToSelector:selector]) return NO;
    @try {
        return ((BOOL (*)(id, SEL))objc_msgSend)(object, selector);
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

static BOOL YTKACEReelObjectLooksLikeAd(id object, NSUInteger depth) {
    if (object == nil || depth > 3) return NO;

    NSString *className = NSStringFromClass([object class]).lowercaseString;
    if ([className containsString:@"nonvideoad"] ||
        [className containsString:@"reelad"] ||
        [className containsString:@"adselection"] ||
        [className containsString:@"miniappad"]) {
        return YES;
    }

    for (NSString *selectorName in @[
        @"isAd", @"isAdVideo", @"isVideoAd", @"hasAdLoggingData"
    ]) {
        if (YTKACEObjectBool(object, selectorName)) return YES;
    }

    SEL videoTypeSelector = NSSelectorFromString(@"videoType");
    if ([object respondsToSelector:videoTypeSelector]) {
        NSInteger videoType = ((NSInteger (*)(id, SEL))objc_msgSend)(
            object,
            videoTypeSelector
        );
        if (videoType == 3) return YES;
    }

    for (NSString *selectorName in @[
        @"adLoggingData",
        @"adSlotRenderer",
        @"reelNonVideoAdRenderer",
        @"nonVideoAdRenderer",
        @"sequenceItemAdSelectionRenderer"
    ]) {
        if (YTKACEObjectValue(object, selectorName) != nil) return YES;
    }

    for (NSString *selectorName in @[
        @"reelModel", @"command", @"watchModel", @"parentWatchModel"
    ]) {
        id child = YTKACEObjectValue(object, selectorName);
        if (child != object && YTKACEReelObjectLooksLikeAd(child, depth + 1)) {
            return YES;
        }
    }
    return NO;
}

static BOOL YTKACEReelShouldDisplay(id receiver, SEL selector) {
    BOOL shouldDisplay = OriginalReelShouldDisplay == NULL ||
        ((BOOL (*)(id, SEL))OriginalReelShouldDisplay)(receiver, selector);
    if (!shouldDisplay || !YTKACEFeatureEnabled(YTKACENoAdsKey)) {
        return shouldDisplay;
    }
    if (YTKACEObjectValue(receiver, @"nonVideoContentModel") != nil) {
        return NO;
    }
    return !YTKACEReelObjectLooksLikeAd(receiver, 0);
}

typedef struct {
    NSUInteger unit;
    CGFloat value;
} YTKACEASDimension;

static void YTKACECollapseCellNode(id node) {
    SEL styleSelector = NSSelectorFromString(@"style");
    if ([node respondsToSelector:styleSelector]) {
        id style = ((id (*)(id, SEL))objc_msgSend)(node, styleSelector);
        YTKACEASDimension zero = {1, 0.0};
        for (NSString *name in @[@"setHeight:", @"setMaxHeight:"]) {
            SEL selector = NSSelectorFromString(name);
            if (![style respondsToSelector:selector]) continue;
            ((void (*)(id, SEL, YTKACEASDimension))objc_msgSend)(
                style, selector, zero);
        }
    }
    for (NSString *name in @[@"invalidateCalculatedLayout", @"setNeedsLayout"]) {
        SEL selector = NSSelectorFromString(name);
        if ([node respondsToSelector:selector]) {
            ((void (*)(id, SEL))objc_msgSend)(node, selector);
        }
    }
}

static void YTKACECollapseCell(UIView *cell) {
    CGRect frame = cell.frame;
    if (frame.size.height == 0.0 && cell.hidden) return;
    frame.size.height = 0.0;
    cell.frame = frame;
    cell.hidden = YES;
    cell.userInteractionEnabled = NO;
    for (UIView *ancestor = cell.superview; ancestor != nil;
         ancestor = ancestor.superview) {
        if ([ancestor isKindOfClass:UICollectionView.class]) {
            [((UICollectionView *)ancestor).collectionViewLayout invalidateLayout];
            break;
        }
    }
}

static void YTKACEHandleCollapsedCellLayout(UIView *cell) {
    if (![objc_getAssociatedObject(cell, YTKACECollapsedCellAssociation) boolValue]) return;
    YTKACECollapseCell(cell);
}

static void YTKACEHandleCollapsedCellReuse(UIView *cell) {
    if (![objc_getAssociatedObject(cell, YTKACECollapsedCellAssociation) boolValue]) return;
    objc_setAssociatedObject(cell, YTKACECollapsedCellAssociation, nil,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    cell.hidden = NO;
    cell.userInteractionEnabled = YES;
}

void YTKACEHandleAdDisplayView(UIView *view) {
    (void)view;
}

void YTKACEHandleAdCellLayout(UIView *cell) {
    YTKACEHandleCollapsedCellLayout(cell);
}

void YTKACEHandleAdCellReuse(UIView *cell) {
    YTKACEHandleCollapsedCellReuse(cell);
}

void YTKACECollapseHostCell(UIView *view) {
    if (view == nil) return;
    UIView *cell = nil;
    for (UIView *ancestor = view; ancestor != nil;
         ancestor = ancestor.superview) {
        if ([ancestor isKindOfClass:UICollectionViewCell.class] ||
            [NSStringFromClass([ancestor class]) hasSuffix:@"CollectionViewCell"]) {
            cell = ancestor;
            break;
        }
    }
    view.hidden = YES;
    if (cell == nil) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [view removeFromSuperview];
        });
        return;
    }
    objc_setAssociatedObject(cell, YTKACECollapsedCellAssociation, @YES,
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    YTKACECollapseCell(cell);
    SEL nodeSelector = NSSelectorFromString(@"node");
    if ([cell respondsToSelector:nodeSelector]) {
        id node = ((id (*)(id, SEL))objc_msgSend)(cell, nodeSelector);
        if (node != nil) {
            YTKACECollapseCellNode(node);
        }
    }
}

typedef struct {
    const char *bytes;
    NSUInteger length;
} YTKACEBytePattern;

#define YTKACE_BYTE_PATTERN(value) { value, sizeof(value) - 1 }

static const YTKACEBytePattern YTKACEAdWireMarkers[] = {
    YTKACE_BYTE_PATTERN("eml.ad"),
    YTKACE_BYTE_PATTERN("eml_ad"),
    YTKACE_BYTE_PATTERN("feed_ad_metadata"),
    YTKACE_BYTE_PATTERN("text_search_ad"),
    YTKACE_BYTE_PATTERN("text_image_button_layout"),
    YTKACE_BYTE_PATTERN("brand_promo"),
    YTKACE_BYTE_PATTERN("product_item"),
    YTKACE_BYTE_PATTERN("product_carousel"),
    YTKACE_BYTE_PATTERN("product_engagement_panel"),
    YTKACE_BYTE_PATTERN("shopping_ad_info_card"),
};

static const uint64_t YTKACEAdFieldNumbers[] = {
    424701016,
    55514441,
    73920376,
    82182324,
    93065129,
    137341759,
    137341794,
    150805198,
    150805689,
    157152263,
    157152273,
    157152280,
    157152285,
    157152291,
    157152292,
    171071888,
    175333548,
    175608736,
    191960355,
    194442374,
    194442375,
    196922251,
};

static const NSUInteger YTKACEAdFieldNumberCount =
    sizeof(YTKACEAdFieldNumbers) / sizeof(YTKACEAdFieldNumbers[0]);
static const uint64_t YTKACEItemSectionRendererFieldNumber = 50195462;

typedef NS_ENUM(NSUInteger, YTKACEWireContext) {
    YTKACEWireContextGeneric = 0,
    YTKACEWireContextItemSection,
};

typedef struct {
    BOOL changed;
    BOOL hadContent;
    BOOL keptContent;
} YTKACEWireResult;

static NSUInteger YTKACEWireWriteVarint(uint64_t value, uint8_t *buffer) {
    NSUInteger length = 0;
    while (value > 0x7F) {
        buffer[length++] = (uint8_t)((value & 0x7F) | 0x80);
        value >>= 7;
    }
    buffer[length++] = (uint8_t)value;
    return length;
}

static BOOL YTKACEWireReadVarint(const uint8_t *bytes,
                                 NSUInteger length,
                                 NSUInteger *offset,
                                 uint64_t *value) {
    uint64_t result = 0;
    NSUInteger shift = 0;
    NSUInteger position = *offset;
    while (position < length) {
        uint8_t byte = bytes[position++];
        if (shift > 63) return NO;
        result |= ((uint64_t)(byte & 0x7F)) << shift;
        if ((byte & 0x80) == 0) {
            *offset = position;
            *value = result;
            return YES;
        }
        shift += 7;
    }
    return NO;
}

static BOOL YTKACEWireContainsBytes(const uint8_t *bytes,
                                    NSUInteger length,
                                    const uint8_t *needle,
                                    NSUInteger needleLength) {
    if (needleLength == 0 || length < needleLength) return NO;
    NSUInteger limit = length - needleLength;
    for (NSUInteger index = 0; index <= limit; index++) {
        if (bytes[index] != needle[0]) continue;
        if (memcmp(bytes + index, needle, needleLength) == 0) return YES;
    }
    return NO;
}

static BOOL YTKACEWireContainsAdMarkerBytes(const uint8_t *bytes,
                                            NSUInteger length) {
    if (bytes == NULL || length == 0) return NO;
    NSUInteger count = sizeof(YTKACEAdWireMarkers) /
        sizeof(YTKACEAdWireMarkers[0]);
    for (NSUInteger index = 0; index < count; index++) {
        const YTKACEBytePattern *pattern = &YTKACEAdWireMarkers[index];
        if (YTKACEWireContainsBytes(bytes, length,
                                    (const uint8_t *)pattern->bytes,
                                    pattern->length)) {
            return YES;
        }
    }
    return NO;
}

static BOOL YTKACEWireMayContainAdBytes(const uint8_t *bytes,
                                        NSUInteger length) {
    if (bytes == NULL || length < 2) return NO;
    if (YTKACEWireContainsAdMarkerBytes(bytes, length)) return YES;
    for (NSUInteger index = 0; index < YTKACEAdFieldNumberCount; index++) {
        uint8_t key[10];
        NSUInteger keyLength = YTKACEWireWriteVarint(
            (YTKACEAdFieldNumbers[index] << 3) | 2,
            key);
        if (YTKACEWireContainsBytes(bytes, length, key, keyLength)) {
            return YES;
        }
    }
    return NO;
}

static BOOL YTKACEIsAdFieldNumber(uint64_t fieldNumber) {
    for (NSUInteger index = 0; index < YTKACEAdFieldNumberCount; index++) {
        if (YTKACEAdFieldNumbers[index] == fieldNumber) return YES;
    }
    return NO;
}

static NSData *YTKACEWireFilterBytes(const uint8_t *bytes,
                                     NSUInteger length,
                                     YTKACEWireContext context,
                                     NSUInteger depth,
                                     YTKACEWireResult *result) {
    if (result == NULL) return nil;
    result->changed = NO;
    result->hadContent = NO;
    result->keptContent = NO;
    if (bytes == NULL || length == 0 || depth > 32) return nil;
    NSMutableData *output = [NSMutableData dataWithCapacity:length];
    NSUInteger offset = 0;
    while (offset < length) {
        NSUInteger fieldStart = offset;
        uint64_t key = 0;
        if (!YTKACEWireReadVarint(bytes, length, &offset, &key)) return nil;
        uint64_t fieldNumber = key >> 3;
        uint32_t wireType = (uint32_t)(key & 0x07);
        if (fieldNumber == 0 || fieldNumber > 536870911) return nil;
        NSUInteger payloadStart = offset;
        NSUInteger payloadLength = 0;
        switch (wireType) {
            case 0: {
                uint64_t ignored = 0;
                if (!YTKACEWireReadVarint(bytes, length, &offset, &ignored)) {
                    return nil;
                }
                break;
            }
            case 1:
                if (length - offset < 8) return nil;
                offset += 8;
                break;
            case 2: {
                uint64_t encodedLength = 0;
                if (!YTKACEWireReadVarint(bytes, length, &offset,
                                          &encodedLength)) {
                    return nil;
                }
                if (encodedLength > (uint64_t)(length - offset)) return nil;
                payloadStart = offset;
                payloadLength = (NSUInteger)encodedLength;
                offset += payloadLength;
                break;
            }
            case 5:
                if (length - offset < 4) return nil;
                offset += 4;
                break;
            default:
                return nil;
        }
        NSUInteger fieldEnd = offset;
        if (fieldEnd > length) return nil;
        if (YTKACEIsAdFieldNumber(fieldNumber)) {
            result->changed = YES;
            continue;
        }
        if (wireType != 2) {
            [output appendBytes:bytes + fieldStart length:fieldEnd - fieldStart];
            continue;
        }
        if (context == YTKACEWireContextItemSection && fieldNumber == 1) {
            result->hadContent = YES;
            if (YTKACEWireContainsAdMarkerBytes(bytes + payloadStart,
                                                payloadLength)) {
                result->changed = YES;
                continue;
            }
            YTKACEWireResult childResult = {0};
            YTKACEWireFilterBytes(bytes + payloadStart,
                                  payloadLength,
                                  YTKACEWireContextGeneric,
                                  depth + 1,
                                  &childResult);
            if (childResult.changed) {
                result->changed = YES;
                continue;
            }
            result->keptContent = YES;
            [output appendBytes:bytes + fieldStart length:fieldEnd - fieldStart];
            continue;
        }
        if (YTKACEWireMayContainAdBytes(bytes + payloadStart, payloadLength)) {
            YTKACEWireContext childContext =
                fieldNumber == YTKACEItemSectionRendererFieldNumber
                    ? YTKACEWireContextItemSection
                    : YTKACEWireContextGeneric;
            YTKACEWireResult childResult = {0};
            NSData *child = YTKACEWireFilterBytes(bytes + payloadStart,
                                                  payloadLength,
                                                  childContext,
                                                  depth + 1,
                                                  &childResult);
            if (childResult.changed) {
                if (fieldNumber == YTKACEItemSectionRendererFieldNumber &&
                    childResult.hadContent &&
                    !childResult.keptContent) {
                    result->changed = YES;
                    continue;
                }
                if (child.length == 0) {
                    result->changed = YES;
                    continue;
                }
                uint8_t keyBytes[10];
                NSUInteger keyLength = YTKACEWireWriteVarint(key, keyBytes);
                uint8_t lengthBytes[10];
                NSUInteger lengthLength = YTKACEWireWriteVarint(
                    child.length,
                    lengthBytes);
                [output appendBytes:keyBytes length:keyLength];
                [output appendBytes:lengthBytes length:lengthLength];
                [output appendData:child];
                result->changed = YES;
                continue;
            }
        }
        [output appendBytes:bytes + fieldStart length:fieldEnd - fieldStart];
    }
    return result->changed ? output : nil;
}

static NSData *YTKACEStripAdFieldsFromData(NSData *data) {
    if (![data isKindOfClass:NSData.class] || data.length == 0) return data;
    if (!YTKACEWireMayContainAdBytes(data.bytes, data.length)) return data;
    YTKACEWireResult result = {0};
    NSData *filtered = YTKACEWireFilterBytes(data.bytes,
                                             data.length,
                                             YTKACEWireContextGeneric,
                                             0,
                                             &result);
    if (!result.changed) return data;
    return filtered;
}

static id YTKACESectionWithFilteredBytes(id section) {
    if (section == nil) return nil;
    NSData *data = YTKACEObjectValue(section, @"data");
    if (![data isKindOfClass:NSData.class] || data.length == 0) return section;
    NSData *filtered = YTKACEStripAdFieldsFromData(data);
    if (filtered == data) return section;
    if (filtered.length == 0) return nil;
    Class sectionClass = [section class];
    SEL parseSelector = NSSelectorFromString(@"parseFromData:error:");
    id rebuilt = ((id (*)(id, SEL, id, NSError **))objc_msgSend)(
        sectionClass,
        parseSelector,
        filtered,
        NULL);
    if (rebuilt == nil) return nil;
    SEL clearSelector = NSSelectorFromString(@"clear");
    SEL mergeSelector = NSSelectorFromString(@"mergeFrom:");
    ((void (*)(id, SEL))objc_msgSend)(section, clearSelector);
    ((void (*)(id, SEL, id))objc_msgSend)(section, mergeSelector, rebuilt);
    return section;
}

NSArray *YTKACEFilterAdSections(NSArray *sections) {
    if (!YTKACEFeatureEnabled(YTKACENoAdsKey) ||
        ![sections isKindOfClass:NSArray.class] || sections.count == 0) {
        return sections;
    }
    NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:sections.count];
    for (id section in sections) {
        id filteredSection = YTKACESectionWithFilteredBytes(section);
        if (filteredSection != nil) [filtered addObject:filteredSection];
    }
    return filtered.count == sections.count ? sections : filtered;
}

static id YTKACENoCompanionAd(id receiver, SEL selector) {
    return YTKACEFeatureEnabled(YTKACENoAdsKey)
        ? nil
        : YTKACECallObjectGetter(OriginalCompanionAd, receiver, selector);
}

static BOOL YTKACENoCompanionFlag(IMP original, id receiver, SEL selector) {
    return YTKACEFeatureEnabled(YTKACENoAdsKey)
        ? NO
        : YTKACECallBooleanGetter(original, receiver, selector);
}

static BOOL YTKACEHasCompanionAdRenderer(id receiver, SEL selector) {
    return YTKACENoCompanionFlag(
        OriginalHasCompanionAdRenderer,
        receiver,
        selector
    );
}

static BOOL YTKACEHasAppPromoCompanionAdRenderer(id receiver, SEL selector) {
    return YTKACENoCompanionFlag(
        OriginalHasAppPromoCompanionAdRenderer,
        receiver,
        selector
    );
}

static BOOL YTKACEHasShoppingCompanionAdRenderer(id receiver, SEL selector) {
    return YTKACENoCompanionFlag(
        OriginalHasShoppingCompanionAdRenderer,
        receiver,
        selector
    );
}

static void YTKACEInstallObjectHookOrMethod(NSString *className,
                                            NSString *selectorName,
                                            IMP replacement,
                                            IMP *originalStorage) {
    if (!YTKACEInstallInstanceHook(
            className,
            selectorName,
            replacement,
            originalStorage
        )) {
        YTKACEAddInstanceMethod(className, selectorName, replacement, "@@:");
    }
}

static void YTKACEInstallBooleanHookOrMethod(NSString *className,
                                             NSString *selectorName,
                                             IMP replacement,
                                             IMP *originalStorage) {
    if (!YTKACEInstallInstanceHook(
            className,
            selectorName,
            replacement,
            originalStorage
        )) {
        YTKACEAddInstanceMethod(className, selectorName, replacement, "B@:");
    }
}

static void YTKACECellLayoutSubviews(UIView *receiver, SEL selector) {
    if (OriginalCellLayout != NULL) {
        ((void (*)(id, SEL))OriginalCellLayout)(receiver, selector);
    }
    YTKACEHandleCollapsedCellLayout(receiver);
}

static void YTKACECellPrepareForReuse(UIView *receiver, SEL selector) {
    YTKACEHandleCollapsedCellReuse(receiver);
    if (OriginalCellReuse != NULL) {
        ((void (*)(id, SEL))OriginalCellReuse)(receiver, selector);
    }
}

void YTKACEInstallAdsHooks(void) {
    YTKACEInstallInstanceHook(@"YTGlobalConfig",
                              @"shouldBlockUpgradeDialog",
                              (IMP)YTKACEShouldBlockUpgradeDialog,
                              &OriginalShouldBlockUpgradeDialog);
    YTKACEInstallClassHook(@"YTAdShieldUtils",
                           @"spamSignalsDictionary",
                           (IMP)YTKACEAdShieldSignals,
                           &OriginalAdShieldSignals);
    YTKACEInstallClassHook(@"YTAdShieldUtils",
                           @"spamSignalsDictionaryWithoutIDFA",
                           (IMP)YTKACEAdShieldSignalsWithoutIDFA,
                           &OriginalAdShieldSignalsWithoutIDFA);
    YTKACEInstallClassHook(@"YTDataUtils",
                           @"spamSignalsDictionary",
                           (IMP)YTKACEDataSignals,
                           &OriginalDataSignals);
    YTKACEInstallClassHook(@"YTDataUtils",
                           @"spamSignalsDictionaryWithoutIDFA",
                           (IMP)YTKACEDataSignalsWithoutIDFA,
                           &OriginalDataSignalsWithoutIDFA);
    YTKACEInstallInstanceHook(@"YTAdsInnerTubeContextDecorator",
                              @"decorateContext:",
                              (IMP)YTKACEAdsDecorateContext,
                              &OriginalAdsDecorateContext);
    YTKACEInstallInstanceHook(@"YTAccountScopedAdsInnerTubeContextDecorator",
                              @"decorateContext:",
                              (IMP)YTKACEAccountAdsDecorateContext,
                              &OriginalAccountAdsDecorateContext);

    YTKACEInstallObjectHookOrMethod(@"YTIPlayerResponse",
                                    @"playerAdsArray",
                                    (IMP)YTKACEPlayerAdsArray,
                                    &OriginalPlayerAdsArray);
    YTKACEInstallObjectHookOrMethod(@"YTIPlayerResponse",
                                    @"adSlotsArray",
                                    (IMP)YTKACEAdSlotsArray,
                                    &OriginalAdSlotsArray);
    YTKACEInstallObjectHookOrMethod(@"YTIPlayerResponse",
                                    @"adPlacementsArray",
                                    (IMP)YTKACEAdPlacementsArray,
                                    &OriginalAdPlacementsArray);
    YTKACEInstallInstanceHook(@"YTIPlayerResponse",
                              @"adBreakParams",
                              (IMP)YTKACEAdBreakParams,
                              &OriginalAdBreakParams);
    YTKACEInstallInstanceHook(@"YTIPlayerResponse",
                              @"adNextParams",
                              (IMP)YTKACEAdNextParams,
                              &OriginalAdNextParams);
    YTKACEInstallInstanceHook(@"YTIPlayerResponse",
                              @"adParams",
                              (IMP)YTKACEAdParams,
                              &OriginalAdParams);
    YTKACEInstallBooleanHookOrMethod(@"YTIClientMdxGlobalConfig",
                                     @"enableSkippableAd",
                                     (IMP)YTKACEEnableSkippableAd,
                                     &OriginalEnableSkippableAd);

    YTKACEInstallInstanceHook(@"MDXSessionImpl",
                              @"adPlaying:",
                              (IMP)YTKACEMDXSessionImplAdPlaying,
                              &OriginalMDXSessionImplAdPlaying);
    YTKACEInstallInstanceHook(@"MDXSession",
                              @"adPlaying:",
                              (IMP)YTKACEMDXSessionAdPlaying,
                              &OriginalMDXSessionAdPlaying);
    YTKACEInstallInstanceHook(@"YTLocalPlaybackController",
                              @"isPlayingAd",
                              (IMP)YTKACEIsPlayingAd,
                              &OriginalIsPlayingAd);
    YTKACEInstallInstanceHook(@"YTLocalPlaybackController",
                              @"isPlayingAdSurvey",
                              (IMP)YTKACEIsPlayingAdSurvey,
                              &OriginalIsPlayingAdSurvey);
    YTKACEInstallInstanceHook(@"YTLocalPlaybackController",
                              @"isPlayingAdIntro",
                              (IMP)YTKACEIsPlayingAdIntro,
                              &OriginalIsPlayingAdIntro);
    YTKACEInstallInstanceHook(@"YTLocalPlaybackController",
                              @"createAdsPlaybackCoordinator",
                              (IMP)YTKACENoAdsPlaybackCoordinator,
                              &OriginalCreateAdsPlaybackCoordinator);

    YTKACEInstallInstanceHook(@"YTReelDataSource",
                              @"makeContentModelForEntry:",
                              (IMP)YTKACEReelContentModel,
                              &OriginalReelContentModel);
    YTKACEInstallInstanceHook(@"YTReelInfinitePlaybackDataSource",
                              @"makeContentModelForEntry:",
                              (IMP)YTKACEInfiniteReelContentModel,
                              &OriginalInfiniteReelContentModel);
    YTKACEInstallInstanceHook(@"YTReelContentModel",
                              @"shouldDisplay",
                              (IMP)YTKACEReelShouldDisplay,
                              &OriginalReelShouldDisplay);
    YTKACEInstallInstanceHook(@"YTIElementRenderer",
                              @"companionAd",
                              (IMP)YTKACENoCompanionAd,
                              &OriginalCompanionAd);
    YTKACEInstallInstanceHook(@"YTIElementRenderer",
                              @"hasCompanionAdRenderer",
                              (IMP)YTKACEHasCompanionAdRenderer,
                              &OriginalHasCompanionAdRenderer);
    YTKACEInstallInstanceHook(@"YTIElementRenderer",
                              @"hasAppPromoCompanionAdRenderer",
                              (IMP)YTKACEHasAppPromoCompanionAdRenderer,
                              &OriginalHasAppPromoCompanionAdRenderer);
    YTKACEInstallInstanceHook(@"YTIElementRenderer",
                              @"hasShoppingCompanionAdRenderer",
                              (IMP)YTKACEHasShoppingCompanionAdRenderer,
                              &OriginalHasShoppingCompanionAdRenderer);
    YTKACEInstallInstanceHook(@"_ASCollectionViewCell",
                              @"layoutSubviews",
                              (IMP)YTKACECellLayoutSubviews,
                              &OriginalCellLayout);
    YTKACEInstallInstanceHook(@"_ASCollectionViewCell",
                              @"prepareForReuse",
                              (IMP)YTKACECellPrepareForReuse,
                              &OriginalCellReuse);
}
