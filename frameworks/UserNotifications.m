/* UserNotifications-lite: a real UserNotifications.framework subset for the
 * iosim runtime.
 *
 * Built as an x86_64 Mach-O dylib at the canonical install name. Apps ask
 * UNUserNotificationCenter for authorization, add UNNotificationRequests with
 * time-interval triggers, and receive foreground deliveries through the
 * UNUserNotificationCenterDelegate. A request is also written to the device's
 * shared SpringBoard directory, so the system UI can present it while the app
 * is suspended (the app's process is stopped and its timers do not run). */

#include "foundation_lite.h"

extern int printf(const char *fmt, ...);
extern int snprintf(char *buf, unsigned long size, const char *fmt, ...);
extern char *getenv(const char *name);
extern double atof(const char *s);
extern unsigned long strlen(const char *s);
extern int strcmp(const char *a, const char *b);
extern int strncmp(const char *a, const char *b, unsigned long n);
extern void *malloc(unsigned long size);
extern void free(void *ptr);
extern void *memcpy(void *dst, const void *src, unsigned long n);
extern void *memset(void *dst, int c, unsigned long n);
extern void *objc_msgSend(void *self, void *sel, ...);
extern double iosim_wall_time(void);
extern int iosim_fs_exists(const char *path);
extern int iosim_fs_read(const char *path, unsigned char **out,
                         unsigned long *out_len);
extern int iosim_fs_write(const char *path, const void *bytes,
                          unsigned long len);
extern int iosim_fs_remove(const char *path);
extern int iosim_fs_mkdir(const char *path, int intermediates);
extern void *_Block_copy(void *block);
extern const char *iosim_string_cstr(id string);

typedef unsigned long long un_time_t;
extern un_time_t dispatch_time(un_time_t when, long long delta);
extern void *dispatch_get_main_queue(void);
extern void dispatch_after(un_time_t when, void *queue, void *block);

/* UIKit is a sibling image: only the application state is needed here. */
@interface UIApplication : NSObject
+ (id)sharedApplication;
- (long)applicationState;
@end

enum {
    UIApplicationStateActive = 0,
    UIApplicationStateInactive = 1,
    UIApplicationStateBackground = 2
};

enum {
    UNAuthorizationStatusNotDetermined = 0,
    UNAuthorizationStatusDenied = 1,
    UNAuthorizationStatusAuthorized = 2,
    UNAuthorizationStatusProvisional = 3,
    UNAuthorizationStatusEphemeral = 4
};

enum {
    UNAuthorizationOptionBadge = 1,
    UNAuthorizationOptionSound = 2,
    UNAuthorizationOptionAlert = 4,
    UNAuthorizationOptionCarPlay = 8,
    UNAuthorizationOptionCriticalAlert = 16,
    UNAuthorizationOptionProvisional = 32,
    UNAuthorizationOptionProvidesAppNotificationSettings = 64
};

enum {
    UNNotificationSettingNotSupported = 0,
    UNNotificationSettingDisabled = 1,
    UNNotificationSettingEnabled = 2
};

enum {
    UNNotificationPresentationOptionBadge = 1,
    UNNotificationPresentationOptionSound = 2,
    UNNotificationPresentationOptionAlert = 4,
    UNNotificationPresentationOptionList = 8,
    UNNotificationPresentationOptionBanner = 16
};

@interface UNNotificationContent : NSObject {
@public
    id _title;
    id _subtitle;
    id _body;
    id _sound;
    id _badge;
    id _categoryIdentifier;
    id _threadIdentifier;
    id _userInfo;
    unsigned long _summaryArgumentCount;
    id _summaryArgument;
}
- (id)title;
- (void)setTitle:(id)title;
- (id)subtitle;
- (void)setSubtitle:(id)subtitle;
- (id)body;
- (void)setBody:(id)body;
- (id)sound;
- (void)setSound:(id)sound;
- (id)badge;
- (void)setBadge:(id)badge;
- (id)categoryIdentifier;
- (void)setCategoryIdentifier:(id)identifier;
- (id)threadIdentifier;
- (void)setThreadIdentifier:(id)identifier;
- (id)userInfo;
- (void)setUserInfo:(id)userInfo;
- (unsigned long)summaryArgumentCount;
- (void)setSummaryArgumentCount:(unsigned long)count;
- (id)summaryArgument;
- (void)setSummaryArgument:(id)argument;
@end

