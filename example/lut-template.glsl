/*
 * Example 1D and 3D LUT shader
 *
 * 1D LUT
 * To use:
 * 0. This assumes the calibrations curves are in a argyllcms format and they are extractable from a vcgt tag in a ICC
 * 1. Obtain calibration curves(.cal files) from a existing ICC work directory or dump it using 'iccvcgt -x $ICC' from argyllcms
 * 2. Use the '1dlut.sh $CAL $TEMPLATE' script to automatically fill the '1DLUT_REPLACE_*' placeholders
 * 3. Copy this shader to `~/.config/hypr/lut.glsl`
 * 4. Uncomment #define _1DLUT and enable it with the command:
 *    `hyprctl keyword decoration:screen_shader "lut.glsl"`
 *
 * 3D LUT
 * adapted from https://lettier.github.io/3d-game-shaders-for-beginners/lookup-table.html
 *
 * To use:
 * 0. Requires hyprland patch from https://github.com/gnusenpai/Hyprland/tree/lut for PNG LUT support
 * 1. Find or generate a strip-style 3D LUT, if using a color correction LUT do not add the vcgt tag
 *    (https://github.com/gnusenpai/lut-generator was used to test)
 * 2. Copy it to `~/.config/hypr/lut.png` and load it with the command:
 *    `hyprctl keyword decoration:lut "lut.png"`
 * 3. Copy this shader to `~/.config/hypr/lut.glsl`
 * 4. Uncomment #define _3DLUT and enable it with the command:
 *    `hyprctl keyword decoration:screen_shader "lut.glsl"`
*/

#version 320 es
precision highp float;

/* Enable 1DLUT code */
//#define _1DLUT
/* Enable 3DLUT code */
//#define _3DLUT
/* Cutoff bits before transformation */
//#define TVCUTOFF
/* No interpolation for 1DLUTs */
//#define _1DNOINTERPOLATION

in vec2 v_texcoord;
uniform vec2 screen_size;
uniform sampler2D tex;
out vec4 fragColor;

#ifdef _1DLUT
    /* check vars */
    #ifndef _3DLUT
        #define O1DLUT
        #define PRIMARY1DCOLOR color
    #else
        #define PRIMARY1DCOLOR _3dlutcache
    #endif
    #define USELUT
#endif

#ifdef _3DLUT
    #define PRIMARY3DCOLOR color
    uniform sampler2D lut;
    uniform vec2 lut_size;

    const float mult = 1.0;
    #ifdef _1DLUT
        /* check vars */
        #define _13DLUT
    #else
        /* check vars */
        #define O3DLUT
        #define USELUT
    #endif
#endif

#ifdef USELUT
    //#define DEBUG
    #ifdef DEBUG
        /* Enable two different color transformations */
        #define TEST
        #ifdef TEST
            #ifdef _3DLUT
                /* Enable 3DLUT image preview + mixing */
                #define LUTPREVIEW
            #endif

            /* Where second transformation should start and how big */
            #define XCUTSTART screen_size.x/2.0
            #define YCUTSTART 0.0
            #define XCUTSPACING screen_size.x
            #define YCUTSPACING screen_size.y
            /* Change relative spacing to absolute position */
            #define ABSOLUTE
            #ifndef ABSOLUTE
                #define XABSOLUTEVAR XCUTSTART+XCUTSPACING
                #define YABSOLUTEVAR YCUTSTART+YCUTSPACING
            #else
                #define XABSOLUTEVAR XCUTSPACING
                #define YABSOLUTEVAR YCUTSPACING
            #endif

            /* Bypass TVCUTOFF */
            //#define REAL
            #ifndef REAL
                #define SECONDARYCOLOR color
            #else
                #define SECONDARYCOLOR realcolor
            #endif

            /* Select 1DLUT/13DLUT pathway */
            #ifdef _1DLUT
                //#define _1DSEL
            #endif

            /* Select 3DLUT pathway */
            #ifdef _3DLUT
                //#define _3DSEL
            #endif

            #ifdef _1DSEL
                #ifdef _3DLUT
                    /* Enable 13DLUT */
                    //#define COL3D
                    #ifdef COL3D
                        #define SECONDARY1DCOLOR _3dlutsecondcache
                    #endif
                #endif

                #ifndef SECONDARY1DCOLOR
                    #define SECONDARY1DCOLOR SECONDARYCOLOR
                #endif

                #define SECONDARYFUNCT _1dlutfunct(SECONDARY1DCOLOR)
            #elif defined _3DSEL
                #define SECONDARYFUNCT mixLUTs(sampleLUTf(SECONDARYCOLOR), sampleLUTc(SECONDARYCOLOR), SECONDARYCOLOR)
            #else
                #define SECONDARYFUNCT SECONDARYCOLOR
            #endif
        #endif
    #endif
#endif

#ifdef TVCUTOFF
    /* Custom cutoff point */
    //#define CUSTOMCUTOFF
    #ifndef CUSTOMCUTOFF
        /* Cutoff <17(256) bits before transformation */
        #define CUTOFFFLOAT 0.06640625
    #else
        #define CUTOFFFLOAT 0.12109375
    #endif
#endif

#ifdef USELUT
    #ifdef O3DLUT
        #define PRIMARYFUNCT mixLUTs(sampleLUTf(PRIMARY3DCOLOR), sampleLUTc(PRIMARY3DCOLOR), PRIMARY3DCOLOR);
    #else
        #define PRIMARYFUNCT _1dlutfunct(PRIMARY1DCOLOR);
    #endif
#endif

