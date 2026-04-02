#version 420

// original https://www.shadertoy.com/view/3s2GRW

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    This shader was created live on stream!
    You can watch the VOD here: https://www.twitch.tv/videos/368710013

    I use the Bonzomatic tool by Gargaj/Conspiracy:
    https://github.com/Gargaj/Bonzomatic

    Wednesdays around 9pm UK time I stream at https://twitch.tv/lunasorcery
    Come and watch a show!

    ~yx
*/

#define time time*.2
#define pi (acos(-1.))

const float SPEED = 2.0;

float tick(float t)
{
    t = smoothstep(0.,1.,t);
    t = smoothstep(0.,1.,t);
    t = smoothstep(0.,1.,t);
    return t;
}

vec2 rotate(vec2 a, float b)
{
    float c =cos(b);
    float s =sin(b);
    return vec2(
        a.x*c-a.y*s,
        a.x*s+a.y*c
    );
}

float noise(float a)
{
    return fract(sin(a*12.4312)*432.432423);
}

float shape(vec2 p)
{
    return length(p)-.25;
}

float scene(vec2 p, float time2)
{
    float fmode = (noise(floor(time2)) * 4.);
    int mode = int(fmode);

    float t = tick(fract(time2));
    t *= fract(fmode)<.5?-1.:1.;

    vec2 np = floor(p-.5);
    p = mod(p-.5,1.)-.5;

    if(mode==0)
        p.x += t;
    if(mode==1)
        p.y += t;
    if(mode==2)
        p.x += t*(mod(np.y,2.)<1.?1.:-1.);
    if(mode==3)
        p.y += t*(mod(np.x,2.)<1.?1.:-1.);

    p = mod(p-.5,1.)-.5;

    return shape(p);
}

// shamelessly stolen from https://www.shadertoy.com/view/MdsyDX
vec3 aberrationColor(float f)
{
    f = f * 3.0 - 1.5;
    return clamp(vec3(-f, 1.0 - abs(f), f),0.,1.);
}

vec4 chroma(float a)
{
    return vec4(aberrationColor(a),1);
}

vec4 fxor(vec4 a, vec4 b)
{
    return mix(a,1.-a,b);
}

void main(void)
{
    vec4 out_color = glFragColor;
    vec2 uv = gl_FragCoord.xy / resolution.xy-.5;
    uv.x *= resolution.x / resolution.y;
    vec2 screenuv = uv;
    uv *= 4.;

    uv/=dot(uv,uv);

    uv *= .25;
    out_color = vec4(0);
    for(int j=0;j<3;++j){
        vec4 tempColor = vec4(0);
        uv = rotate(uv, pi/8.);
        float steps = 50.;
        float e = abs(dFdx(uv).x);
        for(float i=0.;i<steps;++i)
        {
            float time2 = (time+(i/steps )/60.)*SPEED-length(screenuv)*.1+(float(j)*4./3.);
            tempColor += chroma(i/steps ) * (smoothstep(-e,e, -scene(uv, time2)) / steps);
        }
        uv *= 3.0;
        out_color = fxor(out_color, tempColor*3.);
    }
    out_color *= 2.5;
    out_color *= min(1.,length(screenuv)*2.);
    glFragColor = out_color;
}