@interface UNMutableNotificationContent : UNNotificationContent
@end

@interface UNNotificationSound : NSObject {
@public
    id _name;
}
+ (id)defaultSound;
+ (id)soundNamed:(id)name;
- (id)name;
@end

enum {
    UNNotificationActionOptionAuthenticationRequired = 1,
    UNNotificationActionOptionDestructive = 2,
    UNNotificationActionOptionForeground = 4
};

@interface UNNotificationAction : NSObject {
@public
    id _identifier;
    id _title;
    unsigned long _options;
}
+ (id)actionWithIdentifier:(id)identifier title:(id)title
                   options:(unsigned long)options;
- (id)identifier;
- (id)title;
- (unsigned long)options;
@end

enum {
    UNNotificationCategoryOptionCustomDismissAction = 1,
    UNNotificationCategoryOptionAllowInCarPlay = 2
};

@interface UNNotificationCategory : NSObject {
@public
    id _identifier;
    id _actions;
    id _intentIdentifiers;
    unsigned long _options;
}
+ (id)categoryWithIdentifier:(id)identifier actions:(id)actions
            intentIdentifiers:(id)intentIdentifiers
                      options:(unsigned long)options;
- (id)identifier;
- (id)actions;
- (id)intentIdentifiers;
- (unsigned long)options;
@end

@interface UNNotificationTrigger : NSObject {
@public
    BOOL _repeats;
}
- (BOOL)repeats;
@end

@interface UNTimeIntervalNotificationTrigger : UNNotificationTrigger {
@public
    double _timeInterval;
}
+ (id)triggerWithTimeInterval:(double)interval repeats:(BOOL)repeats;
- (double)timeInterval;
- (id)nextTriggerDate;
@end

@interface UNNotificationRequest : NSObject {
@public
    id _identifier;
    UNNotificationContent *_content;
    UNNotificationTrigger *_trigger;
}
+ (id)requestWithIdentifier:(id)identifier content:(id)content
                    trigger:(id)trigger;
- (id)identifier;
- (id)content;
- (id)trigger;
@end

@interface UNNotification : NSObject {
@public
    UNNotificationRequest *_request;
    id _date;
}
- (id)request;
- (id)date;
@end

@interface UNNotificationResponse : NSObject {
@public
    UNNotification *_notification;
    id _actionIdentifier;
    id _userInfo;
}
- (id)notification;
- (id)actionIdentifier;
- (id)userInfo;
@end

@interface UNNotificationSettings : NSObject {
@public
    long _authorizationStatus;
    long _alertSetting;
    long _soundSetting;
    long _badgeSetting;
    long _notificationCenterSetting;
    long _lockScreenSetting;
    long _criticalAlertSetting;
    BOOL _alertStyle;
}
- (long)authorizationStatus;
- (long)alertSetting;
- (long)soundSetting;
- (long)badgeSetting;
- (long)notificationCenterSetting;
- (long)lockScreenSetting;
- (long)criticalAlertSetting;
@end

@interface UNUserNotificationCenter : NSObject {
@public
    id _delegate;
    long _authorizationStatus;
    unsigned long _authorizedOptions;
    NSMutableArray *_pending;
    NSMutableArray *_delivered;
    id _categories;
}
+ (id)currentNotificationCenter;
- (id)delegate;
- (void)setDelegate:(id)delegate;
- (void)requestAuthorizationWithOptions:(unsigned long)options
                      completionHandler:(void (^)(BOOL granted, id error))completion;
- (void)getNotificationSettingsWithCompletionHandler:
    (void (^)(id settings))completion;
- (void)addNotificationRequest:(UNNotificationRequest *)request
          withCompletionHandler:(void (^)(id error))completion;
- (void)removePendingNotificationRequestsWithIdentifiers:(id)identifiers;
- (void)removeAllPendingNotificationRequests;
- (void)getPendingNotificationRequestsWithCompletionHandler:
    (void (^)(id requests))completion;
- (void)getDeliveredNotificationsWithCompletionHandler:
    (void (^)(id notifications))completion;
