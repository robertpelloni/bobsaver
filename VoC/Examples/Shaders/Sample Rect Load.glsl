#version 420

// original https://www.shadertoy.com/view/MstfWX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

precision mediump float;
#define PI 3.14159265359
#define QPI 0.78539816339

float rect(in vec2 uv, in float r, in vec2 offset){
    uv += offset;
    float b = .01;
    return smoothstep(uv.x - r - b, uv.x - r + b, uv.y) * smoothstep(uv.x + r + b, uv.x + r - b, uv.y)
                        * smoothstep(-uv.x - r - b, -uv.x - r + b, uv.y) * smoothstep(-uv.x + r + b, -uv.x + r - b, uv.y);
}

vec2 calcPoint(in float ang){
    vec2 ppp = vec2(cos(ang), .5 * sin(ang * 2.));
    return vec2(pow(ppp.x, 2.) * sign(ppp.x), ppp.y);
}

void main(void)
{
    vec2 st = (gl_FragCoord.xy * 2. - resolution.xy)/resolution.y;
    float bg;
    {
        vec2 uv = abs(st);
        uv -= vec2(.5, 0.);
        float ang = -QPI;
        uv *= mat2(cos(ang), -sin(ang), sin(ang), cos(ang));
        uv += vec2(.5, 0.);
        float r = distance(uv, vec2(.5, 0.));
          float a = mod(atan(uv.y, uv.x - .5), PI/2.) - QPI;
          vec2 p = vec2(r * cos(a), r * sin(a));
        bg = rect(p, .475, vec2(-.5, 0.));
    }
    
    float time = time * 4.;
    float modAng = mod(time, QPI);
    float ang = time - modAng;
    vec2 emptyPoints[2]; emptyPoints[0] = calcPoint(ang); emptyPoints[1] = calcPoint(ang - QPI);
        
    bg -= rect(st, .475, -emptyPoints[0]);
    bg = clamp(bg, 0., 1.);
    bg -= rect(st, .475, -emptyPoints[1]);
    bg = clamp(bg, 0., 1.);
    bg += rect(st, .475, -mix(emptyPoints[0], emptyPoints[1], modAng/QPI));
    
    glFragColor = vec4(bg);
}
