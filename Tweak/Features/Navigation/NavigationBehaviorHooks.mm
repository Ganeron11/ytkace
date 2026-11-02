#import "../../YTKACE.h"
#import "../../Runtime/Localization.h"
#import "../../Runtime/Hooking.h"
#import "../../Runtime/Preferences.h"
#import "../../UI/Notice.h"

#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

static IMP OriginalControlSendAction;
static IMP OriginalAppStatusBarHidden;
static IMP OriginalWatchLayerStatusBarHidden;
static IMP OriginalFullscreenStatusBarHidden;
static IMP OriginalOverlayOrientationChange;
static BOOL YTKACECastBypass;

static BOOL YTKACEIsCastControl(UIControl *control, SEL action, id target) {
    (void)target;
    NSString *token = [[NSString stringWithFormat:@"%@ %@ %@ %@",
        NSStringFromClass(control.class),
        control.accessibilityIdentifier ?: @"",
        control.accessibilityLabel ?: @"",
        NSStringFromSelector(action)]
        lowercaseString];
    return [token containsString:@"cast"] ||
        [token containsString:@"airplay"] ||
        [token containsString:@"routebutton"] ||
        [token containsString:@"mdx"];
}

static void YTKACEControlSendAction(UIControl *receiver,
                                    SEL selector,
                                    SEL action,
                                    id target,
                                    UIEvent *event) {
    if (OriginalControlSendAction == NULL) {
        return;
    }
    BOOL castControl = YTKACEIsCastControl(receiver, action, target);
    if (castControl) {
        YTKACEStartCastDiscovery();
    }
    if (YTKACECastBypass ||
        !YTKACEFeatureEnabled(@"YTKACE.Preference.Navigation.CastConfirmation") ||
        !castControl) {
        ((void (*)(id, SEL, SEL, id, id))OriginalControlSendAction)(
            receiver, selector, action, target, event
        );
        return;
    }
    __weak UIControl *weakReceiver = receiver;
    __weak id weakTarget = target;
    BOOL shown = YTKACEShowYouTubeConfirmation(
        YTKACELocalized(@"Connect to a device?"),
        YTKACELocalized(@"YouTube is about to open the Cast menu."),
        YTKACELocalized(@"Continue"),
        ^{
            UIControl *strongReceiver = weakReceiver;
            if (strongReceiver == nil) {
                return;
            }
            YTKACECastBypass = YES;
            ((void (*)(id, SEL, SEL, id, id))OriginalControlSendAction)(
                strongReceiver, selector, action, weakTarget, event
            );
            YTKACECastBypass = NO;
        }
    );
    if (!shown) {
        ((void (*)(id, SEL, SEL, id, id))OriginalControlSendAction)(
            receiver, selector, action, target, event
        );
    }
}

static BOOL YTKACEAppPrefersStatusHidden(id receiver, SEL selector) {
    if (YTKACEFeatureEnabled(@"YTKACE.Preference.Navigation.StatusBarHidden")) {
        return YES;
    }
    return ((BOOL (*)(id, SEL))OriginalAppStatusBarHidden)(receiver, selector);
}

static BOOL YTKACEOverlayIsPortraitFullscreen(id receiver) {
    id overlayController = ((id (*)(id, SEL))objc_msgSend)(
        receiver,
        NSSelectorFromString(@"mainAppVideoPlayerOverlayViewController")
    );
    id overlayView = ((id (*)(id, SEL))objc_msgSend)(
        overlayController,
        NSSelectorFromString(@"videoPlayerOverlayView")
    );
    return ((BOOL (*)(id, SEL))objc_msgSend)(
        overlayView,
        NSSelectorFromString(@"isPortraitFullscreen")
    );
}

static BOOL YTKACEFullscreenStatusBarHidden(id receiver,
                                            SEL selector,
                                            IMP original) {
    if (YTKACEFeatureEnabled(@"YTKACE.Preference.Navigation.StatusBarHidden")) {
        return YES;
    }
    if (!YTKACEFeatureEnabled(@"YTKACE.Preference.Overlay.StatusBarVisible")) {
        return ((BOOL (*)(id, SEL))original)(receiver, selector);
    }
    // YouTube lays out the fullscreen player itself; portrait fullscreen is
    // the only case where its status bar behavior has to be overridden.
    if (YTKACEOverlayIsPortraitFullscreen(receiver)) {
        return NO;
    }
    return ((BOOL (*)(id, SEL))original)(receiver, selector);
}

static BOOL YTKACEWatchLayerPrefersStatusHidden(id receiver, SEL selector) {
    BOOL fullscreen = ((BOOL (*)(id, SEL))objc_msgSend)(
        receiver, NSSelectorFromString(@"isWatchFullScreen"));
    if (!fullscreen) {
        if (YTKACEFeatureEnabled(@"YTKACE.Preference.Navigation.StatusBarHidden")) {
            return YES;
        }
        return ((BOOL (*)(id, SEL))OriginalWatchLayerStatusBarHidden)(
            receiver, selector
        );
    }
    return YTKACEFullscreenStatusBarHidden(receiver,
                                           selector,
                                           OriginalWatchLayerStatusBarHidden);
}

static BOOL YTKACEWatchFullscreenPrefersStatusHidden(id receiver, SEL selector) {
    return YTKACEFullscreenStatusBarHidden(receiver,
                                           selector,
                                           OriginalFullscreenStatusBarHidden);
}

static void YTKACEOverlayDidChangeOrientation(id receiver,
                                              SEL selector,
                                              UIInterfaceOrientation orientation) {
    ((void (*)(id, SEL, UIInterfaceOrientation))OriginalOverlayOrientationChange)(
        receiver, selector, orientation
    );
    [receiver.view.window.rootViewController setNeedsStatusBarAppearanceUpdate];
}

void YTKACEInstallNavigationBehaviorHooks(void) {
    YTKACEInstallInstanceHook(@"UIControl",
                              @"sendAction:to:forEvent:",
                              (IMP)YTKACEControlSendAction,
                              &OriginalControlSendAction);
    YTKACEInstallInstanceHook(@"YTAppViewControllerImpl",
                              @"prefersStatusBarHidden",
                              (IMP)YTKACEAppPrefersStatusHidden,
                              &OriginalAppStatusBarHidden);
    YTKACEInstallInstanceHook(@"YTWatchLayerViewController",
                              @"prefersStatusBarHidden",
                              (IMP)YTKACEWatchLayerPrefersStatusHidden,
                              &OriginalWatchLayerStatusBarHidden);
    YTKACEInstallInstanceHook(@"YTWatchFullscreenViewController",
                              @"prefersStatusBarHidden",
                              (IMP)YTKACEWatchFullscreenPrefersStatusHidden,
                              &OriginalFullscreenStatusBarHidden);
    YTKACEInstallInstanceHook(@"YTMainAppVideoPlayerOverlayViewController",
                              @"handleDidChangeToInterfaceOrientation:",
                              (IMP)YTKACEOverlayDidChangeOrientation,
                              &OriginalOverlayOrientationChange);
}
