#version 420

// original https://www.shadertoy.com/view/wlffDM

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a)mat2(cos(a),sin(a),-sin(a),cos(a))
float Scale;
float lpNorm(vec3 p, float n)
{
    p = pow(abs(p), vec3(n));
    return pow(p.x+p.y+p.z, 1.0/n);
}

float map(vec3 p){
    vec3 q=p;
    float s = 2.5;
    for(int i = 0; i < 10; i++) {
        p=mod(p-1.,2.)-1.;
        float r2=1.1/pow(lpNorm(abs(p),2.+q.y*10.),1.75);
        p*=r2;
        s*=r2;
        p.xy*=rot(.001);
    }
    Scale=log2(s*.0003);
    return q.y>1.3?length(p)/s:abs(p.y)/s;
}

void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 p,
          ro=vec3(.7-time*.3,.5,-time*.3),
          w=normalize(vec3(.2,0.3,-1)),
          u=normalize(cross(w,vec3(0,1,0))),
          rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
      float h=0.,d,i;
     for(i=1.;i<100.;i++){
        p=ro+rd*h;
          d=map(p);
        if(d<0.001)break;
        h+=d;
    }
    glFragColor.xyz=23.*vec3(cos(Scale*.3+cos(p*.6))*.5+.5)/i;
}
