#version 420

// original https://www.shadertoy.com/view/MdGczK

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

// @lsdlive

float sc(vec3 p, float d){p=abs(p);p=max(p,p.yzx);return min(p.x,min(p.y,p.z))-d;}
mat2 r2d(float a){float c=cos(a),s=sin(a);return mat2(c,s,-s,c);}
float re(float p,float d){return mod(p-d*.5,d)-d*.5;}
void amod(inout vec2 p, float m){float a=re(atan(p.x,p.y),m);p=vec2(cos(a),sin(a))*length(p);}
void mo(inout vec2 p, vec2 d){p.x=abs(p.x)-d.x;p.y=abs(p.y)-d.y;if(p.y>p.x)p=p.yx;}

float scc(vec3 p, float d){
    float c1 = length(p.xy) - d;
    float c2 = length(p.xz) - d;
    float c3 = length(p.zy) - d;
    return min(c1,min(c2,c3));
}

float g=0.;
float de(vec3 p){
    //p.y-=1.;
    p.xy*=r2d(time*.3);    
    
  p.xy*=r2d(p.z*.3);  
    
    p.z=re(p.z,9.);
    
    amod(p.xy, 6.28/4.);
    mo(p.xy, vec2(2., .3));
    amod(p.xy, 6.28/8.3);
    mo(p.zy, vec2(1., .3));
       
    p.x=abs(p.x)-3.;
    
    p.y=abs(p.y)-2.;
    p.xy*=r2d(.5);
    
    float d = sc (p,.5);
    
    p.xy*=r2d(time*.3);
    d = min(d, -scc(p,1.));
    g+=.01/(.01+d*d);
    return d;
}

void main(void)
{
    vec2 uv = gl_FragCoord.xy/resolution.xy -.5;
    uv.x*=resolution.x/resolution.y;
    
    vec3 ro=vec3(0,0,-3.+time);
    vec3 rd=normalize(vec3(uv,1));
    
    vec3 p;
    float t=0.,i=0.;
    for(;i<1.;i+=.01){
        p=ro+rd*t;
        float d=de(p);
        //if(d<.001)break;
        d=max(abs(d), .005);
        t+=d*.3;
    }
    
    vec3 bg= vec3(.2, .1, .2);
    vec3 c=mix(vec3(.7, .1, .1), bg, uv.x*4.3+i);
    c.g+=sin(time);
    c+=g*.02;
    c=mix(c, bg,1.-exp(-.01*t*t));
    glFragColor = vec4(c,1.0);
}
