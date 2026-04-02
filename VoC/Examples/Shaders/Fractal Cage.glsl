#version 420

// original https://www.shadertoy.com/view/3l2yDd

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

float lpNorm(vec3 p, float n)
{
    p = pow(abs(p), vec3(n));
    return pow(p.x+p.y+p.z, 1.0/n);
}

float map(vec3 p){
    float s = 1.;
    for(int i = 0; i < 9; i++) {
        p=p-2.*round(p/2.);
        float r2=1.1/max(pow(lpNorm(p.xyz, 4.5),1.6),.15);
        p*=r2;
        s*=r2;
    }
    return length(p)/s-.001;
}

void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 p,
          ro=vec3(1,1.5,-time*.3),
          w=normalize(vec3(.2,sin(time*.05),-1)),
          u=normalize(cross(w,vec3(0,1,0))),
          rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
      float h=0.,d,i,zoom = 3.;
     ro*=zoom;
    for(i=1.;i<100.;i++){
        p=ro+rd*h;
        p/=zoom;
          d=map(p);
        if(d<0.001||h>25.)break;
        h+=d;
    }
    glFragColor.xyz=25.*vec3(cos(p*.4)*.5+.5)/i;
}
