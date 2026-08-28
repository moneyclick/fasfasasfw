#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <CoreTelephony/CTCarrier.h>

static NSString *const kPrefVerified = @"sa1zy_fake_verified";
static NSString *const kPrefFollowers = @"sa1zy_fake_followers";
static NSString *const kPrefLikes = @"sa1zy_fake_likes";
static NSString *const kPrefNickname = @"sa1zy_fake_nickname";
static NSString *const kPrefUsername = @"sa1zy_fake_username";
static NSString *const kPrefMockLogin = @"sa1zy_mock_login";

// =========================================================================
// 1. FIX BUNDLE ID (Устраняет блокировку Sideloadly)
// =========================================================================
// Sideloadly меняет Bundle ID на com.zhiliaoapp.musically.XXXXX, из-за чего
// сервер TikTok мгновенно отклоняет вход ошибкой "Слишком много попыток".
%hook NSBundle
- (NSString *)bundleIdentifier {
    NSString *orig = %orig;
    if ([orig containsString:@"com.zhiliaoapp.musically"]) {
        return @"com.zhiliaoapp.musically";
    }
    return orig;
}
%end

// =========================================================================
// 2. FIX СИМ-КАРТЫ (Спуфинг оператора связи на США)
// =========================================================================
%hook CTCarrier
- (NSString *)isoCountryCode {
    return @"us";
}
- (NSString *)mobileCountryCode {
    return @"310";
}
- (NSString *)mobileNetworkCode {
    return @"260";
}
- (NSString *)carrierName {
    return @"T-Mobile";
}
%end

// =========================================================================
// 3. FIX КРАША iOS 16 (BoundingPath)
// =========================================================================
@interface _UIScreenBoundingPathUtilities : NSObject
+ (id)boundingPathUtilitiesForScreen:(id)screen;
@end

@interface _UIScreenSimpleBoundingPathUtilities : NSObject
- (id)initWithScreen:(id)screen;
@end

%hook _UIScreenBoundingPathUtilities
+ (id)boundingPathUtilitiesForScreen:(id)screen {
    Class simpleCls = objc_getClass("_UIScreenSimpleBoundingPathUtilities");
    if (simpleCls) {
        return [[simpleCls alloc] initWithScreen:screen];
    }
    return %orig;
}
%end

// =========================================================================
// 4. FIX ДАТЫ РОЖДЕНИЯ (Отключение AgeGate / "Недопустимые параметры")
// =========================================================================
%hook PNSAgeGateService
- (BOOL)needAgeGate { return NO; }
- (BOOL)_needAgeGate { return NO; }
+ (BOOL)needAgeGate { return NO; }
- (BOOL)didRunNUJAgeGate { return YES; }
%end

%hook TTKUserAgeGateInfoService
- (BOOL)didRunAgeGate { return YES; }
- (BOOL)isPassedAgeGate { return YES; }
%end

// =========================================================================
// 5. ЛОКАЛЬНЫЙ ВХОД В АККАУНТ (MOCK LOGIN БЕЗ СЕРВЕРА)
// =========================================================================
// Если сервер не пускает, включаем статус "Залогинен" прямо на клиенте!
%hook AWEAccountUtils
+ (BOOL)isLogin {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefMockLogin]) {
        return YES;
    }
    return %orig;
}
%end

%hook AWEUserService
- (BOOL)isLogin {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefMockLogin]) {
        return YES;
    }
    return %orig;
}
%end

// =========================================================================
// 6. ХУК МОДЕЛИ ПОЛЬЗОВАТЕЛЯ (AWEUserModel)
// =========================================================================
@interface AWEUserModel : NSObject
- (BOOL)isMe;
@end

%hook AWEUserModel
- (BOOL)isMe {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefMockLogin]) {
        return YES;
    }
    return %orig;
}

- (BOOL)isVerified {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return YES;
    return %orig;
}
- (BOOL)isVerification {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return YES;
    return %orig;
}
- (BOOL)isVerifiedUser {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return YES;
    return %orig;
}
- (BOOL)isVerifiedBlue {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return YES;
    return %orig;
}
- (NSString *)customVerify {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return @"Verified Account";
    return %orig;
}

- (id)followerCount {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
    if (fake > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) return %orig;
        return @(fake);
    }
    return %orig;
}

- (id)fansCount {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
    if (fake > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) return %orig;
        return @(fake);
    }
    return %orig;
}

- (id)totalFavorited {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefLikes];
    if (fake > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) return %orig;
        return @(fake);
    }
    return %orig;
}

- (NSString *)nickname {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefNickname];
    if (fake && fake.length > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) return %orig;
        return fake;
    }
    return %orig;
}

- (NSString *)uniqueID {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
    if (fake && fake.length > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) return %orig;
        return fake;
    }
    return %orig;
}

- (NSString *)shortID {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
    if (fake && fake.length > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) return %orig;
        return fake;
    }
    return %orig;
}
%end

// =========================================================================
// 7. МЕНЮ НАСТРОЕК ТВRear (Shake или двойной тап 2 пальцами)
// =========================================================================
void ShowSa1zyMenu(UIViewController *presenter);

%hook UIViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Profile"] || [cls containsString:@"Feed"] || [cls containsString:@"Main"] || [cls containsString:@"Root"]) {
        BOOL exists = NO;
        for (UIGestureRecognizer *g in self.view.gestureRecognizers) {
            if ([g isKindOfClass:[UITapGestureRecognizer class]]) {
                UITapGestureRecognizer *tg = (UITapGestureRecognizer *)g;
                if (tg.numberOfTouchesRequired == 2 && tg.numberOfTapsRequired == 2) {
                    exists = YES;
                    break;
                }
            }
        }
        if (!exists) {
            UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sa1zy_openMenu)];
            tap.numberOfTouchesRequired = 2;
            tap.numberOfTapsRequired = 2;
            tap.cancelsTouchesInView = NO;
            [self.view addGestureRecognizer:tap];
        }
    }
}

%new
- (void)sa1zy_openMenu {
    ShowSa1zyMenu(self);
}
%end

%hook UIWindow
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    %orig;
    if (motion == UIEventSubtypeMotionShake) {
        UIViewController *rootVC = self.rootViewController;
        while (rootVC.presentedViewController) {
            rootVC = rootVC.presentedViewController;
        }
        ShowSa1zyMenu(rootVC);
    }
}
%end

void ShowSa1zyMenu(UIViewController *presenter) {
    if (!presenter) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isVerified = [defaults boolForKey:kPrefVerified];
    BOOL isMockLogin = [defaults boolForKey:kPrefMockLogin];
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

    NSString *toggleLogin = isMockLogin ? @"[✓] Вход без пароля: ВКЛ" : @"[ ] Вход без пароля: ВЫКЛ";
    [alert addAction:[UIAlertAction actionWithTitle:toggleLogin style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [defaults setBool:!isMockLogin forKey:kPrefMockLogin];
        [defaults synchronize];
        ShowSa1zyMenu(presenter);
    }]];

    NSString *toggleTitle = isVerified ? @"[✓] Галочка: ВКЛЮЧЕНА" : @"[ ] Галочка: ВЫКЛЮЧЕНА";
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
                                                                          message:@"Настройки применены."
                                                                   preferredStyle:UIAlertControllerStyleAlert];
            [done addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [presenter presentViewController:done animated:YES completion:nil];
        } @catch (NSException *e) {}
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [presenter presentViewController:alert animated:YES completion:nil];
}