- (void)removeDeliveredNotificationsWithIdentifiers:(id)identifiers;
- (void)removeAllDeliveredNotifications;
- (void)setNotificationCategories:(id)categories;
- (void)getNotificationCategoriesWithCompletionHandler:
    (void (^)(id categories))completion;
@end

@implementation UNNotificationAction
+ (id)actionWithIdentifier:(id)identifier title:(id)title
                   options:(unsigned long)options
{
    UNNotificationAction *action = [[self alloc] init];
    action->_identifier = identifier;
    action->_title = title;
    action->_options = options;
    return action;
}
- (id)identifier { return _identifier; }
- (id)title { return _title; }
- (unsigned long)options { return _options; }
@end

@implementation UNNotificationCategory
+ (id)categoryWithIdentifier:(id)identifier actions:(id)actions
            intentIdentifiers:(id)intentIdentifiers
                      options:(unsigned long)options
{
    UNNotificationCategory *category = [[self alloc] init];
    category->_identifier = identifier;
    category->_actions = actions;
    category->_intentIdentifiers = intentIdentifiers;
    category->_options = options;
    return category;
}
- (id)identifier { return _identifier; }
- (id)actions { return _actions; }
- (id)intentIdentifiers { return _intentIdentifiers; }
- (unsigned long)options { return _options; }
@end

@implementation UNNotificationContent
- (id)title { return _title; }
- (void)setTitle:(id)title { _title = title; }
- (id)subtitle { return _subtitle; }
- (void)setSubtitle:(id)subtitle { _subtitle = subtitle; }
- (id)body { return _body; }
- (void)setBody:(id)body { _body = body; }
- (id)sound { return _sound; }
- (void)setSound:(id)sound { _sound = sound; }
- (id)badge { return _badge; }
- (void)setBadge:(id)badge { _badge = badge; }
- (id)categoryIdentifier { return _categoryIdentifier; }
- (void)setCategoryIdentifier:(id)identifier { _categoryIdentifier = identifier; }
- (id)threadIdentifier { return _threadIdentifier; }
- (void)setThreadIdentifier:(id)identifier { _threadIdentifier = identifier; }
- (id)userInfo { return _userInfo; }
- (void)setUserInfo:(id)userInfo { _userInfo = userInfo; }
- (unsigned long)summaryArgumentCount { return _summaryArgumentCount; }
- (void)setSummaryArgumentCount:(unsigned long)count
{
    _summaryArgumentCount = count;
}
- (id)summaryArgument { return _summaryArgument; }
- (void)setSummaryArgument:(id)argument { _summaryArgument = argument; }
@end

@implementation UNMutableNotificationContent
@end

@implementation UNNotificationSound
+ (id)defaultSound
{
    UNNotificationSound *sound = [[self alloc] init];
    return sound;
}
+ (id)soundNamed:(id)name
{
    UNNotificationSound *sound = [[self alloc] init];
    sound->_name = name;
    return sound;
}
- (id)name { return _name; }
@end

@implementation UNNotificationTrigger
- (BOOL)repeats { return _repeats; }
@end

@implementation UNTimeIntervalNotificationTrigger
+ (id)triggerWithTimeInterval:(double)interval repeats:(BOOL)repeats
{
    UNTimeIntervalNotificationTrigger *trigger = [[self alloc] init];
    trigger->_timeInterval = interval;
    trigger->_repeats = repeats;
    return trigger;
}
- (double)timeInterval { return _timeInterval; }
- (id)nextTriggerDate
{
    return [NSDate dateWithTimeIntervalSinceNow:_timeInterval];
}
@end

@implementation UNNotificationRequest
+ (id)requestWithIdentifier:(id)identifier content:(id)content
                    trigger:(id)trigger
{
    UNNotificationRequest *request = [[self alloc] init];
    request->_identifier = identifier;
    request->_content = content;
    request->_trigger = trigger;
    return request;
}
- (id)identifier { return _identifier; }
- (id)content { return _content; }
- (id)trigger { return _trigger; }
@end

@implementation UNNotification
- (id)request { return _request; }
- (id)date { return _date; }
@end

@implementation UNNotificationResponse
- (id)notification { return _notification; }
- (id)actionIdentifier { return _actionIdentifier; }
- (id)userInfo { return _userInfo; }
@end

