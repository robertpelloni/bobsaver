#version 420

#extension GL_EXT_gpu_shader4 : enable

// original https://www.shadertoy.com/view/Wlsfzs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a)mat2(cos(a),sin(a),-sin(a),cos(a))

float map(vec3 p)
{
    p.xz*=rot(time*.5);
    p.xy*=rot(time*.5);
    float s=2.,r2;
    p=abs(p);
    for(int i=0; i<12;i++){
        p=1.-abs(p-1.);
        if(fract(time*.5)<.7){
            r2=1.2/dot(p,p);
        }else{
            r2=(i%3==1)?1.3:1.3/dot(p,p);
        }
        p*=r2;
        s*=r2;
    }
    return length(cross(p,normalize(vec3(1))))/s-0.003;
}

void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
      vec3 ro=vec3(
        mix(8.,3.,sin(time*.2+.3*sin(time*.5))*.5+.5),
        mix(-.5,.5,cos(time*.1+.5*cos(time*.7))*.5+.5),
        0);
      vec3 w=normalize(-ro);
      vec3 u=normalize(cross(w,vec3(0,1,0)));
      vec3 rd=mat3(u,cross(u,w),w)*normalize(vec3(uv,2));
    vec3 p;
    float h=0.,d,i;
    for(i=1.;i<120.;i++)
    {
        p=ro+rd*h;    
        d=map(p);
        if(d<.0001)break;
        h+=d;
    }
    glFragColor.xyz=30.*vec3(cos(p*.8)*.5+.5)/i;
}
