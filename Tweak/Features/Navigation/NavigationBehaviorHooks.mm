#import "../../YTKACE.h"
#import "../../Runtime/Localization.h"
#import "../../Runtime/Hooking.h"
#import "../../Runtime/Preferences.h"
#import "../../UI/Notice.h"

#import <UIKit/UIKit.h>
#import <objc/message.h>
#import <objc/runtime.h>

@protocol YTKACEWatchLayerStatusBarState <NSObject>
- (BOOL)isFullScreen;
@end

static IMP OriginalControlSendAction;
static IMP OriginalWatchFullscreenStatusBarHidden;
static IMP OriginalWatchLayerStatusBarHidden;
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

static BOOL YTKACEStatusBarOrientationIsPortrait(UIViewController *controller) {
    UIInterfaceOrientation orientation =
        controller.view.window.windowScene.interfaceOrientation;
    if (orientation != UIInterfaceOrientationUnknown) {
        return UIInterfaceOrientationIsPortrait(orientation);
    }
    CGSize size = controller.view.bounds.size;
    return size.height > size.width;
}

static BOOL YTKACEPrefersStatusBarHidden(UIViewController *controller,
                                         BOOL fullscreen,
                                         IMP original,
                                         SEL selector) {
    if (YTKACEFeatureEnabled(@"YTKACE.Preference.Navigation.StatusBarHidden")) {
        return YES;
    }
    if (fullscreen &&
        YTKACEFeatureEnabled(@"YTKACE.Preference.Overlay.StatusBarVisible")) {
        return !YTKACEStatusBarOrientationIsPortrait(controller);
    }
    return ((BOOL (*)(id, SEL))original)(controller, selector);
}

static BOOL YTKACEWatchFullscreenPrefersStatusBarHidden(id receiver, SEL selector) {
    return YTKACEPrefersStatusBarHidden(receiver, YES,
                                        OriginalWatchFullscreenStatusBarHidden,
                                        selector);
}

static BOOL YTKACEWatchLayerPrefersStatusBarHidden(id receiver, SEL selector) {
    BOOL fullscreen = [(id<YTKACEWatchLayerStatusBarState>)receiver isFullScreen];
    return YTKACEPrefersStatusBarHidden(receiver, fullscreen,
                                        OriginalWatchLayerStatusBarHidden,
                                        selector);
}

void YTKACEInstallNavigationBehaviorHooks(void) {
    YTKACEInstallInstanceHook(@"UIControl",
                              @"sendAction:to:forEvent:",
                              (IMP)YTKACEControlSendAction,
                              &OriginalControlSendAction);
    YTKACEInstallInstanceHook(@"YTWatchFullscreenViewController",
                              @"prefersStatusBarHidden",
                              (IMP)YTKACEWatchFullscreenPrefersStatusBarHidden,
                              &OriginalWatchFullscreenStatusBarHidden);
    YTKACEInstallInstanceHook(@"YTWatchLayerViewController",
                              @"prefersStatusBarHidden",
                              (IMP)YTKACEWatchLayerPrefersStatusBarHidden,
                              &OriginalWatchLayerStatusBarHidden);
}
