#version 420

// original https://www.shadertoy.com/view/Wd33R4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// (C) Kristian Sivonen 2019

// edit 2019-09-08: fancier fake specular
//                    simplified truchet function
//                    eliminated some matrix multiplications

// Hash without sine by Dave Hoskins, CC BY-SA 4.0
// https://www.shadertoy.com/view/4djSRW
float hash12(vec2 p)
{
    vec3 p3  = fract(vec3(p.xyx) * .1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p)
{
    vec2 pi = floor(p);
    vec2 pf = p - pi;
    float h00 = hash12(pi);
    float h01 = hash12(pi + vec2(0., 1.));
    float h10 = hash12(pi + vec2(1., 0.));
    float h11 = hash12(pi + 1.);
    return mix(mix(h00, h10, pf.x), mix(h01, h11, pf.x),pf.y);
}

float truchet(vec2 p, float w, float t)
{
    p *= t;
    vec2 i = floor(p);
    vec2 uv = p - i;
    float s = sign((hash12(i) * 2. - 1.) + .001);
    uv.x = fract(abs(uv.x + s));
    vec2 toC = uv - .499;
    s = sign(dot(toC, vec2(1.)));
    uv = fract(abs(uv - s));
    
    float mn = .5 - w;
    float mx = .5 + w;
    float truch = smoothstep(mn, mx, 1. - length(uv));
    truch = 1. - abs(truch * 2. - 1.);
    return truch;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y + sin(vec2(time, time + 1.57) * .13);
    
    float move = sin(time * .123) * .5 + .5;
    float rot = (move * 2. - 1.) * 3.14;
    float tiling = move * 5. + 5.;
    float rcpT = 1. / tiling;
    
    mat2x2 rMat = mat2x2(cos(rot), -sin(rot), sin(rot), cos(rot));
    uv = rMat * uv;
    vec2 one = rMat * vec2(1.);
    vec2 shadowUV = uv + one * .2 * rcpT;
    vec2 hlUV = uv - one * .05 * rcpT;
    vec2 hlUV2 = hlUV + vec2(-one.y, one.x) * .072 * rcpT;
    
    float outline = truchet(uv, .44, tiling);
    float truch = truchet(uv, .3, tiling);
    float shadow = truchet(shadowUV, .3, tiling);
    float hl = truchet(hlUV, .1, tiling);
    hl = min(hl, truchet(hlUV2, .1, tiling));
    float light = truchet(hlUV, .3, tiling);
    
    outline = smoothstep(.38, .4, outline);
    truch = smoothstep(.3, .4, truch);
    shadow = smoothstep(.1, .6, shadow);
    hl = smoothstep(.15, .85, hl) * truch;
    light = smoothstep(.2, .7, light) * truch;
    
    vec3 col = vec3(.1, .2, .35) + noise(uv * tiling * 100.) * .04 - .02;
    col *= 1. - shadow * .4;
    col *= 1. - outline;
    
    col = mix(col, vec3(.8, .2, .5), truch);
    col *= 1. - clamp(truch - light, 0., 1.) * vec3(.6, .6, .4);
    
    col += vec3(1., .8, .4) * hl * .7;
    glFragColor = vec4(col,1.);
}
