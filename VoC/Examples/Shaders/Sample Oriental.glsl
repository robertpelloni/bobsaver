#version 420

// original https://www.shadertoy.com/view/WsSfRG

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

// Shader made for Everyday ATI challenge

#define PI acos(-1.)
#define AAstep(thre, val) smoothstep(-.7,.7,(val-thre)/min(.05,fwidth(val-thre)))

float xor (float a, float b)
{return (1.-a)*b + (1.-b)*a;}

float circle(vec2 uv, float r)
{return AAstep(r,length(uv));}

float pattern(vec2 uv)
{
    float per = 1.5;
    int ip = int(per);
    vec2 id = floor((uv)/per);
    uv = mod(uv,per)-per*0.5;
    float r = sin(length(id+0.5)-time*PI/6.)*0.5+0.5;
    float d = circle(uv,0.5);
    for(int i=-ip; i<=ip;i+=ip)
    {
        for (int j=-ip; j<=ip;j+=ip)
        {
          d = xor(d,circle(uv+vec2(float(i),float(j))/2.,r));
        }
    }
    return d;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 col = mix(vec3(0.8,0.7,0.5),vec3(0.1,0.4,0.6),pattern(uv*5.));
    glFragColor = vec4(sqrt(col),1.0);
}