#ifdef _1DLUT
    const vec3 LUT[1DLUT_REPLACE_NUMBER] = vec3[](
    1DLUT_REPLACE_LIST
    );

    vec4 _1dlutfunct(vec4 color) {
    float LUT_max = float(LUT.length()-1);
    vec3 LUT_color = color.rgb * LUT_max;

    int rIndexLo = int(LUT_color.r);
    int gIndexLo = int(LUT_color.g);
    int bIndexLo = int(LUT_color.b);
    #ifndef _1DNOINTERPOLATION
        int rIndexHi = int(ceil(LUT_color.r));
        int gIndexHi = int(ceil(LUT_color.g));
        int bIndexHi = int(ceil(LUT_color.b));
    #endif

        return vec4(
        #ifndef _1DNOINTERPOLATION
                mix(LUT[rIndexLo].r, LUT[rIndexHi].r, fract(LUT_color.r)),
                mix(LUT[gIndexLo].g, LUT[gIndexHi].g, fract(LUT_color.g)),
                mix(LUT[bIndexLo].b, LUT[bIndexHi].b, fract(LUT_color.b)),
        #else
                LUT[rIndexLo].r,
                LUT[gIndexLo].g,
                LUT[bIndexLo].b,
        #endif
                color.a
        );
    }
#endif

#ifdef _3DLUT
    vec4 sampleLUTf(vec4 color) {
        float u = (floor(color.b * (lut_size.y-1.0)) / (lut_size.y-1.0)) * ((lut_size.x-1.0) - (lut_size.y-1.0));
              u += (floor(color.r * (lut_size.y-1.0)) / (lut_size.y-1.0)) * (lut_size.y-1.0);
              u += 0.5;
              u /= lut_size.x;
        float v = (floor(color.g * (lut_size.y-1.0)) / (lut_size.y-1.0)) * (lut_size.y-1.0);
              v += 0.5;
              v /= lut_size.y;

        return texture(lut, vec2(u, v));
    }

    vec4 sampleLUTc(vec4 color) {
        float u = (ceil(color.b * (lut_size.y-1.0)) / (lut_size.y-1.0)) * ((lut_size.x-1.0) - (lut_size.y-1.0));
              u += (ceil(color.r * (lut_size.y-1.0)) / (lut_size.y-1.0)) * (lut_size.y-1.0);
              u += 0.5;
              u /= lut_size.x;
        float v = (ceil(color.g * (lut_size.y-1.0)) / (lut_size.y-1.0)) * (lut_size.y-1.0);
              v += 0.5;
              v /= lut_size.y;

        return texture(lut, vec2(u, v));
    }

    vec4 mixLUTs(vec4 left, vec4 right, vec4 color) {
        return vec4(
            mix(left.r, right.r, fract(color.r * (lut_size.y-1.0))),
            mix(left.g, right.g, fract(color.g * (lut_size.y-1.0))),
            mix(left.b, right.b, fract(color.b * (lut_size.y-1.0))),
            color.a
        );
    }
#endif


void main() {
    vec4 color = texture(tex, v_texcoord);
    #ifdef REAL
        vec4 realcolor = color;
    #endif

    #ifdef TVCUTOFF
        if ( color.r == color.g && color.r == color.b && color.r < CUTOFFFLOAT ) {
            color.r = 0.0;
            color.g = 0.0;
            color.b = 0.0;
        }
    #endif

    #ifdef TEST
        float x = gl_FragCoord.x;
        float y = gl_FragCoord.y;
        #ifdef _13DLUT
            vec4 PRIMARY1DCOLOR = mixLUTs(sampleLUTf(PRIMARY3DCOLOR), sampleLUTc(PRIMARY3DCOLOR), PRIMARY3DCOLOR);
            #ifdef COL3D
                vec4 SECONDARY1DCOLOR = mixLUTs(sampleLUTf(SECONDARYCOLOR), sampleLUTc(SECONDARYCOLOR), SECONDARYCOLOR);
            #endif
        #endif

        #ifdef LUTPREVIEW
            const vec4 testColor = vec4(133./255., 133./255., 133./255., 1);
            vec4 testLeft = sampleLUTf(testColor);
            vec4 testRight = sampleLUTc(testColor);

            /* LUT texture preview */
            if ( x < lut_size.x*mult && y < lut_size.y*mult ) {
                fragColor = texture(lut, vec2(x,y) / lut_size / mult);
            /* Left LUT sampler preview */
            } else if ( x < lut_size.y*mult && y < lut_size.y*mult*2.0 && y > lut_size.y*mult ) {
                fragColor = testLeft;
            /* Right LUT sampler preview */
            } else if ( x < lut_size.y*mult*2.0 && y < lut_size.y*mult*2.0 && y > lut_size.y*mult ) {
                fragColor = testRight;
            /* Mixed LUT sampler preview */
            } else if ( x < lut_size.y*mult*3.0 && y < lut_size.y*mult*2.0 && y > lut_size.y*mult ) {
                fragColor = mixLUTs(testLeft, testRight, testColor);
            /* Left screen (LUTs applied) */
            } else if ( x > XCUTSTART && x < XABSOLUTEVAR && y > YCUTSTART && y < YABSOLUTEVAR ) {
        #else
            /* Left screen (LUTs applied) */
            if ( x > XCUTSTART && x < XABSOLUTEVAR && y > YCUTSTART && y < YABSOLUTEVAR ) {
        #endif
            fragColor = SECONDARYFUNCT;
        /* Right screen (No/Secondary LUTs applied) */
        } else {
            fragColor = PRIMARYFUNCT;
        }
    #elif defined USELUT
        #ifdef _13DLUT
            vec4 PRIMARY1DCOLOR = mixLUTs(sampleLUTf(PRIMARY3DCOLOR), sampleLUTc(PRIMARY3DCOLOR), PRIMARY3DCOLOR);
        #endif
        fragColor = PRIMARYFUNCT;
    #else
        fragColor = color;
    #endif
}
