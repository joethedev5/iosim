/* UITextFieldDelegate fixture: begin/end editing, character-change veto,
 * Return handling and editing events, without a window or keyboard. */
#import "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int strcmp(const char *a, const char *b);

@interface FieldDelegate : NSObject {
@public
    int allow_changes;
    int began;
    int ended;
    int changes;
    int returns;
}
@end

@implementation FieldDelegate
- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    (void)textField;
    return YES;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    (void)textField;
    began++;
}
- (BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
    (void)textField;
    return YES;
}
- (void)textFieldDidEndEditing:(UITextField *)textField
{
    (void)textField;
    ended++;
}
- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string
{
    (void)textField;
    (void)range;
    changes++;
    if (!allow_changes || strcmp([string UTF8String], "x") == 0)
        return NO;
    return YES;
}
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    (void)textField;
    returns++;
    return YES;
}
@end

int main(void)
{
    UITextField *field = [[UITextField alloc]
        initWithFrame:CGRectMake(0, 0, 200, 30)];
    FieldDelegate *delegate = [[FieldDelegate alloc] init];
    delegate->allow_changes = 1;
    [field setDelegate:delegate];

    [field becomeFirstResponder];
    [field insertText:@"a"];
    [field insertText:@"b"];
    [field insertText:@"x"];
    [field deleteBackward];
    [field insertText:@"\n"];
    NSString *afterReturn = [field text];
    [field resignFirstResponder];

    printf("[tf] text [%s] began %d ended %d changes %d returns %d\n",
           afterReturn ? [afterReturn UTF8String] : "",
           delegate->began, delegate->ended, delegate->changes,
           delegate->returns);
    return 0;
}