@implementation UNNotificationSettings
- (long)authorizationStatus { return _authorizationStatus; }
- (long)alertSetting { return _alertSetting; }
- (long)soundSetting { return _soundSetting; }
- (long)badgeSetting { return _badgeSetting; }
- (long)notificationCenterSetting { return _notificationCenterSetting; }
- (long)lockScreenSetting { return _lockScreenSetting; }
- (long)criticalAlertSetting { return _criticalAlertSetting; }
@end

/* ------------------------------------------------------- shared schedule
 *
 * The same request is stored where SpringBoard reads it. The file name is a
 * hash of the bundle id and request identifier so both processes agree on it.
 * Field values escape backslash, newline and carriage return. */

static void un_escape(const char *in, char *out, unsigned long cap)
{
    unsigned long o = 0;
    if (!in)
        in = "";
    for (; *in && o + 3 < cap; in++)
    {
        if (*in == '\n')
        {
            out[o++] = '\\';
            out[o++] = 'n';
        }
        else if (*in == '\r')
        {
            out[o++] = '\\';
            out[o++] = 'r';
        }
        else if (*in == '\\')
        {
            out[o++] = '\\';
            out[o++] = '\\';
        }
        else
            out[o++] = *in;
    }
    out[o] = 0;
}

/* Category definitions travel to SpringBoard through a second text file, so
 * an expanded banner can draw the same action buttons the app registered. */
static void un_escape_pipe(const char *in, char *out, unsigned long cap)
{
    unsigned long o = 0;
    if (!in)
        in = "";
    for (; *in && o + 3 < cap; in++)
    {
        if (*in == '\n')
        {
            out[o++] = '\\';
            out[o++] = 'n';
        }
        else if (*in == '\r')
        {
            out[o++] = '\\';
            out[o++] = 'r';
        }
        else if (*in == '\\')
        {
            out[o++] = '\\';
            out[o++] = '\\';
        }
        else if (*in == '|')
        {
            out[o++] = '\\';
            out[o++] = 'p';
        }
        else
            out[o++] = *in;
    }
    out[o] = 0;
}

static void un_badge_text(id badge, char *out, unsigned long cap)
{
    out[0] = 0;
    if (!badge)
        return;
    if ([badge isKindOfClass:[NSNumber class]])
    {
        snprintf(out, cap, "%ld", (long)[badge integerValue]);
        return;
    }
    const char *text = iosim_string_cstr(badge);
    if (text)
        snprintf(out, cap, "%s", text);
}

static void un_categories_write(id categories)
{
    const char *shared = getenv("SIMULATOR_SHARED_RESOURCES_DIRECTORY");
    if (!shared || !*shared)
        return;
    char dir[900];
    snprintf(dir, sizeof(dir), "%s/Library/SpringBoard", shared);
    iosim_fs_mkdir(dir, 1);
    char path[1100];
    snprintf(path, sizeof(path), "%s/notification-categories.txt", dir);
    id list = categories;
    if ([categories isKindOfClass:[NSSet class]])
        list = [categories allObjects];
    unsigned long count = list ? [list count] : 0;
    char buf[8000];
    int n = 0;
    for (unsigned long i = 0; i < count && n < (int)sizeof(buf) - 200; i++)
    {
        UNNotificationCategory *category = [list objectAtIndex:i];
        if (![category isKindOfClass:[UNNotificationCategory class]])
            continue;
        char identifier[300];
        un_escape_pipe(iosim_string_cstr(category->_identifier), identifier,
                       sizeof(identifier));
        n += snprintf(buf + n, sizeof(buf) - (unsigned long)n,
                      "category=%s\n", identifier);
        id actions = category->_actions;
        unsigned long actionCount = actions ? [actions count] : 0;
        for (unsigned long j = 0; j < actionCount &&
                                n < (int)sizeof(buf) - 200; j++)
        {
            UNNotificationAction *action = [actions objectAtIndex:j];
            if (![action isKindOfClass:[UNNotificationAction class]])
                continue;
            char actionId[300], title[300];
            un_escape_pipe(iosim_string_cstr(action->_identifier), actionId,
                           sizeof(actionId));
            un_escape_pipe(iosim_string_cstr(action->_title), title,
                           sizeof(title));
            n += snprintf(buf + n, sizeof(buf) - (unsigned long)n,
                          "action=%s|%s|%lu\n", actionId, title,
                          action->_options);
        }
        n += snprintf(buf + n, sizeof(buf) - (unsigned long)n, "end\n");
    }
    if (n > 0)
        iosim_fs_write(path, buf, (unsigned long)n);
}

