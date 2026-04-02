#version 420

// original https://www.shadertoy.com/view/ttsBzM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float map(vec3 p){
    p=mod(p,2.)-1.;
    p = abs(p)-1.;
    if (p.x < p.z) p.xz = p.zx;
    if (p.y < p.z) p.yz = p.zy;
    if (p.x < p.y) p.xy = p.yx;
    float s=1.;
    for(int i=0;i++<10;)
    {
      float r2=2./clamp(dot(p,p),.1,1.);
      p=abs(p)*r2-vec3(.6,.6,3.5);
      s*=r2;
    }
    return length(p)/s;
}

void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 p,
          ro=vec3(.4+.2*sin(time*.03),.2+.05*cos(time*.03),-.1*time),
          w=normalize(vec3(.2,sin(time*.05),-1)),
          u=normalize(cross(w,vec3(0,1,0))),
          rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
      float h=0.1,d,i,zoom = 2.;
     ro*=zoom;
    for(i=1.;i<100.;i++){
        p=ro+rd*h;
        p/=zoom;
          d=map(p);
        if(d<0.001||h>25.)break;
        h+=d;
    }
    glFragColor.xyz=25.*vec3(cos(p*.8)*.5+.5)/i;
}
