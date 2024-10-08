/*
 * Example 1D LUT shader
 *
 * To use:
 * 0. This assumes the calibrations curves are in a argyllcms format and they are extractable from a vcgt tag in a ICC
 * 1. Obtain calibration curves(.cal files) from a existing ICC work directory or dump it using 'iccvcgt -x $ICC' from argyllcms
 * 2. Use the '1dlut.sh $CAL $TEMPLATE' script to automatically fill the '1DLUT_REPLACE_*' placeholders
 * 3. Copy this shader to `~/.config/hypr/lut.glsl` and enable it with the command:
 *    `hyprctl keyword decoration:screen_shader "lut.glsl"`
*/

#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform vec2 screen_size;
uniform sampler2D tex;
out vec4 fragColor;

const bool test = false;

const vec3 LUT[1DLUT_REPLACE_NUMBER] = vec3[](
    1DLUT_REPLACE_LIST
);

void main() {
    vec4 color = texture(tex, v_texcoord);

    float LUT_max = float(LUT.length()-1);

    vec3 LUT_color = color.rgb * LUT_max;

    int rIndexLo = int(LUT_color.r);
    int rIndexHi = int(ceil(LUT_color.r));
    int gIndexLo = int(LUT_color.g);
    int gIndexHi = int(ceil(LUT_color.g));
    int bIndexLo = int(LUT_color.b);
    int bIndexHi = int(ceil(LUT_color.b));

    fragColor = vec4(
        mix(LUT[rIndexLo].r, LUT[rIndexHi].r, fract(LUT_color.r)),
        mix(LUT[gIndexLo].g, LUT[gIndexHi].g, fract(LUT_color.g)),
        mix(LUT[bIndexLo].b, LUT[bIndexHi].b, fract(LUT_color.b)),
        color.a
    );

    if ( test && gl_FragCoord.x > screen_size.x/2.0 ) {
        fragColor = color;
    }
}
