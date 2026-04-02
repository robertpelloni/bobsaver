#version 420

// original https://www.shadertoy.com/view/3sXBD2

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

#define AAstep(thre, val) smoothstep(-.7,.7,(val-thre)/min(.05,fwidth(val-thre)))

float square(vec2 uv, float s)
{return AAstep(s,max(abs(uv.x),abs(uv.y*2.)));}

float triX (vec2 uv, float s)
{
    uv.y = abs(uv.y);
    return AAstep(s,max(-uv.x, dot(uv,normalize(vec2(1.,sqrt(3.))))));
}

float ellipse (vec2 uv, float s)
{return AAstep(s,length(uv*vec2(1.,3.)));}

float circle (vec2 uv, float s)
{return AAstep(length(uv),s);}

float fish (vec2 uv)
{
    vec2 tri_offset = vec2(0.71,0.);
    vec2 ellipse_offset = vec2(0.2,0.5);
    vec2 circle_offset = vec2(1.15,0.1);    
    return (1.-triX(uv+tri_offset,0.29))
            +square(uv,1.)*triX(uv-tri_offset*1.8,0.29)
            *ellipse(uv-ellipse_offset,.8)
            +(1.-ellipse(uv+vec2(-ellipse_offset.x,ellipse_offset.y), .8))
            + circle(uv-circle_offset,0.1);
}

float fishes (vec2 uv)
{
    return fish(uv)
        *fish(vec2(-uv.x,uv.y)+vec2(-1.6,1.))
        -circle(uv+vec2(.8,-0.08),0.1)
        -circle(uv+vec2(.8,0.9),0.1);
}

float img (vec2 uv)
{
    float horizontal = 3.9;
    float vertical = 2.;
    vec2 per = vec2(horizontal,vertical); 
    vec2 guv = mod(uv-per*0.5,per)-per*0.5;
    
    float d = fishes(guv);
    
    for(int i=-1;i<=1; i++)
    {
        for(int j=-1;j<=1;j++)
        {
            vec2 neighbors = vec2(float(i),float(j));
            d *= fishes(guv+neighbors*per);
        }
    }
    return d;
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;

    uv.y += sin(uv.x*1.2+time)*0.05;

    float fish_grid = img(uv*5.);
     vec3 col = vec3(fish_grid);
    
    glFragColor = vec4(col,1.0);
}
