/* UITextView handle dragging: the knobs drawn under a selection are hit
 * targets. Dragging the end knob extends the range; dragging the start knob
 * moves the selection's start. */
#include "UIKitStub.h"

extern int printf(const char *fmt, ...);
extern int iosim_fb_font_text_width(const char *text, int style,
                                    double size_pt, double scale);
extern void iosim_fb_font_metrics(int style, double size_pt, double scale,
                                  int *ascent, int *descent,
                                  int *line_height);

static NSRange drag(UITextView *editor, CGPoint from, CGPoint to)
{
    UITouch *touch = [[UITouch alloc] init];
    touch->_location = from;
    touch->_previousLocation = from;
    touch->_phase = UITouchPhaseBegan;
    [editor touchesBegan:[NSSet setWithObject:touch] withEvent:nil];
    touch->_previousLocation = from;
    touch->_location = to;
    touch->_phase = UITouchPhaseMoved;
    [editor touchesMoved:[NSSet setWithObject:touch] withEvent:nil];
    touch->_phase = UITouchPhaseEnded;
    [editor touchesEnded:[NSSet setWithObject:touch] withEvent:nil];
    return [editor selectedRange];
}

int main(void)
{
    UITextView *editor =
        [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 300, 200)];
    editor.font = [UIFont systemFontOfSize:24];
    editor.text = @"hello world";
    [editor setSelectedRange:NSMakeRange(0, 5)];

    double scale = [[UIScreen mainScreen] scale];
    int ascent = 0, descent = 0, line_height = 0;
    iosim_fb_font_metrics(0, 24.0, scale, &ascent, &descent, &line_height);
    double line_height_pt = line_height / scale;
    double knob_y = 12.0 + line_height_pt + 6.0;
    double end_x = 12.0 +
        iosim_fb_font_text_width("hello", 0, 24.0, scale) / scale;
    printf("[handle] knob %d %d\n", end_x > 30.0 && end_x < 120.0,
           knob_y > 20.0 && knob_y < 80.0);

    NSRange grown = drag(editor, CGPointMake(end_x, knob_y),
                         CGPointMake(end_x + 20.0, knob_y));
    printf("[handle] end %d %d\n",
           grown.location == 0 && grown.length > 5,
           grown.length < 11);

    NSRange moved = drag(editor, CGPointMake(12.0, knob_y),
                         CGPointMake(52.0, knob_y));
    printf("[handle] start %d\n", moved.location > 0 && moved.length > 0);
    return 0;
}
