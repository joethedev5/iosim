/* Foundation-lite: enough of NSLog to run a Foundation-linked simulator
 * binary against the iosim runtime root. */
extern void iosim_nslog(const char *message);

struct cf_constant_string {
    void *isa;
    unsigned int flags;
    unsigned int pad;
    const char *cstr;
    unsigned long length;
};

void NSLog(void *format, ...)
{
    const char *s = 0;
    if (format)
    {
        struct cf_constant_string *cs = format;
        if (cs->flags == 0x7c8 && cs->cstr)
            s = cs->cstr;
    }
    iosim_nslog(s ? s : "(NSLog format object)");
}
