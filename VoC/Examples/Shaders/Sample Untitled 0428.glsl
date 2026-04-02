#version 420

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

#define r 0.6
#define R 0.7
float F(vec3 pos)
{
    vec3 pos2=pos*pos;
    return dot(pos2,pos2)-2.0*r*dot(pos,pos)+R*R;    
}
float dF(vec3 pos,vec3 dir)
{
    vec3 pos3=pos*pos*pos;
    return 4.0*(dot(pos3,dir)-r*dot(pos,dir));
}
float d2F(vec3 pos,vec3 dir)
{
    return 12.0*dot(pos*pos,dir*dir)-4.0*r;    
}
vec2 minF(vec3 pos,vec3 dir)
{
    float t1=0.0,t2=5.0;
    vec3 res,p1=pos,p2=pos+t2*dir;    
    for(int i=0;i<10;i++){
        t1+=-dF(p1,dir)/d2F(p1,dir);
        p1=pos+t1*dir;
        t2+=-dF(p2,dir)/d2F(p2,dir);
        p2=pos+t2*dir;
    }
    return vec2(t1,t2);
}
//(dx4+dy4+dz4)t2+2(xdx3+ydy3+zdz3)t+x2dx2+y2dy2+z2dz2-r/3=0
float turnPoint(vec3 pos,vec3 dir)
{
    vec3 dir2=dir*dir,dir3=dir2*dir,pos2=pos*pos;
    float a=dot(dir2,dir2),b=2.0*dot(pos,dir3),c=dot(pos2,dir2)-r/3.0;
    float delt=b*b-4.0*a*c;
    if(delt<0.0)return -1.0;
    return 0.5*(-b+sqrt(delt))/a;    
}
vec3 Norm(vec3 pos)
{
    return normalize(pos*pos*pos-r*pos);
}
float trace(vec3 pos,vec3 dir)
{
    float total=0.0;
    vec2 mm=minF(pos,dir);
    float Fn=F(pos+mm.x*dir),Ff=F(pos+mm.y*dir);
    if(Fn>0.0&&Ff>0.0)return 100.;
    if(Fn>0.0){
        float turn=turnPoint(pos,dir);
        if(turn>0.0){
            total=mix(turn,mm.y,0.2);
            pos+=total*dir;
        }
    }
    for(int i=0;i<20;i++){
        float Ft=F(pos),dF=dF(pos,dir);
        float t=-Ft/dF*0.8;
        pos+=t*dir;
        total+=t;
        if(abs(t)<0.001) return total;    
    }
    return 100.;
}

float c=cos(0.1*time),s=-sin(0.1*time);
mat2 rotX=mat2(c,s,-s,c);
void main( void ) {

    vec2 position = 3.0*( gl_FragCoord.xy - 0.5*resolution.xy )/resolution.y;
    vec3 pos=vec3(position,1.5),eyepos=vec3(0.,0.0,4.0),dir=normalize(pos-eyepos),dirlight=normalize(vec3(-0.4,0.8,2.0)),lightpos=vec3(-1.0,3.0,4.0),lightdir=normalize(pos-lightpos);
    vec3 diffuse=vec3(0.,0.,0.);
    pos.yz*=rotX,dir.yz*=rotX,lightdir.yz*=rotX,dirlight.yz*=rotX;
    pos.xy*=rotX,dir.xy*=rotX,lightdir.xy*=rotX,dirlight.xy*=rotX;    
    vec3 color =vec3(0.0);
    float dist=trace(pos,dir);
    if(dist<5.0){
        vec3 n=Norm(pos+dist*dir);
        color=dot(n,-lightdir)*smoothstep(0.02,0.02,abs(mod(pos+dist*dir,0.2)-0.1));
    }

    glFragColor = vec4(  color , 1.0 );
}

