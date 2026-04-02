#version 420

// original https://www.shadertoy.com/view/wtcfzr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

mat2 rot(float deg)
{    
    return mat2(cos(deg),-sin(deg),
                sin(deg), cos(deg));
        
}

void main(void)
{
    float t = time;
    vec2 uv = gl_FragCoord.xy / resolution.xy;
    
    uv-=.5;
    uv*=15.;
    
    uv*=rot(uv.y/5.-t*.15);
    uv-=sin(sqrt(uv.x*uv.x+uv.y*uv.y)-t*2.)*3.;
    uv.y+=sin(uv.x-t)*1.2;
    uv-=sin(sqrt(uv.x*uv.x+uv.y*uv.y)+t)*.6;
    uv.x+=sin(uv.y*1.4+t)*.6;
    
    
    uv*=rot(uv.x/5.-t*.8);
    uv.x/=length(.75*uv);
    uv.y/=length(.75*uv);
    //uv+=length(uv-.5);
    glFragColor = vec4(sin(uv.x-t*.6),sin(uv.y+uv.y-t*.7),sin(uv.x+uv.y-t*.8),1.0);
}
