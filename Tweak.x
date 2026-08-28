#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const kPrefVerified = @sa1zy_fake_verified;
static NSString *const kPrefFollowers = @sa1zy_fake_followers;
static NSString *const kPrefLikes = @sa1zy_fake_likes;
static NSString *const kPrefNickname = @sa1zy_fake_nickname;
static NSString *const kPrefUsername = @sa1zy_fake_username;

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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL isVerified = [defaults boolForKey:kPrefVerified];
    NSInteger followers = [defaults integerForKey:kPrefFollowers];
    NSInteger likes = [defaults integerForKey:kPrefLikes];
    NSString *nickname = [defaults stringForKey:kPrefNickname] ?: @";
 NSString *username = [defaults stringForKey:kPrefUsername] ?: @;

 UIAlertController *alert = [UIAlertController alertControllerWithTitle:@Sa1zy TikTok Visual Mod
 message:@Настройка локального отображения профиля
 preferredStyle:UIAlertControllerStyleAlert];

 [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
 textField.placeholder = @Никнейм (Отображаемое имя);
 textField.text = nickname;
 }];

 [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
 textField.placeholder = @Юзернейм (@handle);
 textField.text = username;
 }];

 [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
 textField.placeholder = @Количество подписчиков (число);
 textField.keyboardType = UIKeyboardTypeNumberPad;
 textField.text = followers > 0 ? [NSString stringWithFormat:@%ld, (long)followers] : @;
 }];

 [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
 textField.placeholder = @Количество лайков (число);
 textField.keyboardType = UIKeyboardTypeNumberPad;
 textField.text = likes > 0 ? [NSString stringWithFormat:@%ld, (long)likes] : @;
 }];

 NSString *toggleTitle = isVerified ? @[✓] Галочка: ВКЛЮЧЕНА (Нажми для выкл) : @[ ] Галочка: ВЫКЛЮЧЕНА (Нажми для вкл);
 UIAlertAction *toggleVerified = [UIAlertAction actionWithTitle:toggleTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
 [defaults setBool:!isVerified forKey:kPrefVerified];
 [defaults synchronize];
 ShowSa1zySettingsMenu(presentingVC);
 }];
 [alert addAction:toggleVerified];

 UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@Сохранить style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
 NSString *newNick = alert.textFields[0].text;
 NSString *newUser = alert.textFields[1].text;
 NSString *newFollowersStr = alert.textFields[2].text;
 NSString *newLikesStr = alert.textFields[3].text;

 [defaults setObject:newNick forKey:kPrefNickname];
 [defaults setObject:newUser forKey:kPrefUsername];
 [defaults setInteger:[newFollowersStr integerValue] forKey:kPrefFollowers];
 [defaults setInteger:[newLikesStr integerValue] forKey:kPrefLikes];
 [defaults synchronize];

 UIAlertController *doneAlert = [UIAlertController alertControllerWithTitle:@Готово
 message:@Данные сохранены. Перезайди во вкладку профиля для обновления визуала.
 preferredStyle:UIAlertControllerStyleAlert];
 [doneAlert addAction:[UIAlertAction actionWithTitle:@OK style:UIAlertActionStyleCancel handler:nil]];
 [presentingVC presentViewController:doneAlert animated:YES completion:nil];
 }];
 [alert addAction:saveAction];

 UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@Отмена style:UIAlertActionStyleCancel handler:nil];
 [alert addAction:cancelAction];

 [presentingVC presentViewController:alert animated:YES completion:nil];
}

%hook UIWindow
- (void)didMoveToWindow {
 %orig;
 UITapGestureRecognizer *twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sa1zy_handleTwoFingerDoubleTap:)];
 twoFingerTap.numberOfTouchesRequired = 2;
 twoFingerTap.numberOfTapsRequired = 2;
 [self addGestureRecognizer:twoFingerTap];
}

%new
- (void)sa1zy_handleTwoFingerDoubleTap:(UITapGestureRecognizer *)gesture {
 if (gesture.state == UIGestureRecognizerStateEnded) {
 UIViewController *rootVC = self.rootViewController;
 while (rootVC.presentedViewController) {
 rootVC = rootVC.presentedViewController;
 }
 if (rootVC) {
 ShowSa1zySettingsMenu(rootVC);
 }
 }
}
%end

%hook AWEUserModel

- (BOOL)isVerified {
 if ([self isCurrentLoginUser] && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
 return YES;
 }
 return %orig;
}

- (BOOL)isVerification {
 if ([self isCurrentLoginUser] && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
 return YES;
 }
 return %orig;
}

- (NSString *)customVerify {
 if ([self isCurrentLoginUser] && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefVerified]) {
 return @Verified Account;
 }
 return %orig;
}

- (NSInteger)followerCount {
 if ([self isCurrentLoginUser]) {
 NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
 if (fake > 0) return fake;
 }
 return %orig;
}

- (NSInteger)fansCount {
 if ([self isCurrentLoginUser]) {
 NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefFollowers];
 if (fake > 0) return fake;
 }
 return %orig;
}

- (NSInteger)totalFavorited {
 if ([self isCurrentLoginUser]) {
 NSInteger fake = [[NSUserDefaults standardUserDefaults] integerForKey:kPrefLikes];
 if (fake > 0) return fake;
 }
 return %orig;
}

- (NSString *)nickname {
 if ([self isCurrentLoginUser]) {
 NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefNickname];
 if (fake && fake.length > 0) return fake;
 }
 return %orig;
}

- (NSString *)uniqueID {
 if ([self isCurrentLoginUser]) {
 NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
 if (fake && fake.length > 0) return fake;
 }
 return %orig;
}

- (NSString *)shortID {
 if ([self isCurrentLoginUser]) {
 NSString *fake = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefUsername];
 if (fake && fake.length > 0) return fake;
 }
 return %orig;
}

%end
