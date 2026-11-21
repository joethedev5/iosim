#ifndef IOSIM_IMAGE_H
#define IOSIM_IMAGE_H

int iosim_png_load(const char *path, unsigned char **out_rgba,
                     int *out_width, int *out_height);
int iosim_png_load_memory(const unsigned char *bytes, unsigned long length,
                          unsigned char **out_rgba, int *out_width,
                          int *out_height);

#endif
