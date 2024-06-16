#version 460 core

#include <flutter/runtime_effect.glsl>

precision highp float;

// Created by mccannjp in 2020-07-07
// https://www.shadertoy.com/view/3lScDR

#define PI 3.14159
#define S smoothstep
#define COUNT 45

uniform vec2 iResolution;
uniform float iTime;

out vec4 fragColor;

float RAND_01(float co)
{
    return fract(sin(co * (98.3458)) * 47453.5453);
}

float RAND_Range(float id, float minimum, float maximum)
{
    return (RAND_01(id) * (maximum - minimum)) + minimum;
}

vec3 mountain(float id, vec2 uv, float blur, float offsetY)
{
    float height = RAND_Range(id, 0.2, 0.45);
    float offsetX = RAND_Range(id + 333., -1., 1.);
    float width = RAND_Range(id + 100., 0.65, 2.);

    float r1 = floor(RAND_Range(id, 6., 10.));
    float r2 = floor(RAND_Range(id, 10., 18.));
    float r3 = floor(RAND_Range(id, 17., 39.));
    float r4 = floor(RAND_Range(id, 39., 59.));

    uv.x = uv.x + (0.5 * width) - offsetX;
    uv.x += (iTime * (float(COUNT) - id)) / 100.;

    float y = sin(uv.x * PI / width) * height;
    y += sin(uv.x * r1 * PI / width) * height / r2;
    y += sin(uv.x * r3 * PI / width) * height / r4;
    y += + offsetY;

    uv.y += 0.03;

    float res = S(y + blur, y, uv.y);

    // gradient
    float ay = S(-0.5, y, uv.y / 1.) + 0.6;

    return vec3(res * ay);
}

void main()
{
    vec2 fragCoord = FlutterFragCoord();
    vec2 uv = (fragCoord - 0.5 * iResolution.xy) / iResolution.y;
    uv.y = 0.5 - uv.y;

    vec3 col = vec3(0.);
    float ct = float(COUNT);

    for (int i = 0; i < COUNT; i++) {
        float id = float(i);
        vec3 m = mountain(id, uv, 0.09, float(i) / ct - 1.0);

        float idx = RAND_Range(id, 0., 3.);
        vec3 c = vec3(1.);
        if (idx > 2.5) c = vec3(0.208, 0.308, 0.108);
        else if (idx > 1.5) c = vec3(0.1, 0.1, 0.1);
        else if (idx > 0.5) c = vec3(0.2, 0.2, 0.2);
        else c = vec3(0.2, 0.234, 0.2);

        if (col.r < 0.1)
        col += c * m;
    }

    if (col.r > 0.1) {
        fragColor = vec4(col, 1.0);
        fragColor.a = 0.5 + uv.y;
        fragColor.x *= fragColor.a;
        fragColor.y *= fragColor.a;
        fragColor.z *= fragColor.a;
    }
    //    if(col.r < 0.1)
    //    col += vec3(0.4, 0.5, 0.99); // sky
}
