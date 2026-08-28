#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const kPrefVerified = @"sa1zy_fake_verified";
static NSString *const kPrefFollowers = @"sa1zy_fake_followers";
static NSString *const kPrefLikes = @"sa1zy_fake_likes";
static NSString *const kPrefNickname = @"sa1zy_fake_nickname";
static NSString *const kPrefUsername = @"sa1zy_fake_username";

// 1. Обход детекта модификации бандла (Sideload / Bundle Mangling Bypass)
%hook NSBundle
- (NSString *)bundleIdentifier {
    NSString *orig = %orig;
    if ([orig containsString:@"musically"] || [orig containsString:@"TikTok"] || [orig containsString:@"zhiliao"]) {
        return @"com.zhiliaoapp.musically";
    }
    return orig;
}
%end

// 2. Блокировка краш-репортеров и встроенных детекторов безопасности TikTok
%hook BDTuring
+ (BOOL)isJailbroken {
    return NO;
}
%end

@interface AWEUserModel : NSObject
- (BOOL)isCurrentLoginUser;
- (BOOL)isVerified;
- (BOOL)isVerification;
- (NSString *)customVerify;
- (NSInteger)followerCount;
- (NSInteger)fansCount;
- (NSInteger)totalFavorited;
- (NSString *)nickname;
- (NSString *)uniqueID;
- (NSString *)shortID;
@end

static void ShowSa1zySettingsMenu(UIViewController *presentingVC) {
    if (!presentingVC) return;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isVerified = [defaults boolForKey:kPrefVerified];
    NSInteger followers = [defaults integerForKey:kPrefFollowers];
    NSInteger likes = [defaults integerForKey:kPrefLikes];
    NSString *nickname = [defaults stringForKey:kPrefNickname] ?: @"";
    NSString *username = [defaults stringForKey:kPrefUsername] ?: @"";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sa1zy TikTok Mod"
                                                                   message:@"Визуальная настройка профиля"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Никнейм (Отображаемое имя)";
        textField.text = nickname;
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Юзернейм (@handle)";
        textField.text = username;
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Подписчики (число, напр. 1000000)";
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.text = followers > 0 ? [NSString stringWithFormat:@"%ld", (long)followers] : @"";
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Лайки (число, напр. 5000000)";
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.text = likes > 0 ? [NSString stringWithFormat:@"%ld", (long)likes] : @"";
    }];

    NSString *toggleTitle = isVerified ? @"[✓] Галочка: ВКЛЮЧЕНА (Тап для выкл)" : @"[ ] Галочка: ВЫКЛЮЧЕНА (Тап для вкл)";
    UIAlertAction *toggleVerified = [UIAlertAction actionWithTitle:toggleTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [defaults setBool:!isVerified forKey:kPrefVerified];
        [defaults synchronize];
        ShowSa1zySettingsMenu(presentingVC);
    }];
    [alert addAction:toggleVerified];

    UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"Сохранить" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @try {
            NSString *newNick = alert.textFields[0].text;
            NSString *newUser = alert.textFields[1].text;
            NSString *newFollowersStr = alert.textFields[2].text;
            NSString *newLikesStr = alert.textFields[3].text;

            [defaults setObject:newNick forKey:kPrefNickname];
            [defaults setObject:newUser forKey:kPrefUsername];
            [defaults setInteger:[newFollowersStr integerValue] forKey:kPrefFollowers];
            [defaults setInteger:[newLikesStr integerValue] forKey:kPrefLikes];
            [defaults synchronize];

            UIAlertController *doneAlert = [UIAlertController alertControllerWithTitle:@"Сохранено"
                                                                               message:@"Перезайди в профиль для обновления интерфейса."
                                                                        preferredStyle:UIAlertControllerStyleAlert];
            [doneAlert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [presentingVC presentViewController:doneAlert animated:YES completion:nil];
        } @catch (NSException *e) {}
    }];
    [alert addAction:saveAction];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];

    [presentingVC presentViewController:alert animated:YES completion:nil];
}

static BOOL IsCurrentUser(id target) {
    if (!target) return NO;
    @try {
        if ([target respondsToSelector:@selector(isCurrentLoginUser)]) {
            return [target isCurrentLoginUser];
        }
    } @catch (NSException *e) {
        return NO;
    }
    return YES;
}

// 3. Безопасный триггер вызова меню по двойному тапу 2 пальцами
%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    @try {
        NSString *cls = NSStringFromClass([self class]);
        if ([cls containsString:@"Profile"] || [cls containsString:@"Feed"] || [cls containsString:@"AWE"]) {
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
                UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sa1zy_openMenu)];
                doubleTap.numberOfTouchesRequired = 2;
                doubleTap.numberOfTapsRequired = 2;
                doubleTap.cancelsTouchesInView = NO;
                [self.view addGestureRecognizer:doubleTap];
            }
        }
    } @catch (NSException *e) {}
}

%new
- (void)sa1zy_openMenu {
    ShowSa1zySettingsMenu(self);
}

%end

// 4. Подмена модели профиля TikTok
%hook AWEUserModel

- (BOOL)isVerified {
    if (IsCurrentUser(self) && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
        return YES;
    }
    return %orig;
}

- (BOOL)isVerification {
    if (IsCurrentUser(self) && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
        return YES;
    }
    return %orig;
}

- (NSString *)customVerify {
    if (IsCurrentUser(self) && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
        return @"Verified Account";
    }
    return %orig;
}

- (NSInteger)followerCount {
    if (IsCurrentUser(self)) {
        NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
        if (fake > 0) return fake;
    }
    return %orig;
}

- (NSInteger)fansCount {
    if (IsCurrentUser(self)) {
        NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
        if (fake > 0) return fake;
    }
    return %orig;
}

- (NSInteger)totalFavorited {
    if (IsCurrentUser(self)) {
        NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefLikes];
        if (fake > 0) return fake;
    }
    return %orig;
}

- (NSString *)nickname {
    if (IsCurrentUser(self)) {
        NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefNickname];
        if (fake && fake.length > 0) return fake;
    }
    return %orig;
}

- (NSString *)uniqueID {
    if (IsCurrentUser(self)) {
        NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
        if (fake && fake.length > 0) return fake;
    }
    return %orig;
}

- (NSString *)shortID {
    if (IsCurrentUser(self)) {
        NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
        if (fake && fake.length > 0) return fake;
    }
    return %orig;
}

%end
