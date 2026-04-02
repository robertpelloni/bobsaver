#version 420

// original https://www.shadertoy.com/view/WtsBW4

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec3 p){
    p=mod(p,2.) *0.6;
    p = abs(p)-0.6;
    if (p.x < p.z) p.xz = p.zx;
    if (p.y < p.z) p.yz = p.zy;
    
    float s=0.45;
  
    
    return length(p)/s;
}

void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 p,
          ro=vec3(.4+.32*sin(time*.155),.2+.05*cos(time*.05),-.5*time),
          w=normalize(vec3(.2,sin(time*.05),-1)),
          u=normalize(cross(w,vec3(1,5,5))),
          rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
      float h=0.1,d,i,zoom = 2.;
     ro*=zoom;
    for(i=2.;i<911250.;i++){
        p=ro+rd*h;
        p/=zoom;
          d=map(p);
        if(d<0.1||h>15.)break;
        h+=d;
    }
    glFragColor.xyz=15.*vec3(cos(p*.73)*.643335+1.15)/i;
}
