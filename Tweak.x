#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const kPrefVerified = @"sa1zy_fake_verified";
static NSString *const kPrefFollowers = @"sa1zy_fake_followers";
static NSString *const kPrefLikes = @"sa1zy_fake_likes";
static NSString *const kPrefNickname = @"sa1zy_fake_nickname";
static NSString *const kPrefUsername = @"sa1zy_fake_username";

static void SwizzleInstance(Class cls, SEL origSel, SEL newSel, IMP newImp, const char *types) {
    if (!cls) return;
    Method origMethod = class_getInstanceMethod(cls, origSel);
    if (origMethod) {
        class_addMethod(cls, newSel, newImp, types);
        Method newMethod = class_getInstanceMethod(cls, newSel);
        method_exchangeImplementations(origMethod, newMethod);
    } else {
        class_addMethod(cls, origSel, newImp, types);
    }
}

// 1. Bundle Spoofer
static NSString *sa1zy_bundleIdentifier(id self, SEL _cmd) {
    return @"com.zhiliaoapp.musically";
}

// 2. AWEUserModel Hooks
static BOOL sa1zy_isVerified(id self, SEL _cmd) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return YES;
    SEL orig = NSSelectorFromString(@"sa1zy_orig_isVerified");
    if ([self respondsToSelector:orig]) {
        BOOL (*typedMsgSend)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
        return typedMsgSend(self, orig);
    }
    return NO;
}

static NSString *sa1zy_customVerify(id self, SEL _cmd) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return @"Verified Account";
    SEL orig = NSSelectorFromString(@"sa1zy_orig_customVerify");
    if ([self respondsToSelector:orig]) {
        id (*typedMsgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        return typedMsgSend(self, orig);
    }
    return nil;
}

static NSInteger sa1zy_followerCount(id self, SEL _cmd) {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
    if (fake > 0) return fake;
    SEL orig = NSSelectorFromString(@"sa1zy_orig_followerCount");
    if ([self respondsToSelector:orig]) {
        NSInteger (*typedMsgSend)(id, SEL) = (NSInteger (*)(id, SEL))objc_msgSend;
        return typedMsgSend(self, orig);
    }
    return 0;
}

static NSInteger sa1zy_totalFavorited(id self, SEL _cmd) {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefLikes];
    if (fake > 0) return fake;
    SEL orig = NSSelectorFromString(@"sa1zy_orig_totalFavorited");
    if ([self respondsToSelector:orig]) {
        NSInteger (*typedMsgSend)(id, SEL) = (NSInteger (*)(id, SEL))objc_msgSend;
        return typedMsgSend(self, orig);
    }
    return 0;
}

static NSString *sa1zy_nickname(id self, SEL _cmd) {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefNickname];
    if (fake && fake.length > 0) return fake;
    SEL orig = NSSelectorFromString(@"sa1zy_orig_nickname");
    if ([self respondsToSelector:orig]) {
        id (*typedMsgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        return typedMsgSend(self, orig);
    }
    return @"";
}

static NSString *sa1zy_uniqueID(id self, SEL _cmd) {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
    if (fake && fake.length > 0) return fake;
    SEL orig = NSSelectorFromString(@"sa1zy_orig_uniqueID");
    if ([self respondsToSelector:orig]) {
        id (*typedMsgSend)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        return typedMsgSend(self, orig);
    }
    return @"";
}

