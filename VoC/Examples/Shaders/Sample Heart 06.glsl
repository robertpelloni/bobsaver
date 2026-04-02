#version 420

// original https://www.shadertoy.com/view/MtfcDS

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Created by Gabor Nagy (gabor.nagy@me.com)
// September 23, 2017
//
// Op Art Heart

float sqr(float x) {
    return x*x;
}

float heart(vec2 p)
{
    float n = sqr(p.x) + sqr(5.*(p.y+.25)/3.8 - sqrt(abs(p.x))) - 1.;
    return 0. - n;
}

void main(void)
{
    float t = time;
    vec2 r = resolution;
    
    vec2 uv = (2. * gl_FragCoord.xy - r.xy) / r.y;
    vec2 uv_sin = vec2(uv.x + .33 * sin(uv.y * 5.), uv.y);
    
    // Rotate
    uv_sin *= mat2(cos(t), sin(t), -sin(t), cos(t));
    
    // Stripes
    float color = smoothstep(.5, .5 + 50./r.y, .5 + .5 * sin(uv_sin.x * 30.));
    
    // Scale heart
    uv *= (2. - pow(sin(t * 4.),8.) * .6);  
    
    // Invert color inside heart
    color = mix(color, 1.-color, smoothstep(-0.01, 0.01, heart(uv)));
    
    glFragColor = vec4(vec3(color), 1.);
}
