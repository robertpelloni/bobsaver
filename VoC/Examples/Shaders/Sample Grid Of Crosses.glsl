#version 420

// original https://www.shadertoy.com/view/tsffWs

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

vec4 quaternion(vec3 axis,float angle){
    float halfang=angle/2.;
    return vec4(axis*sin(halfang),cos(halfang));
}

vec4 quaternionMultiply(vec4 q1,vec4 q2){
    return vec4(q1.xyz*q2.w+q1.w*q2.xyz+cross(q1.xyz,q2.xyz),q1.w*q2.w-dot(q1.xyz,q2.xyz));
}

vec3 rotation(vec4 q,vec3 pos){
    return pos+2.*cross(q.xyz,cross(q.xyz,pos)+q.w*pos);
}

//Note: we need dimension.x > dimension.y here
float sdfCross(vec2 dimension,vec3 p){
    vec3 xmaxP=abs(p);
    xmaxP=xmaxP.x<xmaxP.y?xmaxP.yzx:xmaxP;
    xmaxP=xmaxP.x<xmaxP.y?xmaxP.yzx:xmaxP;
    xmaxP=xmaxP.x<xmaxP.z?xmaxP.zxy:xmaxP;
    vec3 diff=xmaxP-dimension.xyy;
    float maxdiff=max(max(diff.x,diff.y),diff.z);
    vec3 connection=maxdiff>0.?diff:vec3(0.,-maxdiff,dimension.y-xmaxP.x);
    return sign(maxdiff)*length(max(connection,0.));
}

float sdfcell(vec3 p,vec2 cell){
    vec4 qUpDown=quaternion(vec3(1,0,0),radians(-cell.y*30.));
    vec4 qLeftRight=quaternion(vec3(0,0,1),radians(time*10.+cell.x*30.));
    vec4 q=quaternionMultiply(qLeftRight,qUpDown);
    return sdfCross(vec2(0.9,0.3),rotation(q,p))+.1;
}

float sdf(vec3 p){
    vec2 cell=floor((p.xz/2.0));
    vec2 offset=fract((p.xz/2.0))*2.;
    return min(min(sdfcell(vec3(offset.x,p.y,offset.y),cell+vec2(0.,0.)),
              sdfcell(vec3(offset.x-2.,p.y,offset.y),cell+vec2(1.,0.))),min(
              sdfcell(vec3(offset.x,p.y,offset.y-2.),cell+vec2(0.,1.)),
              sdfcell(vec3(offset.x-2.,p.y,offset.y-2.),cell+vec2(1.,1.))));
    //return length(p)-1.0;
}

vec3 rayDirection(){
    float zoom=0.6;
    vec2 offset=gl_FragCoord.xy/resolution.xy-0.5;
    offset.y/=resolution.x/resolution.y;
    vec3 rawDir=vec3(offset/zoom,-1);
    vec2 mouseAngles=mouse*resolution.xy.xy/resolution.xy-0.5;
    vec4 qUpDown=quaternion(vec3(1,0,0),radians(90.+mouseAngles.y*10.0));
    vec4 qLeftRight=quaternion(vec3(0,0,1),radians(0.-mouseAngles.x*10.0));
    vec4 q=quaternionMultiply(qLeftRight,qUpDown);
    return normalize(rotation(q,rawDir));
}

#define delta 0.00025
vec3 normal(vec3 pos){
    vec2 e=vec2(1.,-1.);
    vec3 rawNormal=e.xxx*sdf(pos+delta*e.xxx);
    rawNormal+=e.xyy*sdf(pos+delta*e.xyy);
    rawNormal+=e.yyx*sdf(pos+delta*e.yyx);
    rawNormal+=e.xxx*sdf(pos+delta*e.xxx);
    return normalize(rawNormal);
}

#define iteration 128
vec3 rayMarching(vec3 start,vec3 dir){
    float tmin=(-1.0-start.y)/dir.y;
    vec3 pos=tmin*dir+start;
    float t=tmin;
    if(tmin<0.){
        return pos;
    }
    for(int i=0;i<iteration;i++){
        float step1=sdf(pos);
        if(abs(step1)<.000001*t){
            return pos;
        }
        t+=step1;
        pos=t*dir+start;
    }
    return pos;
}

float lighting(vec3 pos){
    vec3 light=vec3(0.+sin(2.*time),-2.0,0.-cos(2.*time));
    float diffuse=clamp(dot(normalize(light-pos),normal(pos)),0.,1.);
    return diffuse*.5+.5;
}

vec3 color(vec3 pos){
    return pos.y>1.?vec3(0,0,0):vec3(1.,.5,0);
}

void main(void)
{
    vec3 cameraPos=vec3(0.+.25*sin(time),-8.0,0.-.25*cos(time));
    vec3 dir=rayDirection();
    vec3 pos=rayMarching(cameraPos,dir);
    glFragColor =vec4(lighting(pos)*color(pos),1);
}
