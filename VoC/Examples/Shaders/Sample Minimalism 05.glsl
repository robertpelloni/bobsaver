#version 420

// original https://www.shadertoy.com/view/3tBfWz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// Code by Flopine

// Thanks to wsmind, leon, XT95, lsdlive, lamogui, 
// Coyhot, Alkama,YX, NuSan and slerpy for teaching me

// Thanks LJ for giving me the spark :3

// Thanks to the Cookie Collective, which build a cozy and safe environment for me 
// and other to sprout :)  https://twitter.com/CookieDemoparty

#define TAU 6.2831853

#define BPM (120./60.)
#define dt(speed) fract(time*speed)
#define AnimOutExpoLoop(speed) easeOutExpo(abs(2.*dt(speed)-1.))
#define AnimOutExpo(speed) easeOutExpo(dt(speed))

#define AAstep(thre, val) smoothstep(-.7,.7,(val-thre)/min(0.07,fwidth(val-thre)))
#define square(puv,s) (max(abs(puv.x),abs(puv.y))-s)
#define hexa(puv,s) (max(abs(puv.x),dot(abs(puv), normalize(vec2(1.,sqrt(3.))))))-s

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define moda(puv,r) float a=mod(atan(puv.x,puv.y),TAU/r)-(TAU/r)*0.5; puv=vec2(cos(a),sin(a))*length(puv)

#define palette(t,c,d) (vec3(0.5)+vec3(0.5)*cos(TAU*(c*t+d)))

float easeOutExpo (float x)
{     return x == 1. ? 1. : 1. - pow(2., -10. * x); }

float equitri (vec2 p, float r)
{
    p.x = abs(p.x) - r;
    p.y = p.y + r/sqrt(3.);
    if (p.x+sqrt(3.)*p.y>0.) p=vec2(p.x-sqrt(3.)*p.y,-sqrt(3.)*p.x-p.y)/2.;
    p.x -= clamp( p.x, -2.*r, 0. );
    return -length(p)*sign(p.y);
}

float frame (vec2 uv)
{
    vec2 hper = vec2(1.,sqrt(3.));
    vec2 auv = mod(uv,hper)-hper*0.5;
    vec2 buv = mod(uv-hper*0.5,hper)-hper*0.5;
    vec2 guv = (dot(auv,auv)<dot(buv,buv)) ? auv : buv;
    vec2 gid = uv-guv;

    float cellsize = 0.4;
    guv *= rot(AnimOutExpo(BPM/6.+length(gid.x+gid.y*.5))*TAU);
    float mask = AAstep(0.02,abs(hexa(guv,cellsize)));
    if(mod(gid.x+0.1,2.) < 1.) 
    {
        moda(guv,3.);
        float line = max(abs(guv.y)-0.02,abs(guv.x)-cellsize*1.1);
        mask *= AAstep(0.01,line);
    }
    else mask *= AAstep(0.03,abs(equitri(guv,cellsize*0.95)));
    return mask;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 col = vec3(frame(uv*3.5));
    glFragColor = vec4(col,1.0);
}