static const char *un_bundle_id(void)
{
    id bundle = [NSBundle mainBundle];
    id identifier = bundle ? [bundle bundleIdentifier] : nil;
    if (!identifier)
        return "com.iosim.app";
    const char *text = iosim_string_cstr(identifier);
    return (text && *text) ? text : "com.iosim.app";
}

static unsigned long long un_hash(const char *a, const char *b)
{
    unsigned long long h = 1469598103934665603ULL;
    for (; a && *a; a++)
    {
        h ^= (unsigned char)*a;
        h *= 1099511628211ULL;
    }
    h ^= '|';
    h *= 1099511628211ULL;
    for (; b && *b; b++)
    {
        h ^= (unsigned char)*b;
        h *= 1099511628211ULL;
    }
    return h;
}

static int un_store_dir(char *out, unsigned long cap)
{
    const char *shared = getenv("SIMULATOR_SHARED_RESOURCES_DIRECTORY");
    if (!shared || !*shared)
    {
        out[0] = 0;
        return 0;
    }
    snprintf(out, cap, "%s/Library/SpringBoard/notifications", shared);
    iosim_fs_mkdir(out, 1);
    return 1;
}

static void un_store_path(UNNotificationRequest *request, char *out,
                          unsigned long cap)
{
    out[0] = 0;
    char dir[900];
    if (!un_store_dir(dir, sizeof(dir)))
        return;
    const char *identifier =
        request && request->_identifier
            ? iosim_string_cstr(request->_identifier)
            : "";
    unsigned long long h = un_hash(un_bundle_id(), identifier);
    char hex[17];
    for (int i = 15; i >= 0; i--)
    {
        int digit = (int)(h & 15);
        hex[i] = (char)(digit < 10 ? '0' + digit : 'a' + digit - 10);
        h >>= 4;
    }
    hex[16] = 0;
    snprintf(out, cap, "%s/%s.notif", dir, hex);
}

static void un_store_write(UNNotificationRequest *request, double fire)
{
    char path[1200];
    un_store_path(request, path, sizeof(path));
    if (!path[0])
        return;
    UNNotificationContent *content = request ? request->_content : nil;
    char title[600], subtitle[600], body[2200], identifier[300];
    char category[300], badge[64];
    un_escape(content ? iosim_string_cstr(content->_categoryIdentifier) : "",
              category, sizeof(category));
    un_badge_text(content ? content->_badge : nil, badge, sizeof(badge));
    un_escape(content ? iosim_string_cstr(content->_title) : "", title,
              sizeof(title));
    un_escape(content ? iosim_string_cstr(content->_subtitle) : "", subtitle,
              sizeof(subtitle));
    un_escape(content ? iosim_string_cstr(content->_body) : "", body,
              sizeof(body));
    un_escape(request && request->_identifier
                  ? iosim_string_cstr(request->_identifier)
                  : "",
              identifier, sizeof(identifier));
    int repeats = 0;
    double interval = 0;
    if (request && request->_trigger &&
        [request->_trigger isKindOfClass:
            [UNTimeIntervalNotificationTrigger class]])
    {
        UNTimeIntervalNotificationTrigger *trigger =
            (UNTimeIntervalNotificationTrigger *)request->_trigger;
        repeats = trigger->_repeats ? 1 : 0;
        interval = trigger->_timeInterval;
    }
    char buf[4200];
    int n = snprintf(buf, sizeof(buf),
                     "bundle=%s\nid=%s\nfire=%.6f\nrepeats=%d\n"
                     "interval=%.6f\ntitle=%s\nsubtitle=%s\nbody=%s\n"
                     "category=%s\nbadge=%s\n",
                     un_bundle_id(), identifier, fire, repeats, interval,
                     title, subtitle, body, category, badge);
    if (n > 0)
        iosim_fs_write(path, buf, (unsigned long)n);
}

static void un_store_remove(UNNotificationRequest *request)
{
    char path[1200];
    un_store_path(request, path, sizeof(path));
    if (path[0])
        iosim_fs_remove(path);
}

