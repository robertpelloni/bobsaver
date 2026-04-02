#version 420

// original https://www.shadertoy.com/view/dsKyDz

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*
    random emotes
    2021 stb
    
    animation by misol101 2023
*/

// hash without sine
// https://www.shadertoy.com/view/4djSRW
//#define MOD3 vec3(.1031, .11369, .13787) // int range
#define MOD3 vec3(443.8975, 397.2973, 491.1871) // uv range
vec2 hash22(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * MOD3);
    p3 += dot(p3, p3.yzx+19.19);
    return fract(vec2((p3.x + p3.y)*p3.z, (p3.x+p3.z)*p3.y));
}

// circle inversion function
vec2 cInv(vec2 p, vec2 o, float r) {
    return (p-o) * r * r / dot(p-o, p-o) + o;
}

// a line of width w, warped by circle inversion, offset by o
float arc(in vec2 p, float w, in vec2 o) {
    p = cInv(p, vec2(0.), 1.);
    p = cInv(p, vec2(0., o.y), 1.);
    p.y -= o.y;

    return  length(vec2(max(0., abs(p.x-o.x)-w), p.y));
}

float emote(vec2 p, vec2 h, float aa, float time, vec2 lk, bool eyeb) {
    float f=1., eyes, eyebrows=-.065, mouth, head;
    vec2 o = vec2(0., 1.);
    
    float blinktime = 0.45;
    float blx = 1.0, bly = 1.0;
    float blt = (mod(time,8.)-(h.x*h.y)*8.);
    if (blt > 0. && blt < blinktime) {
        bly = 1. + sin((blt/blinktime)*3.141)*1.5;
        blx = 1. - sin((blt/blinktime)*3.141)*0.4;
    }
    
    // get eyes
    eyes = length(vec2((abs(p.x-lk.x)-.36)*blx+.25*pow(lk.x+h.x*0.15+0.3, 0.9+h.y), (p.y-.27-lk.y)*bly )) - (.15);
    
    // get eyebrows (symmetrical or not)
    if(fract(3.447*h.x) < .5)
        eyebrows += arc(vec2(abs(p.x-lk.x)-.35, p.y-lk.y-.5*fract(1.46*lk.y)-.35), .2, 2.*fract(h*2.31)*h.y*o-.5*o);
    else
        eyebrows +=
            min(
                arc(vec2(p.x-lk.x-.35, p.y-lk.y-.25*fract(2.31*lk.y)-.4), .2, 2.*fract(h*2.31)*h.y*o-.5*o),
                arc(vec2(-p.x+lk.x-.35, p.y-lk.y-.25*fract(-1.81*lk.y)-.4), .2, 2.*fract(-h*1.92)*h.y*o-.5*o)
            );
    
    // get mouth
    mouth = arc(p+vec2(0., .35)-.5*lk, .4*pow(max(0.0,h.x+sin(time*h.y*1.0)+0.8), .5), vec2(.35, 1.)*(fract(2.772*h)-.5)) - .08;
    if(fract(1.932*h.x) < .10) // some emotes are surprised
        mouth = length(vec2(((p.x-lk.x)-.36+.25)*(1.0-h.y*0.2), (p.y+.27-lk.y)*1.1)) - (.2+sin(0.2+time*(2.0*h.x+h.y))*(0.005+(h.y)*0.08));
    
    // get head
    head = (abs(length(p)-1.) - .075) ;
    
    // combine everything
    f = min(f, eyes);
    if(eyeb) // some emotes have eyebrows
        f = min(f, eyebrows);
    f = min(f, mouth);
    f = min(f, head);
    
    // result
    return smoothstep(-aa, aa, f);
}

void main(void)
{
    vec2 fc = gl_FragCoord.xy;
    
    vec2 res = resolution.xy;
    vec2 p   = (fc-res/2.) / res.y;
    vec2 m   = (mouse*resolution.xy.xy-res/2.) / res.y;
    
    float zoom     = .2;
    
    // zoom
    p /= zoom;
    
    // scroll
    p.y -= .15 * time;
    
    // one hash22 to rule them all
    vec2 h = hash22(ceil(p)+.371);

    float headSize = 1.4;// + sin(time*h.x*2.)*0.06;
    float aa       = 2. / zoom / res.y * headSize;

    float time = time * (0.8+(h.x*h.y)) * 1.0;
    
    // look variable (where the face is facing)
    vec2 lk = (0.75+sin(time*(min(1.4,0.5+h.y*0.66+h.x*1.33)))*0.5) * (.5 * (h-.5));
    
    bool eyebrows = fract(4.932*h.x) < .65; // some emotes have eyebrows
    if (!eyebrows) lk*=sin(time*h.x+h.y*4.); else if (sin(h.x*h.y) < 0.5) lk=-lk;

    p -= lk*0.1;

    // get emote
    float f = emote((headSize)*(fract(p)*2.-1.), h, aa, time, lk, eyebrows);
    
    // set initial color to black/white emote
    vec3 col = vec3(f);
    
    // apply circles of color
    if(length(fract(p)-.5) < .5/headSize) {
        col *= 1.*fract(vec3(pow(h.x, .15), pow(fract(1.314*h.y), .15), fract(1.823*h.y)));
        col *= pow(clamp(2.0*(.75-length(fract(p)-vec2(0.5, 0.6)*1.0)), 0.0, 1.15),1.3);
    } else {
        col *= 1.1 * mix( vec3(1.0,0.8,0.3), vec3(0.58, 0.99, 0.99), sqrt((fc/resolution.y).y) );
    }

    // output
    vec4 fo = vec4(col, 1.);
    
    glFragColor = fo;
}