#version 420

// original https://www.shadertoy.com/view/lsXXDr

uniform float time;
uniform vec2 resolution;

out vec4 glFragColor;

const float PI=3.14159;

float saw(float x){
    return abs(mod(x-1.,2.)-1.);
}

// edit this
vec3 tex(vec2 uv){
    float m=PI*20.;
    float d = smoothstep(-0.02,0.02,sin(uv.x*m))+
              smoothstep(-0.02,0.02,sin(uv.y*m));
    d=saw(d);
    //d=smoothstep(00.2,0.3,d);
    return vec3(d,sin(length(uv)*39.),sin(length(uv)*50.));
}

vec2 displace(vec2 uv){
    
    float refindex=1.3; // refraction index, change this (1.3 is glass)
    
    float r=0.5;
    
    float m=length(uv);
    
    if(m<1.)
        m = sin(asin(m)/refindex);
    
    return normalize(uv)*m;
}

vec3 shade(vec2 uv){
    vec2 d=vec2(sin(time),cos(time*1.5))*0.3;
    return tex(displace(uv+d)-d);
}

void main(void)
{
    vec2 uv = (2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    glFragColor = vec4(shade(uv),1.0);
}
