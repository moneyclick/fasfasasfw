#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const kPrefVerified = @"sa1zy_fake_verified";
static NSString *const kPrefFollowers = @"sa1zy_fake_followers";
static NSString *const kPrefLikes = @"sa1zy_fake_likes";
static NSString *const kPrefNickname = @"sa1zy_fake_nickname";
static NSString *const kPrefUsername = @"sa1zy_fake_username";

// =========================================================================
// 0. FIX: Устранение краша iOS 16 (____UIKitSharedBoundingPathDataManager)
// =========================================================================
// На iPhone X / iOS 16 в sideloaded приложениях при показе стартовых шторрок
// _UIScreenComplexBoundingPathUtilities падает с ошибкой в памяти 0x74.
// Принудительно используем _UIScreenSimpleBoundingPathUtilities.
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
// 1. Жест вызова меню (Двойное касание 2 пальцами + Shake)
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

// Открытие по встряхиванию (Shake)
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

// =========================================================================
// 2. UI Меню настроек
// =========================================================================
void ShowSa1zyMenu(UIViewController *presenter) {
    if (!presenter) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isVerified = [defaults boolForKey:kPrefVerified];
    NSInteger followers = [defaults integerForKey:kPrefFollowers];
    NSInteger likes = [defaults integerForKey:kPrefLikes];
    NSString *nick = [defaults stringForKey:kPrefNickname] ?: @"";
    NSString *user = [defaults stringForKey:kPrefUsername] ?: @"";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sa1zy TikTok Mod"
                                                                   message:@"Визуальные настройки профиля\n(Двойной тап 2 пальцами или потрясти телефон)"
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
                                                                          message:@"Перейди в свой профиль для обновления."
                                                                   preferredStyle:UIAlertControllerStyleAlert];
            [done addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [presenter presentViewController:done animated:YES completion:nil];
        } @catch (NSException *e) {}
    }]];

    [alert addAction:[UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

// =========================================================================
// 3. Хук галочки в лейбле имени
// =========================================================================
@interface AWEUserNameLabel : UILabel
- (void)addVerifiedIcon:(BOOL)arg1;
@end

%hook AWEUserNameLabel
- (void)layoutSubviews {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
        if ([self respondsToSelector:@selector(addVerifiedIcon:)]) {
            [self addVerifiedIcon:YES];
        }
    }
}
%end

// =========================================================================
// 4. Хук компонентов профиля
// =========================================================================
@interface TTKProfileBaseComponentModel : NSObject
@property (nonatomic, copy) NSString *componentID;
@end

%hook TTKProfileBaseComponentModel
- (NSDictionary *)bizData {
    NSDictionary *orig = %orig;
    if (!orig) return orig;
    
    NSInteger followers = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
    if (followers > 0 && [self.componentID isEqualToString:@"relation_info_follower"]) {
        NSMutableDictionary *mod = [orig mutableCopy];
        mod[@"follower_count"] = @(followers);
        return [mod copy];
    }
    return orig;
}
%end

// =========================================================================
// 5. Хук AWEUserModel (с правильными типами NSNumber*)
// =========================================================================
@interface AWEUserModel : NSObject
- (BOOL)isMe;
@end

%hook AWEUserModel
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
- (NSString *)customVerifyInfo {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return @"Verified Account";
    return %orig;
}

// ВНИМАНИЕ: followerCount и totalFavorited в TikTok возвращают NSNumber*!
- (id)followerCount {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
    if (fake > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) {
            return %orig; // не меняем чужих авторов в ленте
        }
        return @(fake);
    }
    return %orig;
}

- (id)fansCount {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
    if (fake > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) {
            return %orig;
        }
        return @(fake);
    }
    return %orig;
}

- (id)totalFavorited {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefLikes];
    if (fake > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) {
            return %orig;
        }
        return @(fake);
    }
    return %orig;
}

- (NSString *)nickname {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefNickname];
    if (fake && fake.length > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) {
            return %orig;
        }
        return fake;
    }
    return %orig;
}

- (NSString *)uniqueID {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
    if (fake && fake.length > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) {
            return %orig;
        }
        return fake;
    }
    return %orig;
}

- (NSString *)shortID {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
    if (fake && fake.length > 0) {
        if ([self respondsToSelector:@selector(isMe)] && ![self isMe]) {
            return %orig;
        }
        return fake;
    }
    return %orig;
}
%end
