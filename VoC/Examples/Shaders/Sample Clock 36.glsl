#version 420

// original https://www.shadertoy.com/view/ddSGzd

uniform float time;
uniform vec4 date;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define TAO 6.2831853
#define HALFPI 1.570796325
#define S smoothstep
#define R resolution.xy
#define px 1./min(R.x,R.y)

#define outerRadius  250. *px
#define outerMinTick 5.   *px
#define outerMaxTick 120. *px

float sdfBox(vec2 p, vec2 size)
{
    vec2 d = abs(p) - size;  
    return length(max(d, vec2(0))) + min(max(d.x, d.y), 0.0);
}

mat2 rot(float a) {
    return mat2(cos(a), -sin(a), sin(a), cos(a));
}

float tick(vec2 uv, vec2 size, float offset, float time) {
    uv *= rot(time);
    uv -= vec2(0., size.y + offset);
    return S(px, 0., sdfBox(uv, size));
}

float light(vec2 uv, float time) {
    uv *= rot(time+HALFPI);
    return pow(length(vec2(atan(uv.y, uv.x), length(uv))), 1.);
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy-.5*R.xy)/R.y;

    float hourTime = (date.w/3600.)/24.*TAO*2.;
    float minTime = date.w/60./60.*TAO;
    float secTime = date.w/60.*TAO;

    float s = tick(uv, vec2(0.1*px, 85.*px), 20.*px, secTime);
    float m = tick(uv, vec2(0.5*px, 70.*px), 16.*px, minTime);
    float h = tick(uv, vec2(.5*px, 40.*px), 20.*px, hourTime);
    float pin = S(px, 0., abs(length(uv) - 4.*px) - .5*px);
    
    float outer = 0.;
    float ticks = 1./120.;
    for (float i = ticks; i < 1.; i += ticks) {
        vec2 st = uv;
        float r = TAO * i;
        st *= rot(r);
        float t = pow(.5 + .5 * sin(HALFPI+secTime-i*TAO), 20.);
        st -= vec2(0., outerRadius + t*-outerMaxTick);
        outer += S(px, 0., sdfBox(st, vec2(0.1*px, outerMinTick + t * outerMaxTick)));
    }
    
    float clock = m +
                  h +
                  s * .4 +
                  pin * .4 +
                  outer * .2 +
                  light(uv, secTime) * .05;
               
    vec3 col = vec3(clock);
    glFragColor = vec4(col,1.0);
}
