#version 420

// original https://www.shadertoy.com/view/WdVBDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

/*Ethan Alexander Shulman 2020 - xaloez.com
4k 60fps video https://www.youtube.com/watch?v=kf-Lrm9S6ZI
4k wallpaper xaloez.com/art/2020/Disorientation.jpg*/

mat2 r2(float a) {
    float s = sin(a), c = cos(a);
    return mat2(c,-s,s,c);
}

vec4 hash(vec4 a) {
    return fract(abs(sin(a.ywxz*766.345)+cos(normalize(a)*4972.92855))*2048.97435+abs(a.wxyz)*.2735);
}

float twave(float x) {
    return x*2.-max(0.,x*4.-2.);
}

void main(void)
{
#define time time
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/resolution.y;

    float s = 0.;
    #define AA 2.
    #ifdef AA
    for (float ax = -AA; ax < AA+1.; ax++) {
        for (float ay = -AA; ay < AA+1.; ay++) {
            vec2 p = (uv.xy+vec2(ax,ay)/AA/resolution.y)*10.;
    #else
            vec2 p = uv.xy*10.;
    #endif
            for (float l = 1.; l < 40.; l++) {
                vec4 h = hash(l*vec4(.01,.1,1.,10.));
                h.xy = (h.xy*2.-1.)*6.;
                p -= h.xy;
                float lp = length(p);
                p *= r2(h.z/length(p)+time*(h.w-.5));
                p += h.xy;
            }
            p = floor(100.+p);
            s += mod(p.x+p.y,2.);
    #ifdef AA
        }
    }
    s /= (AA*2.+1.)*(AA*2.+1.);
    #endif
    glFragColor = vec4(s,s,s,1.);
}
