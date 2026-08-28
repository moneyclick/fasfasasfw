#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const kPrefVerified = @"sa1zy_fake_verified";
static NSString *const kPrefFollowers = @"sa1zy_fake_followers";
static NSString *const kPrefLikes = @"sa1zy_fake_likes";
static NSString *const kPrefNickname = @"sa1zy_fake_nickname";
static NSString *const kPrefUsername = @"sa1zy_fake_username";

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
                                                                   message:@"Настройки визуального отображения"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Никнейм (Имя в профиле)";
        textField.text = nickname;
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Юзернейм (@handle)";
        textField.text = username;
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Подписчики (например 1000000)";
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.text = followers > 0 ? [NSString stringWithFormat:@"%ld", (long)followers] : @"";
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"Лайки (например 5000000)";
        textField.keyboardType = UIKeyboardTypeNumberPad;
        textField.text = likes > 0 ? [NSString stringWithFormat:@"%ld", (long)likes] : @"";
    }];

    NSString *toggleTitle = isVerified ? @"[✓] Галочка: ВКЛЮЧЕНА" : @"[ ] Галочка: ВЫКЛЮЧЕНА";
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

            UIAlertController *doneAlert = [UIAlertController alertControllerWithTitle:@"Успешно"
                                                                               message:@"Настройки применены. Обновите страницу профиля."
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

static BOOL IsTargetCurrentUser(id userModel) {
    if (!userModel) return NO;
    @try {
        if ([userModel respondsToSelector:@selector(isCurrentLoginUser)]) {
            return [userModel isCurrentLoginUser];
        }
    } @catch (NSException *e) {
        return NO;
    }
    return YES;
}

// Безопасный хук на контроллер профиля для добавления жеста меню
%hook UIViewController

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    @try {
        NSString *className = NSStringFromClass([self class]);
        if ([className containsString:@"UserProfile"] || [className containsString:@"AWEProfile"] || [className containsString:@"AWEFeed"]) {
            BOOL alreadyAdded = NO;
            for (UIGestureRecognizer *g in self.view.gestureRecognizers) {
                if ([g isKindOfClass:[UITapGestureRecognizer class]]) {
                    UITapGestureRecognizer *tg = (UITapGestureRecognizer *)g;
                    if (tg.numberOfTouchesRequired == 2 && tg.numberOfTapsRequired == 2) {
                        alreadyAdded = YES;
                        break;
                    }
                }
            }
            if (!alreadyAdded) {
                UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sa1zy_openSettingsMenu)];
                twoFingerTap.numberOfTouchesRequired = 2;
                twoFingerTap.numberOfTapsRequired = 2;
                twoFingerTap.cancelsTouchesInView = NO;
                [self.view addGestureRecognizer:twoFingerTap];
            }
        }
    } @catch (NSException *e) {}
}

%new
- (void)sa1zy_openSettingsMenu {
    ShowSa1zySettingsMenu(self);
}

%end

// Хуки на модель пользователя с защитой от сбоев
%hook AWEUserModel

- (BOOL)isVerified {
    if (IsTargetCurrentUser(self) && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
        return YES;
    }
    return %orig;
}

- (BOOL)isVerification {
    if (IsTargetCurrentUser(self) && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
        return YES;
    }
    return %orig;
}

- (NSString *)customVerify {
    if (IsTargetCurrentUser(self) && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
        return @"Verified Account";
    }
    return %orig;
}

- (NSInteger)followerCount {
    if (IsTargetCurrentUser(self)) {
        NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
        if (fake > 0) return fake;
    }
    return %orig;
}

- (NSInteger)fansCount {
    if (IsTargetCurrentUser(self)) {
        NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
        if (fake > 0) return fake;
    }
    return %orig;
}

- (NSInteger)totalFavorited {
    if (IsTargetCurrentUser(self)) {
        NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefLikes];
        if (fake > 0) return fake;
    }
    return %orig;
}

- (NSString *)nickname {
    if (IsTargetCurrentUser(self)) {
        NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefNickname];
        if (fake && fake.length > 0) return fake;
    }
    return %orig;
}

- (NSString *)uniqueID {
    if (IsTargetCurrentUser(self)) {
        NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
        if (fake && fake.length > 0) return fake;
    }
    return %orig;
}

- (NSString *)shortID {
    if (IsTargetCurrentUser(self)) {
        NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
        if (fake && fake.length > 0) return fake;
    }
    return %orig;
}

%end