/* 1 when the file exists; *fire receives its absolute fire time. */
static int un_store_fire(UNNotificationRequest *request, double *fire)
{
    char path[1200];
    un_store_path(request, path, sizeof(path));
    if (!path[0])
        return 0;
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(path, &bytes, &length) != 0 || !bytes)
        return 0;
    char buf[4200];
    if (length >= sizeof(buf))
        length = sizeof(buf) - 1;
    memcpy(buf, bytes, length);
    buf[length] = 0;
    free(bytes);
    const char *p = buf;
    while (*p)
    {
        if (strncmp(p, "fire=", 5) == 0)
        {
            *fire = atof(p + 5);
            return 1;
        }
        while (*p && *p != '\n')
            p++;
        if (*p)
            p++;
    }
    return 0;
}

static UNUserNotificationCenter *g_un_center;

/* SpringBoard writes a response file when the user taps a banner or a
 * Notification Center card. The app process may have been stopped at that
 * moment, so the center polls for the file and delivers it once its delegate
 * exists. */
static int un_response_field(const char *line, unsigned long len,
                             const char *key, char *out, unsigned long cap)
{
    unsigned long k = strlen(key);
    if (len < k || strncmp(line, key, k) != 0)
        return 0;
    unsigned long o = 0;
    const char *p = line + k;
    const char *end = line + len;
    while (p < end && o + 1 < cap)
    {
        if (p[0] == '\\' && p + 1 < end && p[1] == 'n')
        {
            out[o++] = '\n';
            p += 2;
        }
        else if (p[0] == '\\' && p + 1 < end && p[1] == '\\')
        {
            out[o++] = '\\';
            p += 2;
        }
        else
            out[o++] = *p++;
    }
    out[o] = 0;
    return 1;
}

static void un_check_response(void)
{
    UNUserNotificationCenter *center = g_un_center;
    if (!center || !center->_delegate)
        return;
    char shared[900];
    const char *sharedEnv = getenv("SIMULATOR_SHARED_RESOURCES_DIRECTORY");
    if (!sharedEnv || !*sharedEnv)
        return;
    snprintf(shared, sizeof(shared), "%s", sharedEnv);
    char path[1100];
    snprintf(path, sizeof(path), "%s/Library/SpringBoard/"
             "notification-response.txt", shared);
    unsigned char *bytes = 0;
    unsigned long length = 0;
    if (iosim_fs_read(path, &bytes, &length) != 0 || !bytes)
        return;
    char buf[4200];
    if (length >= sizeof(buf))
        length = sizeof(buf) - 1;
    memcpy(buf, bytes, length);
    buf[length] = 0;
    free(bytes);
    char bundle[128] = "", identifier[128] = "", action[128] = "";
    char title[512] = "", body[2048] = "";
    const char *p = buf;
    while (*p)
    {
        const char *line = p;
        while (*p && *p != '\n')
            p++;
        unsigned long len = (unsigned long)(p - line);
        un_response_field(line, len, "bundle=", bundle, sizeof(bundle));
        un_response_field(line, len, "id=", identifier, sizeof(identifier));
        un_response_field(line, len, "action=", action, sizeof(action));
        un_response_field(line, len, "title=", title, sizeof(title));
        un_response_field(line, len, "body=", body, sizeof(body));
        if (*p)
            p++;
    }
    if (strcmp(bundle, un_bundle_id()) != 0)
        return;
    id delegate = center->_delegate;
    if (![delegate respondsToSelector:
            @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:)])
        return;
    UNMutableNotificationContent *content =
        [[UNMutableNotificationContent alloc] init];
    content->_title = [NSString stringWithUTF8String:title];
    content->_body = [NSString stringWithUTF8String:body];
    UNNotificationRequest *request = [UNNotificationRequest
        requestWithIdentifier:[NSString stringWithUTF8String:identifier]
                      content:content
                      trigger:nil];
    UNNotification *notification = [[UNNotification alloc] init];
    notification->_request = request;
    notification->_date = [NSDate date];
    UNNotificationResponse *response = [[UNNotificationResponse alloc] init];
    response->_notification = notification;
    response->_actionIdentifier =
        [NSString stringWithUTF8String:(action[0] ? action :
            "com.apple.UNNotificationDefaultActionIdentifier")];
    [center->_delivered addObject:notification];
    SEL sel = @selector(userNotificationCenter:didReceiveNotificationResponse:withCompletionHandler:);
    void (^completion)(void) = ^{
    };
    ((void (*)(id, void *, id, id, id))objc_msgSend)(
        delegate, (void *)sel, center, response, (id)completion);
    iosim_fs_remove(path);
}

