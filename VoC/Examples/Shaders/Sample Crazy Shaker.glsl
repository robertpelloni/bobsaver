#version 420

// original https://www.shadertoy.com/view/wdSczt

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

out vec4 glFragColor;

const int MAX_MARCHING_STEPS=256;
const float MIN_DIST=4.;
const float MAX_DIST=6.;
const float EPSILON=.0001;

// Primitives from http://iquilezles.org/www/articles/distfunctions/distfunctions.htm

float sdSphere(vec3 p,float s)
{
    return length(p)-s;
}

float sdBox(vec3 p,vec3 b)
{
    vec3 q=abs(p)-b;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.);
}

float sdRoundBox(vec3 p,vec3 b,float r)
{
    vec3 q=abs(p)-b;
    return length(max(q,0.))+min(max(q.x,max(q.y,q.z)),0.)-r;
}

float sdVerticalCapsule(vec3 p,float h,float r)
{
    p.y-=clamp(p.y,0.,h);
    return length(p)-r;
}

float sdCapsule(vec3 p,vec3 a,vec3 b,float r)
{
    vec3 pa=p-a,ba=b-a;
    float h=clamp(dot(pa,ba)/dot(ba,ba),0.,1.);
    return length(pa-ba*h)-r;
}

float opUnion(float d1,float d2){return min(d1,d2);}

float opSubtraction(float d1,float d2){return max(-d1,d2);}

float opIntersection(float d1,float d2){return max(d1,d2);}

float opSmoothUnion(float d1,float d2,float k){
    float h=clamp(.5+.5*(d2-d1)/k,0.,1.);
return mix(d2,d1,h)-k*h*(1.-h);}

float opSmoothSubtraction(float d1,float d2,float k){
    float h=clamp(.5-.5*(d2+d1)/k,0.,1.);
return mix(d2,-d1,h)+k*h*(1.-h);}

float opSmoothIntersection(float d1,float d2,float k){
    float h=clamp(.5-.5*(d2-d1)/k,0.,1.);
return mix(d2,d1,h)+k*h*(1.-h);}

vec3 rotateX(vec3 p,float angle){
    return vec3(mat4(
            1,0,0,0,
            0,cos(angle),-sin(angle),0,
            0,sin(angle),cos(angle),0,
            0,0,0,1
        )*vec4(p,0)
    );
}

vec3 rotateY(vec3 p,float angle){
    return vec3(mat4(
            cos(angle),0,sin(angle),0,
            0,1,0,0,
            -sin(angle),0,cos(angle),0,
            0,0,0,1
        )*vec4(p,0)
    );
}

vec3 rotateZ(vec3 p,float angle){
    return vec3(mat4(
            cos(angle),-sin(angle),0,0,
            sin(angle),cos(angle),0,0,
            0,0,1,0,
            0,0,0,1
        )*vec4(p,0)
    );
}

vec3 repeat(in vec3 p,in vec3 c){
    return mod(p+.5*c,c)-.5*c;
}

vec3 twist(in vec3 p,float k){
    float c=cos(k*p.y);
    float s=sin(k*p.y);
    mat2 m=mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
}

vec3 cheapBend(in vec3 p,float k){
    float c=cos(k*p.x);
    float s=sin(k*p.x);
    mat2 m=mat2(c,-s,s,c);
    return vec3(m*p.xy,p.z);
}

float sdGrid(in vec3 p){
    return sdSphere(repeat(p,vec3(.2,.8,.4)),.05);
}

float grimace(in vec3 p) {
    return opSmoothUnion(
        sdBox(cheapBend(p,sin(time*8.)),vec3(.8,.1,.3)),
        sdBox(cheapBend(rotateY(p, time),cos(time*8.)),vec3(.8,.1,.3)),
        .4
    );
}

float sceneSDF(in vec3 p){
    return grimace(rotateZ(rotateX(p, time),time*1.5));
}

vec4 render(in vec3 ro,in vec3 rd){
    float depth=MIN_DIST;
    int cost=MAX_MARCHING_STEPS;
    for(int i=0;i<MAX_MARCHING_STEPS;i++){
        float dist=sceneSDF(ro+depth*rd);
        if(dist<EPSILON){
            cost=i;
            break;
        }
        depth+=dist;
        if(depth>=MAX_DIST){
            cost=i;
            depth=MAX_DIST;
            break;
        }
    }
    if(cost==MAX_MARCHING_STEPS)depth=MAX_DIST;
    
    float hard=clamp(log(float(cost))/log(float(MAX_MARCHING_STEPS)),0.,1.);
    float deep=clamp(1.-(depth-MIN_DIST)/(MAX_DIST-MIN_DIST),0.,1.);
    
    if(depth>MAX_DIST-EPSILON){
        return vec4(hard*.5,hard,1.,hard*hard);
    }
    return vec4(vec3(deep-hard),1.);
    //return vec4(hard*hard*1.5,hard*hard*hard*1.2,deep*deep*(1.-hard),1);
    
}

vec3 rayDirection(float fieldOfView,vec2 size){
    vec2 xy=gl_FragCoord.xy-size/2.;
    float z=size.y/tan(radians(fieldOfView)/2.);
    return normalize(vec3(xy,-z));
}

void main(void) {
    glFragColor=render(
        vec3(0.,0.,5.),// ray origin
        rayDirection(50.,resolution.xy)
    );
}
