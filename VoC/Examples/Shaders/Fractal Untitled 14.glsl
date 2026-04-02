#version 420

// original https://www.shadertoy.com/view/wtVcDK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
float orbit;

float map(vec3 p){
    p.yz*=rot(time*0.1+2.);
    p.xz*=rot(time*0.2+2.);
    p=abs(p)-3.5;
    if(p.x<p.z)p.xz=p.zx;
    if(p.y<p.z)p.yz=p.zy;
     if(p.x<p.y)p.xy=p.yx;
     float s=3.;
    vec3  p0=p*1.2;
    for(float i=0.;i<5.;i++){
        p=1.-abs(p-1.);
          float k=-6.5*clamp(.5*max(1.8/dot(p,p),.8),0.,1.);
        s*=abs(k);
           p*=k;
        p+=p0;
        p.yz*=rot(-1.0);
    }
    orbit = log2(s);
    float a=3.;
    p.xy-=clamp(p.xy,-a,a);
    return length(p.xy)/s;
}

void main(void)
{
    vec2 uv=(2.*gl_FragCoord.xy-resolution.xy)/resolution.y;
    vec3 ro=vec3(0,0,-20);
    vec3 rd=normalize(vec3(uv,3));
    float h=0.,d,i;
    for(i=1.;i<100.;i++)
    {
        d=map(ro+rd*h);
        if(d<.001)break;
        h+=d;
    }
    glFragColor.xyz+=20.*(cos(vec3(9,5,12)+orbit*3.)*.5+.5)/i;
}