static void un_poll_response(void)
{
    un_check_response();
    dispatch_after(dispatch_time(0, 250 * 1000000LL),
                   dispatch_get_main_queue(), ^{
        un_poll_response();
    });
}

static void un_fire(UNNotificationRequest *request)
{
    UNUserNotificationCenter *center = g_un_center;
    if (!center || !request)
        return;
    unsigned long index = [center->_pending indexOfObject:request];
    if (index == (unsigned long)-1)
        return;
    char dir[900];
    int stored = un_store_dir(dir, sizeof(dir));
    double fire = 0;
    int haveFire = stored ? un_store_fire(request, &fire) : 0;
    if (stored && !haveFire)
    {
        /* Another process already consumed this request. */
        [center->_pending removeObject:request];
        return;
    }
    double now = iosim_wall_time();
    if (stored && haveFire && fire > now + 0.25)
    {
        /* A repeat the system UI rescheduled while the app was away. */
        long long delta = (long long)((fire - now) * 1e9);
        if (delta < 1000000LL)
            delta = 1000000LL;
        dispatch_after(dispatch_time(0, delta), dispatch_get_main_queue(), ^{
            un_fire(request);
        });
        return;
    }
    int repeats = 0;
    double interval = 0;
    if (request->_trigger &&
        [request->_trigger isKindOfClass:
            [UNTimeIntervalNotificationTrigger class]])
    {
        UNTimeIntervalNotificationTrigger *trigger =
            (UNTimeIntervalNotificationTrigger *)request->_trigger;
        repeats = trigger->_repeats ? 1 : 0;
        interval = trigger->_timeInterval;
    }
    if (repeats && interval > 0.05)
    {
        un_store_write(request, now + interval);
        dispatch_after(dispatch_time(0, (long long)(interval * 1e9)),
                       dispatch_get_main_queue(), ^{
            un_fire(request);
        });
    }
    else
    {
        [center->_pending removeObject:request];
        if (stored)
            un_store_remove(request);
    }
    UNNotification *notification = [[UNNotification alloc] init];
    notification->_request = request;
    notification->_date = [NSDate date];
    [center->_delivered addObject:notification];
    id delegate = center->_delegate;
    if (delegate && [delegate respondsToSelector:
            @selector(userNotificationCenter:willPresentNotification:withCompletionHandler:)])
    {
        SEL sel = @selector(userNotificationCenter:willPresentNotification:withCompletionHandler:);
        void (^completion)(unsigned long) = ^(unsigned long options) {
            (void)options;
        };
        ((void (*)(id, void *, id, id, id))objc_msgSend)(
            delegate, (void *)sel, center, notification, (id)completion);
    }
}

