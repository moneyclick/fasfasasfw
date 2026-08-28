#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const kPrefVerified = @"sa1zy_fake_verified";
static NSString *const kPrefFollowers = @"sa1zy_fake_followers";
static NSString *const kPrefLikes = @"sa1zy_fake_likes";
static NSString *const kPrefNickname = @"sa1zy_fake_nickname";
static NSString *const kPrefUsername = @"sa1zy_fake_username";

static void SafeSwizzle(Class cls, SEL origSel, SEL backupSel, IMP newImp, const char *types) {
    if (!cls) return;
    Method origMethod = class_getInstanceMethod(cls, origSel);
    if (origMethod) {
        class_addMethod(cls, backupSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
        class_replaceMethod(cls, origSel, newImp, types);
    } else {
        class_addMethod(cls, origSel, newImp, types);
    }
}

// 1. AWEUserModel Hooks
static BOOL sa1zy_isVerified(id self, SEL _cmd) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return YES;
    SEL orig = NSSelectorFromString(@"sa1zy_orig_isVerified");
    if ([self respondsToSelector:orig]) {
        BOOL (*fn)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
        return fn(self, orig);
    }
    return NO;
}

static BOOL sa1zy_isVerification(id self, SEL _cmd) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return YES;
    SEL orig = NSSelectorFromString(@"sa1zy_orig_isVerification");
    if ([self respondsToSelector:orig]) {
        BOOL (*fn)(id, SEL) = (BOOL (*)(id, SEL))objc_msgSend;
        return fn(self, orig);
    }
    return NO;
}

static NSString *sa1zy_customVerify(id self, SEL _cmd) {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return @"Verified Account";
    SEL orig = NSSelectorFromString(@"sa1zy_orig_customVerify");
    if ([self respondsToSelector:orig]) {
        id (*fn)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        return fn(self, orig);
    }
    return nil;
}

static NSInteger sa1zy_followerCount(id self, SEL _cmd) {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
    if (fake > 0) return fake;
    SEL orig = NSSelectorFromString(@"sa1zy_orig_followerCount");
    if ([self respondsToSelector:orig]) {
        NSInteger (*fn)(id, SEL) = (NSInteger (*)(id, SEL))objc_msgSend;
        return fn(self, orig);
    }
    return 0;
}

static NSInteger sa1zy_totalFavorited(id self, SEL _cmd) {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefLikes];
    if (fake > 0) return fake;
    SEL orig = NSSelectorFromString(@"sa1zy_orig_totalFavorited");
    if ([self respondsToSelector:orig]) {
        NSInteger (*fn)(id, SEL) = (NSInteger (*)(id, SEL))objc_msgSend;
        return fn(self, orig);
    }
    return 0;
}

static NSString *sa1zy_nickname(id self, SEL _cmd) {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefNickname];
    if (fake && fake.length > 0) return fake;
    SEL orig = NSSelectorFromString(@"sa1zy_orig_nickname");
    if ([self respondsToSelector:orig]) {
        id (*fn)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        return fn(self, orig);
    }
    return @"";
}

static NSString *sa1zy_uniqueID(id self, SEL _cmd) {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
    if (fake && fake.length > 0) return fake;
    SEL orig = NSSelectorFromString(@"sa1zy_orig_uniqueID");
    if ([self respondsToSelector:orig]) {
        id (*fn)(id, SEL) = (id (*)(id, SEL))objc_msgSend;
        return fn(self, orig);
    }
    return @"";
}

