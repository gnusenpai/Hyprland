/*
 * Example 3D LUT shader
 * adapted from https://lettier.github.io/3d-game-shaders-for-beginners/lookup-table.html
 *
 * To use:
 * 1. Find or generate a strip-style 3D LUT, if using a color correction LUT you should add the vcgt tag
 *    (https://github.com/gnusenpai/lut-generator was used to test)
 * 2. Copy it to `~/.config/hypr/lut.png` and load it with the command:
 *    `hyprctl keyword decoration:lut "lut.png"`
 * 3. Copy this shader to `~/.config/hypr/lut.glsl` and enable it with the command:
 *    `hyprctl keyword decoration:screen_shader "lut.glsl"`
*/

#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform vec2 screen_size;
uniform sampler2D tex;
uniform sampler2D lut;
uniform vec2 lut_size;
out vec4 fragColor;

const float mult = 1.0;

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

void main() {
    vec4 color = texture(tex, v_texcoord);
    float x = gl_FragCoord.x;
    float y = gl_FragCoord.y;

    vec4 testColor = vec4(133./255., 133./255., 133./255., 1);
    vec4 testLeft = sampleLUTf(testColor);
    vec4 testRight = sampleLUTc(testColor);

    // LUT texture preview
    if ( x < lut_size.x*mult && y < lut_size.y*mult ) {
        fragColor = texture(lut, vec2(x,y) / lut_size / mult);
    // Left LUT sampler preview
    } else if ( x < lut_size.y*mult && y < lut_size.y*mult*2.0 && y > lut_size.y*mult) {
        fragColor = testLeft;
    // Right LUT sampler preview
    } else if ( x < lut_size.y*mult*2.0 && y < lut_size.y*mult*2.0 && y > lut_size.y*mult) {
        fragColor = testRight;
    // Mixed LUT sampler preview
    } else if ( x < lut_size.y*mult*3.0 && y < lut_size.y*mult*2.0 && y > lut_size.y*mult) {
        fragColor = mixLUTs(testLeft, testRight, testColor);
    // Left screen (LUT applied)
    } else if ( x < screen_size.x/2.0 ) {
        fragColor = mixLUTs(sampleLUTf(color), sampleLUTc(color), color);
    // Right screen (no LUT applied)
    } else {
        fragColor = color;
    }
}
