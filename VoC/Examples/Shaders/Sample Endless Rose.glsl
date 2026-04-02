#version 420

// original https://www.shadertoy.com/view/NsKGW1

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 hash42(vec2 p)
{
    vec4 p4 = fract(vec4(p.xyxy) * vec4(.1031, .1030, .0973, .1099));
    p4 += dot(p4, p4.wzxy+33.33);
    return fract((p4.xxyz+p4.yzzw)*p4.zywx);
}

void main(void)
{
    vec2 C = gl_FragCoord.xy;
    vec4 o = glFragColor;

    vec2 R = resolution.xy;
    vec2 uv = (C-R*.5)/max(R.y,R.x);
    uv *= 1.5;
    float a_ = atan(uv.x, uv.y)/3.14159265;
    float fog = length(uv);
    float z_ = 1./fog;
    uv = vec2(a_, z_);
    uv.y += time;

    float ringOrig = floor(uv.y);
    vec4 hring = hash42(vec2(ringOrig));
    
    uv.x *= floor(hring.x * 10.) + 1.;
    uv.x += time * (.5-hring.y)*2.;
    uv.x += sin(uv.y*hring.w-.5);
    
    vec2 u2 = fract(uv);
    u2.y *= -sign(hring.w-.5);
    float hpat = step(.6, fract((u2.x + u2.y) * .5));

    o = hring * hpat;
    o *= fog * 5.;
    o *= 1.-fract(uv.y);

    glFragColor = o;
}
