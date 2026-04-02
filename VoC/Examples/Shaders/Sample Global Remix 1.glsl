#version 420

// original https://www.shadertoy.com/view/td3XzX

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// global remix - Del 30/10/2019

float snow(vec2 uv,float scale)
{
    
    float _t = (time)*2.3;
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
    //vec2 uv=(gl_FragCoord.xy*2.-resolution.xy)/min(resolution.x,resolution.y); 
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
    vec3 finalColor=(vec3(0.7,0.35,0.9))*c*30.0;
    finalColor += vec3(1.1,0.55,0.9)*0.02/dd;
    return finalColor;
}

void main(void)
{
    // Normalized pixel coordinates (from 0 to 1)
     vec2 uv = (gl_FragCoord.xy - 0.5 * resolution.xy) / resolution.y;

    glFragColor = vec4(_globalmix(uv),1.0);

}
