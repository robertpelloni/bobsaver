#version 420

// original https://www.shadertoy.com/view/WlsSzB

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define PI 3.141592

float polygon(vec2 p, float s)
{
    if (s<3.) { s=3.; }
    float a = ceil(s*(atan(-p.y, -p.x)/PI+1.)*.5);
    float n = 2.*PI/s;
    float t = n*a-n*.5;
    return dot(p, vec2(cos(t), sin(t)));
}

mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.y;
    
    float s = 4.;
    vec2 i = floor(uv*s);
    vec2 e = vec2(.01, .0);
    vec2 f = fract(uv*s)*2.-1.;
    f *= rotate2d(time);
    float l = i.y*s+i.x+3.+i.y*3.;
    float p = 1.-polygon(f*1.9, l);
    float dx = 1.-polygon((f-e.xy)*1.9, l);
    float dy = 1.-polygon((f-e.yx)*1.9, l);
    
    dx = (dx-p)/e.x;
    dy = (dy-p)/e.x;
    
    vec3 n = normalize(vec3(dx, dy, 1.));
    vec3 lP = vec3(cos(time), sin(time), 1.)*6.;
    vec3 lD = normalize(lP - vec3(f, .0));
    float ambi = (1.-p); 
    float diff = max(dot(n, lD), 0.);
    float r = ambi+diff;
    
    vec3 col = vec3(0.);
    float m = (i.x+1.)/s;
    if (i.y == 0.)
        col += p*mix(vec3(1., 0., .0), vec3(1., .2, .6), m)*r;
    else if (i.y==1.)
        col += p*mix(vec3(0., 1., 0.), vec3(.6, 1., .2), m)*r;
    else if (i.y==2.)
        col += p*mix(vec3(0., 0., 1.), vec3(.2, .6, 1.), m)*r;
    else
        col += p*mix(vec3(1., 1., 0.), vec3(1., .6, .2), m)*r;
        
    glFragColor = vec4(sqrt(clamp(col, 0., 1.)),1.0);
}
