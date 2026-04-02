#version 420

// original https://www.shadertoy.com/view/ld33WH

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define GLOBAL_SPEED 1.  //  <---------- play around with these
#define SPEED_RATIO 2.
#define SIZE_RATIO 1.5
#define NB_CIRCLES 8

#define EPS .008
#define D(A,B,C) abs(distance(A,B)-C)<=EPS

void main(void)
{
    vec2 R = resolution.xy,
         p = 2. * (gl_FragCoord.xy+gl_FragCoord.xy-R) / R.y,
         o = vec2(0);
    float t = GLOBAL_SPEED * time / 20.;
    vec3 c = abs(p.x) < 2.*EPS ? vec3(0) : vec3(1);
    bool b = p.x < .0;
    p.x = b ? p.x + 2. : p.x - 2.;
    vec2 r = vec2(.5);
    for(int i=0;i<NB_CIRCLES;i++)
    {
        vec2 s=r.y*vec2(sin(t/r.x),cos(t/r.x));
        if(b)
        {
            if(D(p,o,EPS)) c=vec3(0);
            if(D(p,o,r.y)) c*=vec3(.8);
        }
        else if(i == NB_CIRCLES - 1)
        {
            if(D(p,o,EPS)) c=vec3(0);
            else if(time > .1) discard;
        }
        r.x/=SPEED_RATIO; o+=s; r.y/=SIZE_RATIO;
    }
    glFragColor.xyz=c;
}
