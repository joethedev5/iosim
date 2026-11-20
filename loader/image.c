/* PNG decoding for UIImage. Kept in the loader so the UIKit dylib only deals
 * in decoded RGBA buffers. */
#include "image.h"

#include <png.h>
#include <stdlib.h>
#include <string.h>

int iosim_png_load(const char *path, unsigned char **out_rgba,
                     int *out_width, int *out_height)
{
    if (!path || !out_rgba || !out_width || !out_height)
        return -1;
    *out_rgba = NULL;
    *out_width = *out_height = 0;

    png_image image;
    memset(&image, 0, sizeof(image));
    image.version = PNG_IMAGE_VERSION;
    if (!png_image_begin_read_from_file(&image, path))
        return -1;
    image.format = PNG_FORMAT_RGBA;
    size_t size = PNG_IMAGE_SIZE(image);
    unsigned char *pixels = malloc(size);
    if (!pixels)
    {
        png_image_free(&image);
        return -1;
    }
    if (!png_image_finish_read(&image, NULL, pixels, 0, NULL))
    {
        free(pixels);
        png_image_free(&image);
        return -1;
    }
    *out_rgba = pixels;
    *out_width = (int)image.width;
    *out_height = (int)image.height;
    png_image_free(&image);
    return 0;
}