@implementation UNUserNotificationCenter
+ (id)currentNotificationCenter
{
    static UNUserNotificationCenter *center;
    if (!center)
        center = [[self alloc] init];
    return center;
}
- (id)init
{
    self = [super init];
    if (self)
    {
        _authorizationStatus = UNAuthorizationStatusNotDetermined;
        _pending = [[NSMutableArray alloc] init];
        _delivered = [[NSMutableArray alloc] init];
        g_un_center = self;
        un_poll_response();
    }
    return self;
}
- (id)delegate { return _delegate; }
- (void)setDelegate:(id)delegate { _delegate = delegate; }
- (void)requestAuthorizationWithOptions:(unsigned long)options
                      completionHandler:(void (^)(BOOL granted, id error))completion
{
    _authorizedOptions |= options;
    _authorizationStatus = options ? UNAuthorizationStatusAuthorized
                                   : UNAuthorizationStatusDenied;
    if (completion)
        completion(_authorizationStatus == UNAuthorizationStatusAuthorized,
                   nil);
}
- (void)getNotificationSettingsWithCompletionHandler:
    (void (^)(id settings))completion
{
    UNNotificationSettings *settings = [[UNNotificationSettings alloc] init];
    settings->_authorizationStatus = _authorizationStatus;
    long setting = _authorizationStatus == UNAuthorizationStatusAuthorized
                       ? UNNotificationSettingEnabled
                       : UNNotificationSettingDisabled;
    settings->_alertSetting = setting;
    settings->_soundSetting = setting;
    settings->_badgeSetting = setting;
    settings->_notificationCenterSetting = setting;
    settings->_lockScreenSetting = setting;
    settings->_criticalAlertSetting = UNNotificationSettingNotSupported;
    if (completion)
        completion(settings);
}
- (void)addNotificationRequest:(UNNotificationRequest *)request
          withCompletionHandler:(void (^)(id error))completion
{
    if (!request)
    {
        if (completion)
            completion([NSError errorWithDomain:@"UNErrorDomain" code:1
                                        userInfo:nil]);
        return;
    }
    for (unsigned long i = 0; i < [_pending count]; i++)
    {
        UNNotificationRequest *pending = [_pending objectAtIndex:i];
        if (pending->_identifier && request->_identifier &&
            [pending->_identifier isEqual:request->_identifier])
        {
            [_pending removeObjectAtIndex:i];
            break;
        }
    }
    [_pending addObject:request];
    double interval = 0;
    if (request->_trigger &&
        [request->_trigger isKindOfClass:
            [UNTimeIntervalNotificationTrigger class]])
        interval = ((UNTimeIntervalNotificationTrigger *)request->_trigger)
                       ->_timeInterval;
    if (interval < 0.05)
        interval = 0.05;
    un_store_write(request, iosim_wall_time() + interval);
    dispatch_after(dispatch_time(0, (long long)(interval * 1e9)),
                   dispatch_get_main_queue(), ^{
        un_fire(request);
    });
    if (completion)
        completion(nil);
}
- (void)removePendingNotificationRequestsWithIdentifiers:(id)identifiers
{
    if (!identifiers)
        return;
    unsigned long count = [identifiers count];
    for (unsigned long i = 0; i < count; i++)
    {
        id identifier = [identifiers objectAtIndex:i];
        for (unsigned long j = 0; j < [_pending count]; j++)
        {
            UNNotificationRequest *pending = [_pending objectAtIndex:j];
            if (pending->_identifier &&
                [pending->_identifier isEqual:identifier])
            {
                un_store_remove(pending);
                [_pending removeObjectAtIndex:j];
                break;
            }
        }
    }
}
- (void)removeAllPendingNotificationRequests
{
    for (unsigned long i = 0; i < [_pending count]; i++)
        un_store_remove([_pending objectAtIndex:i]);
    [_pending removeAllObjects];
}
- (void)getPendingNotificationRequestsWithCompletionHandler:
    (void (^)(id requests))completion
{
    if (completion)
        completion([NSArray arrayWithArray:_pending]);
}
- (void)getDeliveredNotificationsWithCompletionHandler:
    (void (^)(id notifications))completion
{
    if (completion)
        completion([NSArray arrayWithArray:_delivered]);
}
- (void)removeDeliveredNotificationsWithIdentifiers:(id)identifiers
{
    if (!identifiers)
        return;
    unsigned long count = [identifiers count];
    for (unsigned long i = 0; i < count; i++)
    {
        id identifier = [identifiers objectAtIndex:i];
        for (unsigned long j = 0; j < [_delivered count]; j++)
        {
            UNNotification *notification = [_delivered objectAtIndex:j];
            if (notification->_request &&
                notification->_request->_identifier &&
                [notification->_request->_identifier isEqual:identifier])
            {
                [_delivered removeObjectAtIndex:j];
                break;
            }
        }
    }
}
- (void)removeAllDeliveredNotifications
{
    [_delivered removeAllObjects];
}
- (void)setNotificationCategories:(id)categories
{
    _categories = categories;
    un_categories_write(categories);
}
- (void)getNotificationCategoriesWithCompletionHandler:
    (void (^)(id categories))completion
{
    if (completion)
        completion(_categories);
}
@end

NSString *const UNNotificationDefaultActionIdentifier =
    @"com.apple.UNNotificationDefaultActionIdentifier";