// 2. Menu Dialog
static void ShowSa1zyMenu(UIViewController *presenter) {
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
        t.placeholder = @"Подписчики (число, напр. 1000000)";
        t.keyboardType = UIKeyboardTypeNumberPad;
        t.text = followers > 0 ? [NSString stringWithFormat:@"%ld", (long)followers] : @"";
    }];
    [alert addTextFieldWithConfigurationHandler:^(UITextField *t) {
        t.placeholder = @"Лайки (число, напр. 5000000)";
        t.keyboardType = UIKeyboardTypeNumberPad;
        t.text = likes > 0 ? [NSString stringWithFormat:@"%ld", (long)likes] : @"";
    }];

    NSString *toggleTitle = isVerified ? @"[✓] Галочка: ВКЛЮЧЕНА (Нажми для выкл)" : @"[ ] Галочка: ВЫКЛЮЧЕНА (Нажми для вкл)";
    [alert addAction:[UIAlertAction actionWithTitle:toggleTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [defaults setBool:!isVerified forKey:kPrefVerified];
        [defaults synchronize];
        ShowSa1zyMenu(presenter);
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Сохранить" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @try {
            [defaults setObject:alert.textFields[0].text forKey:kPrefNickname];
            [defaults setObject:alert.textFields[1].text forKey:kPrefUsername];
            [defaults setInteger:[alert.textFields[2].text integerValue] forKey:kPrefFollowers];
            [defaults setInteger:[alert.textFields[3].text integerValue] forKey:kPrefLikes];
            [defaults synchronize];

            UIAlertController *done = [UIAlertController alertControllerWithTitle:@"Сохранено!"
                                                                          message:@"Перейди в профиль для обновления."
                                                                   preferredStyle:UIAlertControllerStyleAlert];
            [done addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [presenter presentViewController:done animated:YES completion:nil];
        } @catch (NSException *e) {}
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

// 3. UIViewController gesture hook
static void sa1zy_viewDidAppear(id self, SEL _cmd, BOOL animated) {
    SEL orig = NSSelectorFromString(@"sa1zy_orig_viewDidAppear");
    if ([self respondsToSelector:orig]) {
        void (*fn)(id, SEL, BOOL) = (void (*)(id, SEL, BOOL))objc_msgSend;
        fn(self, orig, animated);
    }
    
    UIViewController *vc = (UIViewController *)self;
    if ([vc isMemberOfClass:[UIViewController class]] || [NSStringFromClass([vc class]) containsString:@"Profile"] || [NSStringFromClass([vc class]) containsString:@"Feed"] || [NSStringFromClass([vc class]) containsString:@"Main"]) {
        BOOL exists = NO;
        for (UIGestureRecognizer *g in vc.view.gestureRecognizers) {
            if ([g isKindOfClass:[UITapGestureRecognizer class]]) {
                UITapGestureRecognizer *tg = (UITapGestureRecognizer *)g;
                if (tg.numberOfTouchesRequired == 2 && tg.numberOfTapsRequired == 2) {
                    exists = YES;
                    break;
                }
            }
        }
        if (!exists) {
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:vc action:@selector(sa1zy_openMenuAction)];
            tap.numberOfTouchesRequired = 2;
            tap.numberOfTapsRequired = 2;
            tap.cancelsTouchesInView = NO;
            [vc.view addGestureRecognizer:tap];
        }
    }
}

static void sa1zy_openMenuAction(id self, SEL _cmd) {
    ShowSa1zyMenu((UIViewController *)self);
}

__attribute__((constructor)) static void Sa1zyInit(void) {
    @autoreleasepool {
        // Hook UIViewController
        class_addMethod([UIViewController class], @selector(sa1zy_openMenuAction), (IMP)sa1zy_openMenuAction, "v@:");
        SafeSwizzle([UIViewController class], @selector(viewDidAppear:), NSSelectorFromString(@"sa1zy_orig_viewDidAppear"), (IMP)sa1zy_viewDidAppear, "v@:B");

        // Hook AWEUserModel
        Class userCls = objc_getClass("AWEUserModel");
        if (userCls) {
            SafeSwizzle(userCls, @selector(isVerified), NSSelectorFromString(@"sa1zy_orig_isVerified"), (IMP)sa1zy_isVerified, "B@:");
            SafeSwizzle(userCls, @selector(isVerification), NSSelectorFromString(@"sa1zy_orig_isVerification"), (IMP)sa1zy_isVerification, "B@:");
            SafeSwizzle(userCls, @selector(customVerify), NSSelectorFromString(@"sa1zy_orig_customVerify"), (IMP)sa1zy_customVerify, "@@:");
            SafeSwizzle(userCls, @selector(followerCount), NSSelectorFromString(@"sa1zy_orig_followerCount"), (IMP)sa1zy_followerCount, "q@:");
            SafeSwizzle(userCls, @selector(fansCount), NSSelectorFromString(@"sa1zy_orig_fansCount"), (IMP)sa1zy_followerCount, "q@:");
            SafeSwizzle(userCls, @selector(totalFavorited), NSSelectorFromString(@"sa1zy_orig_totalFavorited"), (IMP)sa1zy_totalFavorited, "q@:");
            SafeSwizzle(userCls, @selector(nickname), NSSelectorFromString(@"sa1zy_orig_nickname"), (IMP)sa1zy_nickname, "@@:");
            SafeSwizzle(userCls, @selector(uniqueID), NSSelectorFromString(@"sa1zy_orig_uniqueID"), (IMP)sa1zy_uniqueID, "@@:");
            SafeSwizzle(userCls, @selector(shortID), NSSelectorFromString(@"sa1zy_orig_shortID"), (IMP)sa1zy_uniqueID, "@@:");
        }
    }
}
