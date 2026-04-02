#version 420

// original https://www.shadertoy.com/view/tscXzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// global remix 2 - Del 30/10/2019

float snow(vec2 uv,float scale)
{
    float _t = time*2.3;
    uv*=scale;    
    uv.x+=_t; 
    vec2 s=floor(uv);
    vec2 f=fract(uv);
    vec2 p=.5+.35*sin(11.*fract(sin((s+scale)*mat2(7,3,6,5))*5.))-f;
    float d=length(p);
    float k=smoothstep(0.,d,sin(f.x+f.y)*0.003);
    return k;
}

vec3 _globalmix(vec2 uv)
{
    float dd = 0.5-length(uv);
    uv.x += sin(time*0.08);
    uv.y += sin(uv.x*1.4)*0.2;
    uv.x *= 0.1;
    float c=snow(uv,30.)*.3;
    c+=snow(uv,20.)*.5;
    c+=snow(uv,15.)*.8;
    c+=snow(uv,10.);
    c+=snow(uv,8.);
    c+=snow(uv,6.);
    c+=snow(uv,5.);
    c*=0.2/dd;
    vec3 finalColor=(vec3(0.77,0.435,0.29))*c*30.0;
    finalColor += vec3(.75,0.35,0.15)*0.02/dd;
    return finalColor;
}

mat2 rot(float a)
{
    float sa = sin(a), ca = cos(a);
    return mat2(ca, -sa, sa, ca);
}    
 
void main(void)
{
    vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;
    uv *= rot(time);
    vec2 uv2 = uv;
    uv2.y += sin(time*0.35+uv2.x*2.0);
    uv2.y = abs(uv2.y);
    uv2.y -= dot(uv2,uv2);
    glFragColor = vec4(_globalmix(uv)*length(0.25/uv2),1.0);
}
