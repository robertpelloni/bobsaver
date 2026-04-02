#version 420

// original https://www.shadertoy.com/view/tldyWr

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define rot(a) mat2(cos(a),sin(a),-sin(a),cos(a))
#define PI 3.14159265

vec2 pmodA(vec2 p,float n)
{
    float np=(2.0*PI)/n;
    float r=atan(p.x,p.y)-0.5*np;
    r=mod(r,np)-0.5*np;
    return 2.0*length(p)*vec2(cos(r),sin(r)); 
}

float SmoothMin(float d1,float d2,float k)
{
    float h=exp(-k*d1)+exp(-k*d2);
    return -log(h)/k;
}

float Plane(vec3 p)
{
    return p.y;
}

float Ceiling(vec3 p)
{
    p=(-1.0)*p;
    return p.y;
}

float sdCylinder(vec3 p,vec3 c)
{
    return length(p.xz-c.xy)-c.z;
}

float sdCylinderYZ(vec3 p,vec3 c)
{
    return length(p.yz-c.xy)-c.z;
}

float sdCylinderXY(vec3 p,vec3 c)
{
    return length(p.xy-c.xy)-c.z;
}

vec3 hsv2rgb2(vec3 c, float k) {
    return smoothstep(0. + k, 1. - k,
                      .5 + .5 * cos((vec3(c.x) + vec3(3., 2., 1.) / 3.) * radians(360.)));
}

float map(vec3 p,inout vec3 color)
{
    vec3 pos=p;
    float s=1.0;
    for(int i=0;i<5;i++)
    {
        pos.xy=abs(pos.xy);
        pos.xy*=rot(2.5+pos.z+0.02);
        pos*=0.6;
        s*=0.6;
    }
    pos/=s;
    
    pos.xy=pmodA(pos.xy,2.0);
    
    vec3 cyPos=p;
    cyPos.xy*=rot(cyPos.z);
    float d1=sdCylinderXY(cyPos+vec3(0.25,0.25,0.0),vec3(0.,0.,0.025));
    float d2=sdCylinderXY(cyPos+vec3(-0.25,-0.25,0.0),vec3(0.,0.,0.025));
    float d1d=sdCylinderXY(cyPos+vec3(-0.25,0.25,0.0),vec3(0.,0.,0.025));
    float d2d=sdCylinderXY(cyPos+vec3(0.25,-0.25,0.0),vec3(0.,0.,0.025));
    
    
    float d3=sdCylinder(mod(pos,1.0)-0.5,vec3(0.,0.,0.05));
    float d4=sdCylinderYZ(mod(pos,1.0)-0.5,vec3(0.,0.,0.05));
    
    float d6=Plane(p+vec3(0.0,.8,0.0));
    float d7=Ceiling(p+vec3(0.0,-.8,0.0));
   
    
    float cyRot= min(min(d1,d2),min(d1d,d2d));
    return min(SmoothMin(min(d6,d7),min(d3,d4),6.0),cyRot);
}

void main(void)
{
    
    vec2 uv = (gl_FragCoord.xy*2.0-resolution.xy)/min(resolution.x,resolution.y);
    vec3 ro=vec3(0.,0.,3.)+vec3(0.,0.,-time);
    vec3 rd=vec3(uv.xy,-1.0);
    
    float d,t=0.0;
    vec3 color=hsv2rgb2(vec3(mod(time*0.1,1.0),1.0,1.0),4.2);
    float mainEmissive=0.0;
    for(int i=0;i<256;i++)
    {
        d=map(ro+rd*t*0.175,color);
        mainEmissive+=exp(abs(d)*-0.2);
        if(d<0.001||t>1000.0)
        {
            break;
        }
        t+=d;
    }
    
   
    vec3 col=vec3(exp(-0.35*t))+color*mainEmissive*0.006;
    glFragColor = vec4(col,1.0);
}
