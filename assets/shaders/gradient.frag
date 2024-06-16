#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

uniform vec4 color1;
uniform vec4 color2;
uniform vec2 resolution;
uniform float size;
uniform float d;
uniform float x_off;
uniform float y_off;
uniform float z_off;

out vec4 fragColor;

const float merge_col = 16;
const float fade_out = 16;

float do_mod(float a, float b) {
    return a - (b * floor(a / b));
}

void main() {
    float x = FlutterFragCoord().x - resolution.x / 2;
    float y = FlutterFragCoord().y - resolution.y;

    float y_world = y_off;
    float z_world = y_world * d / y;
    float x_world = x / d * z_world + x_off;

    float x_tile = do_mod(floor(x_world / size), 2);
    float z_tile = do_mod(floor((z_world * 8 - z_off) / size), 2);
    // why the 8 to be it look square?

    vec4 col = color1;
    vec4 other = color2;
    if (x_tile != z_tile) {
        col = color2;
        other = color1;
    }

    float merge_ = (y - resolution.y / merge_col) / resolution.y;
    if (merge_ < 0) merge_ = 0;
    col = mix(col, other, 0.5 - merge_);

    float mix_ = y / resolution.y * fade_out;
    if (y < resolution.y / fade_out) {
        col = col * mix_;
    }

    col.x *= col.a;
    col.y *= col.a;
    col.z *= col.a;
    fragColor = col;
}

// https://jameshfisher.com/2017/08/30/how-do-i-make-a-full-width-iframe/

// This set suits the coords of of 0-1.0 ranges..
#define MOD3 vec3(443.8975,397.2973, 491.1871)
//#define MOD4 vec4(443.8975,397.2973, 491.1871, 470.7827)

//  1 out, 1 in...
float hash11(float p)
{
    vec3 p3  = fract(vec3(p) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(p3.x * p3.y * p3.z);
}
//----------------------------------------------------------------------------------------
//  1 out, 2 in...
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx + 19.19);
    return fract(p3.x * p3.z * p3.y);
}

//----------------------------------------------------------------------------------------

const float NUM_LEVELS_F = 10.0;

//----------------------------------------------------------------------------------------
float quantize_round( float v, float num_levels )
{
    return floor(v * num_levels ) / num_levels;
}

float quantize_round_rnd( float v, float num_levels, vec2 seed )
{
    float rnd = hash12( seed );
    float v_rnd = v + rnd / NUM_LEVELS_F;
    return quantize_round( v_rnd, NUM_LEVELS_F );
}

//----------------------------------------------------------------------------------------

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 ssuv = fragCoord.xy / iResolution.xy;

    vec2 fc = fragCoord.xy;
    fc = floor( fc.xy / 4.0 ) * 4.0;

    vec2 uv = fc/iResolution.xy;

    float v = uv.x;

    vec2 mp = iMouse.xy;
    float c_mp = quantize_round( mp.x, NUM_LEVELS_F );

    vec3 c;
    float rnd = hash12( fc / 1000.0 );
    float v_rnd = v + rnd / NUM_LEVELS_F;
    c = vec3( quantize_round( v_rnd, NUM_LEVELS_F ) );

    fragColor = vec4(c,1.0);

    fragColor.rgb += hash12(ssuv)/255.0;
}
