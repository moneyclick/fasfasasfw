#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const kPrefVerified = @"sa1zy_fake_verified";
static NSString *const kPrefFollowers = @"sa1zy_fake_followers";
static NSString *const kPrefLikes = @"sa1zy_fake_likes";
static NSString *const kPrefNickname = @"sa1zy_fake_nickname";
static NSString *const kPrefUsername = @"sa1zy_fake_username";

// 0. ПОЛНАЯ БЛОКИРОВКА ОКНА АКТИВАЦИИ RXTIKTOK И ЛЮБЫХ КЛЮЧЕЙ

// 0.1 Перехват через UIAlertController
%hook UIViewController
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion {
    if (!viewControllerToPresent) {
        if (completion) completion();
        return;
    }
    
    if ([viewControllerToPresent isKindOfClass:[UIAlertController class]]) {
        UIAlertController *alert = (UIAlertController *)viewControllerToPresent;
        NSString *title = alert.title ?: @"";
        NSString *msg = alert.message ?: @"";
        
        if ([title isEqualToString:@"RXTikTok"] ||
            [title containsString:@"активац"] || [title containsString:@"Активац"] ||
            [title containsString:@"ключ"] || [title containsString:@"Ключ"] ||
            [msg containsString:@"ключ"] || [msg containsString:@"Ключ"] ||
            [msg containsString:@"активац"] || [msg containsString:@"Активац"] ||
            [msg containsString:@"Xavier"] || [msg containsString:@"ashhad"]) {
            if (completion) completion();
            return;
        }
    }
    
    NSString *cls = NSStringFromClass([viewControllerToPresent class]);
    if ([cls containsString:@"Security"] || [cls containsString:@"Lock"] || [cls containsString:@"Passcode"]) {
        if (completion) completion();
        return;
    }

    %orig;
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    NSString *cls = NSStringFromClass([self class]);
    if ([cls containsString:@"Profile"] || [cls containsString:@"Feed"] || [cls containsString:@"Main"]) {
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
    extern void ShowSa1zyMenu(UIViewController *presenter);
    ShowSa1zyMenu(self);
}
%end

// 0.2 Перехват через нативный AWEUIAlertView
@interface AWEUIAlertView : NSObject
@end

%hook AWEUIAlertView
+ (void)showAlertWithTitle:(id)arg1 description:(id)arg2 image:(id)arg3 actionButtonTitle:(id)arg4 cancelButtonTitle:(id)arg5 actionBlock:(id)arg6 cancelBlock:(id)arg7 {
    NSString *title = [NSString stringWithFormat:@"%@", arg1 ?: @""];
    NSString *desc = [NSString stringWithFormat:@"%@", arg2 ?: @""];
    if ([title containsString:@"RXTikTok"] || [title containsString:@"активац"] || [title containsString:@"ключ"] ||
        [desc containsString:@"активац"] || [desc containsString:@"ключ"] || [desc containsString:@"Xavier"] || [desc containsString:@"ashhad"]) {
        return;
    }
    %orig;
}
+ (void)showAlertWithTitle:(id)arg1 message:(id)arg2 {
    NSString *title = [NSString stringWithFormat:@"%@", arg1 ?: @""];
    NSString *desc = [NSString stringWithFormat:@"%@", arg2 ?: @""];
    if ([title containsString:@"RXTikTok"] || [title containsString:@"активац"] || [title containsString:@"ключ"] ||
        [desc containsString:@"активац"] || [desc containsString:@"ключ"] || [desc containsString:@"Xavier"] || [desc containsString:@"ashhad"]) {
        return;
    }
    %orig;
}
%end

// 1. UI Меню настроек
void ShowSa1zyMenu(UIViewController *presenter) {
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

// 2. Хук галочки через лейбл имени (как в BHTikTok++)
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

// 3. Хук модели компонентов профиля (как в BHTikTok++)
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

// 4. Хук AWEUserModel
%hook AWEUserModel
- (BOOL)isVerified {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return YES;
    return %orig;
}
- (BOOL)isVerification {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return YES;
    return %orig;
}
- (NSString *)customVerify {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) return @"Verified Account";
    return %orig;
}
- (NSInteger)followerCount {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
    if (fake > 0) return fake;
    return %orig;
}
- (NSInteger)fansCount {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
    if (fake > 0) return fake;
    return %orig;
}
- (NSInteger)totalFavorited {
    NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefLikes];
    if (fake > 0) return fake;
    return %orig;
}
- (NSString *)nickname {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefNickname];
    if (fake && fake.length > 0) return fake;
    return %orig;
}
- (NSString *)uniqueID {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
    if (fake && fake.length > 0) return fake;
    return %orig;
}
- (NSString *)shortID {
    NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
    if (fake && fake.length > 0) return fake;
    return %orig;
}
%end
