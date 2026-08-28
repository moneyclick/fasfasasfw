#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const kPrefVerified = @"sa1zy_fake_verified";
static NSString *const kPrefFollowers = @"sa1zy_fake_followers";
static NSString *const kPrefLikes = @"sa1zy_fake_likes";
static NSString *const kPrefNickname = @"sa1zy_fake_nickname";
static NSString *const kPrefUsername = @"sa1zy_fake_username";

// 1. Спуфинг бандла без блокировки рантайма
%hook NSBundle
- (NSString *)bundleIdentifier {
    NSString *orig = %orig;
    if (orig && ([orig containsString:@"musically"] || [orig containsString:@"TikTok"])) {
        return @"com.zhiliaoapp.musically";
    }
    return orig;
}
%end

// 2. Модальное меню настроек
static void OpenSa1zyMenu(UIViewController *topVC) {
    if (!topVC) return;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isVerified = [defaults boolForKey:kPrefVerified];
    NSInteger followers = [defaults integerForKey:kPrefFollowers];
    NSInteger likes = [defaults integerForKey:kPrefLikes];
    NSString *nickname = [defaults stringForKey:kPrefNickname] ?: @"";
    NSString *username = [defaults stringForKey:kPrefUsername] ?: @"";

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Sa1zy TikTok Visual Mod"
                                                                   message:@"Локальное изменение профиля"
                                                            preferredStyle:UIAlertControllerStyleAlert];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Имя (Никнейм)";
        tf.text = nickname;
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Юзернейм (@handle)";
        tf.text = username;
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Подписчики (число)";
        tf.keyboardType = UIKeyboardTypeNumberPad;
        tf.text = followers > 0 ? [NSString stringWithFormat:@"%ld", (long)followers] : @"";
    }];

    [alert addTextFieldWithConfigurationHandler:^(UITextField *tf) {
        tf.placeholder = @"Лайки (число)";
        tf.keyboardType = UIKeyboardTypeNumberPad;
        tf.text = likes > 0 ? [NSString stringWithFormat:@"%ld", (long)likes] : @"";
    }];

    NSString *toggleTitle = isVerified ? @"[✓] Галочка: ВКЛЮЧЕНА (Тап: выкл)" : @"[ ] Галочка: ВЫКЛЮЧЕНА (Тап: вкл)";
    UIAlertAction *toggleAct = [UIAlertAction actionWithTitle:toggleTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [defaults setBool:!isVerified forKey:kPrefVerified];
        [defaults synchronize];
        OpenSa1zyMenu(topVC);
    }];
    [alert addAction:toggleAct];

    UIAlertAction *saveAct = [UIAlertAction actionWithTitle:@"Сохранить" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        @try {
            [defaults setObject:alert.textFields[0].text forKey:kPrefNickname];
            [defaults setObject:alert.textFields[1].text forKey:kPrefUsername];
            [defaults setInteger:[alert.textFields[2].text integerValue] forKey:kPrefFollowers];
            [defaults setInteger:[alert.textFields[3].text integerValue] forKey:kPrefLikes];
            [defaults synchronize];

            UIAlertController *done = [UIAlertController alertControllerWithTitle:@"Успешно"
                                                                          message:@"Данные сохранены. Перезайди во вкладку профиля."
                                                                   preferredStyle:UIAlertControllerStyleAlert];
            [done addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
            [topVC presentViewController:done animated:YES completion:nil];
        } @catch (NSException *e) {}
    }];
    [alert addAction:saveAct];

    UIAlertAction *cancelAct = [UIAlertAction actionWithTitle:@"Отмена" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAct];

    [topVC presentViewController:alert animated:YES completion:nil];
}

// 3. Глобальный жест через Window после старта
%hook UIWindow
- (void)becomeKeyWindow {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sa1zy_trigger:)];
        tap.numberOfTouchesRequired = 2;
        tap.numberOfTapsRequired = 2;
        tap.cancelsTouchesInView = NO;
        [self addGestureRecognizer:tap];
    });
}

%new
- (void)sa1zy_trigger:(UITapGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateEnded) {
        UIViewController *root = self.rootViewController;
        while (root.presentedViewController) {
            root = root.presentedViewController;
        }
        if (root) {
            OpenSa1zyMenu(root);
        }
    }
}
%end

// 4. Легковесный хук модели без задержек и циклов
%hook AWEUserModel

- (BOOL)isVerified {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
        return YES;
    }
    return %orig;
}

- (BOOL)isVerification {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
        return YES;
    }
    return %orig;
}

- (NSString *)customVerify {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
        return @"Verified Account";
    }
    return %orig;
}

- (NSInteger)followerCount {
    NSInteger val = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
    if (val > 0) return val;
    return %orig;
}

- (NSInteger)fansCount {
    NSInteger val = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
    if (val > 0) return val;
    return %orig;
}

- (NSInteger)totalFavorited {
    NSInteger val = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefLikes];
    if (val > 0) return val;
    return %orig;
}

- (NSString *)nickname {
    NSString *val = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefNickname];
    if (val && val.length > 0) return val;
    return %orig;
}

- (NSString *)uniqueID {
    NSString *val = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
    if (val && val.length > 0) return val;
    return %orig;
}

- (NSString *)shortID {
    NSString *val = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
    if (val && val.length > 0) return val;
    return %orig;
}

%end
