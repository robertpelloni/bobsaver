#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float snow(vec2 uv,float scale)
{
    float w = smoothstep(1., 0., -uv.y*(scale/10.));
    
    if (w < 0.1)
        return 0.;
    
    uv += time/scale;
    
    uv.y += time*8./scale;
    uv.x += sin(uv.y+time*.1)/scale;
    
    uv *= scale;
    
    vec2 s = floor(uv);
    vec2 f=fract(uv);
    vec2 p;
    
    float k=3.,d;
    
    p = .3+.35*sin(7.*fract(sin((s+p+scale)*mat2(3,3,6,5))*5.))-f;
    
    d = length(p);
    
    k = min(d,k);
    
    k = smoothstep(0.,k,sin(f.x+f.y)*0.03);
    
        return k*w;
}

void main(void)
{
    vec2 uv = (gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y); 
    
    float c = 0.0;
    
    c+=snow(uv,20.)*.5;
    c+=snow(uv,15.)*.8;
    c+=snow(uv,10.);
    c+=snow(uv,8.);
    c+=snow(uv,6.);
    c+=snow(uv,5.);
    
    glFragColor = vec4(c,c,c,c);
}
