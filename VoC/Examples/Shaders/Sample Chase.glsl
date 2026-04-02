#version 420

// original https://www.shadertoy.com/view/wsjBzw

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.14159265359

const float rad = .6;
const float bRad = .07;
const float speed = 5.;

const float lRad = 3.;
const float lInt = .4;
const float lAtten = 5.;

const vec4 c1 = vec4(27., 231., 255., 255.) / 255.;
const vec4 c2 = vec4(227., 108., 201., 255.) / 255.;
const vec4 bg = vec4(48., 13., 68., 255.) / 255.;

void main(void)
{
    vec2 uv = gl_FragCoord.xy / resolution.xy * 2. - 1.;
    uv.x *= resolution.x / resolution.y;
    
    //Ball point and angle
    float t = time * speed;
    vec2 p = vec2(cos(t), sin(t)) * rad;
    
    //Trail
    float rAngle = dot(normalize(uv), normalize(p)) * 0.5 + 0.5;
    rAngle *= ceil(cross(vec3(uv, 0.), vec3(p, 0.)).z);
    
    float gAngle = dot(normalize(uv), normalize(-p)) * 0.5 + 0.5;
    gAngle *= ceil(cross(vec3(uv, 0.), vec3(-p, 0.)).z);
    
    //Use trail in path
    float rTRad = mix(0., bRad, rAngle);
    rAngle *= clamp(ceil(1. - abs(length(uv) - rad) / rTRad), 0., 1.);
    
    float gTRad = mix(0., bRad, gAngle);
    gAngle *= clamp(ceil(1. - abs(length(uv) - rad) / gTRad), 0., 1.);
    
    //Ball colors
    float rb = ceil(bRad - length(uv - p));
    rb = clamp(rb + rAngle, 0., 1.);
    
    float gb = ceil(bRad - length(uv + p));
    gb = clamp(gb + gAngle, 0., 1.);
    
    //Lighting
    float rDist = clamp(lRad - length(uv - p), 0., lRad) / lRad;
    rb += pow(rDist, lAtten) * lInt;
    
    float gDist = clamp(lRad - length(uv + p), 0., lRad) / lRad;
    gb += pow(gDist, lAtten) * lInt;
    
    //Color output
    vec4 c = c1 * rb + c2 * gb;
    c += bg * (1. - c.a);
    glFragColor = c;
}