// 3. UI Settings Menu
static void ShowMenu(UIViewController *presenter) {
    if (!presenter) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isVerified = [defaults boolForKey:kPrefVerified];
    NSInteger followers = [defaults integerForKey:kPrefFollowers];
    NSInteger likes = [defaults integerForKey:kPrefLikes];
    NSString *nick = [defaults stringForKey:kPrefNickname] ?: @"";
    NSString *user = [defaults stringForKey:kPrefUsername] ?: @"";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sa1zy TikTok Mod"
                                                                   message:@"Визуальные настройки профиля"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *t) { t.placeholder = @"Имя (Никнейм)"; t.text = nick; }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *t) { t.placeholder = @"Юзернейм (@handle)"; t.text = user; }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *t) {
        t.placeholder = @"Подписчики (число)";
        t.keyboardType = UIKeyboardTypeNumberPad;
        t.text = followers > 0 ? [NSString stringWithFormat:@"%ld", (long)followers] : @"";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *t) {
        t.placeholder = @"Лайки (число)";
        t.keyboardType = UIKeyboardTypeNumberPad;
        t.text = likes > 0 ? [NSString stringWithFormat:@"%ld", (long)likes] : @"";
    }];

    NSString *toggleTitle = isVerified ? @"[✓] Галочка: ВКЛЮЧЕНА (Нажми для выкл)" : @"[ ] Галочка: ВЫКЛЮЧЕНА (Нажми для вкл)";
    [alert addAction:[UIAlertAction actionWithTitle:toggleTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [defaults setBool:!isVerified forKey:kPrefVerified];
        [defaults synchronize];
        ShowMenu(presenter);
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Сохранить" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @try {
            [defaults setObject:alert.textFields[0].text forKey:kPrefNickname];
            [defaults setObject:alert.textFields[1].text forKey:kPrefUsername];
            [defaults setInteger:[alert.textFields[2].text integerValue] forKey:kPrefFollowers];
            [defaults setInteger:[alert.textFields[3].text integerValue] forKey:kPrefLikes];
            [defaults synchronize];

            UIAlertController *done = [UIAlertController alertControllerWithTitle:@"Сохранено"
                                                                          message:@"Обнови профиль для применения."
                                                                   preferredStyle:UIAlertControllerStyleAlert];
            [done addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [presenter presentViewController:done animated:YES completion:nil];
        } @catch (NSException *e) {}
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

@interface Sa1zyGestureHandler : NSObject
+ (void)handleTap:(UITapGestureRecognizer *)gesture;
@end

@implementation Sa1zyGestureHandler
+ (void)handleTap:(UITapGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded) {
        UIViewController *root = nil;
        if ([gesture.view isKindOfClass:[UIWindow class]]) {
            root = [(UIWindow *)gesture.view rootViewController];
        }
        if (!root) {
            for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
                if ([scene isKindOfClass:[UIWindowScene class]]) {
                    for (UIWindow *w in scene.windows) {
                        if (w.isKeyWindow && w.rootViewController) {
                            root = w.rootViewController;
                            break;
                        }
                    }
                }
                if (root) break;
            }
        }
        if (!root) {
            for (UIWindow *w in [UIApplication sharedApplication].windows) {
                if (w.isKeyWindow && w.rootViewController) { root = w.rootViewController; break; }
            }
        }
        while (root.presentedViewController) {
            root = root.presentedViewController;
        }
        if (root) {
            ShowMenu(root);
        }
    }
}
@end

static void sa1zy_becomeKeyWindow(id self, SEL _cmd) {
    SEL orig = NSSelectorFromString(@"sa1zy_orig_becomeKeyWindow");
    if ([self respondsToSelector:orig]) {
        void (*typedMsgSend)(id, SEL) = (void (*)(id, SEL))objc_msgSend;
        typedMsgSend(self, orig);
    }
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:[Sa1zyGestureHandler class] action:@selector(handleTap:)];
        tap.numberOfTouchesRequired = 2;
        tap.numberOfTapsRequired = 2;
        tap.cancelsTouchesInView = NO;
        [self addGestureRecognizer:tap];
    });
}

__attribute__((constructor)) static void Sa1zyInit(void) {
    @autoreleasepool {
        // 1. Swizzle NSBundle
        SwizzleInstance([NSBundle class], @selector(bundleIdentifier), NSSelectorFromString(@"sa1zy_orig_bundleIdentifier"), (IMP)sa1zy_bundleIdentifier, "@@:");

        // 2. Swizzle UIWindow
        SwizzleInstance([UIWindow class], @selector(becomeKeyWindow), NSSelectorFromString(@"sa1zy_orig_becomeKeyWindow"), (IMP)sa1zy_becomeKeyWindow, "v@:");

        // 3. Swizzle AWEUserModel
        Class userCls = objc_getClass("AWEUserModel");
        if (userCls) {
            SwizzleInstance(userCls, @selector(isVerified), NSSelectorFromString(@"sa1zy_orig_isVerified"), (IMP)sa1zy_isVerified, "B@:");
            SwizzleInstance(userCls, @selector(isVerification), NSSelectorFromString(@"sa1zy_orig_isVerification"), (IMP)sa1zy_isVerified, "B@:");
            SwizzleInstance(userCls, @selector(customVerify), NSSelectorFromString(@"sa1zy_orig_customVerify"), (IMP)sa1zy_customVerify, "@@:");
            SwizzleInstance(userCls, @selector(followerCount), NSSelectorFromString(@"sa1zy_orig_followerCount"), (IMP)sa1zy_followerCount, "q@:");
            SwizzleInstance(userCls, @selector(fansCount), NSSelectorFromString(@"sa1zy_orig_fansCount"), (IMP)sa1zy_followerCount, "q@:");
            SwizzleInstance(userCls, @selector(totalFavorited), NSSelectorFromString(@"sa1zy_orig_totalFavorited"), (IMP)sa1zy_totalFavorited, "q@:");
            SwizzleInstance(userCls, @selector(nickname), NSSelectorFromString(@"sa1zy_orig_nickname"), (IMP)sa1zy_nickname, "@@:");
            SwizzleInstance(userCls, @selector(uniqueID), NSSelectorFromString(@"sa1zy_orig_uniqueID"), (IMP)sa1zy_uniqueID, "@@:");
            SwizzleInstance(userCls, @selector(shortID), NSSelectorFromString(@"sa1zy_orig_shortID"), (IMP)sa1zy_uniqueID, "@@:");
        }
    }
}
